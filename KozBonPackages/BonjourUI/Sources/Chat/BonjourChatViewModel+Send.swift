//
//  BonjourChatViewModel+Send.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourAI
import BonjourCore
import BonjourLocalization
import BonjourModels
import BonjourScanning
import BonjourStorage

// MARK: - Send Pipeline

extension BonjourChatViewModel {

    // MARK: - Send Validation

    /// Whether the Send button should be disabled. True when
    /// the assistant is generating OR the input is
    /// empty/whitespace-only.
    func sendDisabled(session: any BonjourChatSessionProtocol) -> Bool {
        session.isGenerating
            || inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Returns the localized VoiceOver hint that matches the
    /// Send button's current state. Three-way switch — busy
    /// (assistant streaming), empty (no input), enabled — so
    /// VoiceOver explains exactly *why* the button is in the
    /// state it's in. Previously both disabled cases shared
    /// the empty-input hint, which was actively misleading
    /// while the assistant was still streaming.
    func sendButtonAccessibilityHint(
        session: any BonjourChatSessionProtocol
    ) -> String {
        if session.isGenerating {
            return String(localized: Strings.Accessibility.chatBusyHint)
        }
        let trimmedInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedInput.isEmpty {
            return String(localized: Strings.Accessibility.chatSendDisabledHint)
        }
        return String(localized: Strings.Accessibility.chatSendHint)
    }

    // MARK: - Send

    /// Validates the input, appends the user bubble
    /// synchronously (so it lands on the next render before
    /// any awaits run), builds the chat context (which may
    /// include a fresh ~3-second Bonjour scan for live-state
    /// questions), and streams the assistant's response.
    ///
    /// The caller is responsible for incrementing
    /// ``submitCount`` synchronously in the Button action so
    /// the haptic fires the same render as the press
    /// animation. This method only handles the validation +
    /// scan + model invocation pipeline — *not* the haptic.
    ///
    /// - Parameters:
    ///   - text: The user's message text. Trimmed internally.
    ///   - session: The active session, resolved by the view
    ///     from the environment-injected or local fallback.
    ///   - preferencesStore: Read for the `aiExpertiseLevel`
    ///     preference, which drives the response-length
    ///     directive injected into the system instructions.
    ///   - reduceMotion: Forwarded into the input-clear
    ///     animation; the rest of the pipeline doesn't
    ///     animate.
    func sendMessage(
        _ text: String,
        using session: any BonjourChatSessionProtocol,
        preferencesStore: PreferencesStore,
        reduceMotion: Bool
    ) async {
        guard !session.isGenerating else { return }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
            inputText = ""
        }

        // Client-side pre-filter catches obvious prompt-injection
        // and off-topic patterns without paying model latency. On
        // rejection we render the exchange as a normal chat turn
        // (user message + assistant refusal) so the surface stays
        // coherent and the refusal is visible even on a previously-
        // empty chat.
        switch ChatInputValidator.validate(trimmed) {
        case .allowed:
            break
        case .rejected(let reason):
            session.appendLocalRejection(
                userMessage: trimmed,
                refusalText: Self.errorMessage(for: reason)
            )
            return
        }

        // Append the user's bubble synchronously, BEFORE any
        // awaits. The fresh-scan path inside
        // ``buildChatContext(forMessage:)`` can stall for ~3
        // seconds on live-state questions; without this
        // synchronous append the bubble wouldn't appear until
        // both awaits resolved, which looked like the chat
        // surface was frozen post-tap.
        session.appendUserMessage(trimmed)

        let context = await buildChatContext(forMessage: trimmed)

        // Response length is derived from the user's Detail-level
        // preference. Basic → standard, Technical → thorough.
        let detailLevel = BonjourServicePromptBuilder.ExpertiseLevel(
            rawValue: preferencesStore.aiExpertiseLevel
        ) ?? .basic
        session.responseLength = detailLevel.responseLength

        await session.send(trimmed, context: context)
    }

    /// Builds the `ChatContext` the assistant sees for the
    /// user's current message. When the message looks like a
    /// question about live network state ("what's on my
    /// network?", "list devices", "scan", and similar), runs
    /// a fresh `BonjourOneShotScanner` pass first. Otherwise
    /// passes through the cached `services.flatActiveServices`
    /// snapshot.
    ///
    /// A fresh `BonjourServiceScanner` instance is used per
    /// scan rather than the shared one driving Discover, so
    /// the chat's snapshot doesn't disturb Discover's
    /// continuous observation — same isolation pattern the
    /// Siri intents use.
    func buildChatContext(
        forMessage message: String
    ) async -> BonjourChatPromptBuilder.ChatContext {
        let library = BonjourServiceType.fetchAll()
        let publishedServices = services.sortedPublishedServices

        if ChatScanIntentDetector.wantsFreshScan(message: message) {
            let runner = BonjourOneShotScanner(scanner: BonjourServiceScanner())
            let freshServices = await runner.run(
                publishedServices: services.publishManager.publishedServices
            )
            return BonjourChatPromptBuilder.ChatContext(
                discoveredServices: freshServices,
                publishedServices: publishedServices,
                serviceTypeLibrary: library,
                // The just-completed scan is by definition the
                // most recent; pin `lastScanTime` to now so the
                // assistant's freshness-aware phrasing reads as
                // "data is fresh" rather than "data may be
                // stale."
                lastScanTime: Date(),
                isScanning: false
            )
        }

        return BonjourChatPromptBuilder.ChatContext(
            discoveredServices: services.flatActiveServices,
            publishedServices: publishedServices,
            serviceTypeLibrary: library,
            lastScanTime: services.lastScanTime,
            isScanning: services.serviceScanner.isProcessing
        )
    }

    /// Returns a localized error message for the given
    /// validation rejection reason.
    static func errorMessage(for reason: ChatInputValidator.Reason) -> String {
        switch reason {
        case .empty:
            return ""
        case .tooLong(let limit):
            return String(format: String(localized: Strings.Chat.errorTooLong), limit)
        case .promptInjection:
            return String(localized: Strings.Chat.errorPromptInjection)
        case .offTopic:
            return String(localized: Strings.Chat.errorOffTopic)
        }
    }
}
