//
//  OpenAIBonjourChatSession.swift
//  BonjourAIOpenAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourAICore
import BonjourCore
import BonjourLocalization

// MARK: - OpenAIBonjourChatSession

/// OpenAI-backed implementation of ``BonjourChatSessionProtocol``.
///
/// Mirrors ``GeminiBonjourChatSession`` so the SwiftUI chat surface
/// treats every backend interchangeably:
///
/// - Multi-turn — every completed exchange is appended to a
///   parallel ``conversationHistory`` that's replayed on each send.
///   The requests set `store: false`, so OpenAI holds no
///   server-side copy of the conversation; this history is the only
///   one. Keeping the instructions byte-identical across turns lets
///   OpenAI's automatic prompt caching apply to the shared prefix.
/// - Streaming — text deltas are appended to a placeholder
///   assistant message in real time.
/// - Cancellation — task cancellation propagates to the underlying
///   `URLSessionDataTask`.
/// - Recreation — flipping the response-length preference
///   regenerates the instructions.
///
/// The `intentBroker` is held for protocol conformance but stays
/// inert: tool calling lives on the on-device backend only, as it
/// does for the other cloud providers.
@MainActor
@Observable
public final class OpenAIBonjourChatSession: BonjourChatSessionProtocol {

    // MARK: - Protocol-Required Properties

    public private(set) var messages: [BonjourChatMessage] = []
    public private(set) var isGenerating: Bool = false
    public var error: String?
    public private(set) var errorAction: ChatErrorAction?
    public var responseLength: BonjourServicePromptBuilder.ResponseLength = .standard
    public let intentBroker: BonjourChatIntentBroker

    // MARK: - Diagnostics

    private let logger = Logger(
        subsystem: "com.kozinga.KozBon",
        category: "OpenAIBonjourChatSession"
    )

    // MARK: - OpenAI-Specific State

    private let client: any OpenAIClientProtocol

    /// Read on every send so signing out and back in mid-session
    /// never leaves the chat holding a stale key.
    private let credentialsStore: any AICloudCredentialsStore

    /// Snapshot of the model selected when the current instructions
    /// were built.
    private var currentModel: String?

    /// Snapshot of the response-length preference baked into the
    /// current instructions.
    private var currentResponseLengthSnapshot: BonjourServicePromptBuilder.ResponseLength?

    /// The system instructions sent on every request. Built lazily
    /// on the first send (or `prewarm()`).
    private var instructions: String?

    /// The user / assistant turns replayed to OpenAI on every
    /// request. Distinct from ``messages`` because the streaming
    /// placeholder and locally-rejected turns are never sent.
    private var conversationHistory: [OpenAIInputMessage] = []

    /// Signature of the last `<context>` block sent. Only a changed
    /// context triggers re-injection.
    private var lastContextSignature: String?

    // MARK: - Init

    public init(
        client: any OpenAIClientProtocol,
        credentialsStore: any AICloudCredentialsStore,
        intentBroker: BonjourChatIntentBroker = BonjourChatIntentBroker()
    ) {
        self.client = client
        self.credentialsStore = credentialsStore
        self.intentBroker = intentBroker
    }

    // MARK: - Limits

    /// Same in-memory bubble cap as the other sessions, so every
    /// backend produces indistinguishable scrollback behavior.
    static let maxInMemoryMessageCount = 500

    /// Max output tokens per turn.
    ///
    /// Higher than the Claude and Gemini sessions' 1,024 because on
    /// OpenAI's reasoning models this budget also pays for hidden
    /// reasoning — at 1,024 a thoughtful model can spend it all
    /// before writing a word.
    static let maximumResponseTokensPerTurn = 4096

    // MARK: - Prewarm

    /// Builds the instructions ahead of the first send. Idempotent;
    /// no network call happens here.
    public func prewarm() {
        guard instructions == nil
                || currentResponseLengthSnapshot != responseLength
                || currentModel != selectedModel else {
            return
        }

        instructions = BonjourChatPromptBuilder.systemInstructions(responseLength: responseLength)
        currentResponseLengthSnapshot = responseLength
        currentModel = selectedModel
        lastContextSignature = nil
    }

    // MARK: - Append User Message

    /// Appends the user's message to ``messages`` synchronously so
    /// the bubble lands before the network awaits.
    /// `send(_:context:)` will NOT re-append.
    public func appendUserMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if messages.count >= Self.maxInMemoryMessageCount {
            messages = Array(messages.suffix(Self.maxInMemoryMessageCount - 1))
        }

        messages.append(BonjourChatMessage(role: .user, content: trimmed))
    }

    // MARK: - Send

    public func send(_ text: String, context: BonjourChatPromptBuilder.ChatContext) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        error = nil
        errorAction = nil
        isGenerating = true
        defer { isGenerating = false }
        intentBroker.resetToolCallCount()

        prewarm()
        guard let apiKey = readAPIKey() else { return }
        let turnText = composeTurn(trimmed: trimmed, context: context)

        conversationHistory.append(OpenAIInputMessage(role: .user, content: turnText))
        let assistantId = UUID()
        messages.append(BonjourChatMessage(id: assistantId, role: .assistant, content: ""))

        let request = OpenAIResponseRequest.make(
            model: selectedModel,
            instructions: instructions
                ?? BonjourChatPromptBuilder.systemInstructions(responseLength: responseLength),
            input: conversationHistory,
            maxOutputTokens: Self.maximumResponseTokensPerTurn
        )

        await drainStream(request: request, apiKey: apiKey, assistantId: assistantId)
    }

    // MARK: - Send Helpers

    /// Reads the OpenAI key, surfacing a localized
    /// `.missingCredentials` error and returning `nil` when the user
    /// has signed out mid-session.
    private func readAPIKey() -> String? {
        do {
            guard let storedKey = try credentialsStore.apiKey(for: .openai),
                  !storedKey.isEmpty else {
                self.error = AICloudError.missingCredentials(provider: .openai).errorDescription
                return nil
            }
            return storedKey
        } catch {
            logger.error("Failed to read OpenAI API key: \(error.localizedDescription)")
            self.error = error.localizedDescription
            return nil
        }
    }

    /// Composes the user-turn text via
    /// `BonjourChatPromptBuilder.userTurn(...)`, the same shape every
    /// other session uses.
    private func composeTurn(
        trimmed: String,
        context: BonjourChatPromptBuilder.ChatContext
    ) -> String {
        // Compared on the signature, not the rendered block: the
        // block carries a live "Ns ago" scan counter that changes
        // every second.
        let currentSignature = BonjourChatPromptBuilder.contextSignature(context: context)
        let isFirstTurn = (lastContextSignature == nil)
        let contextChanged = lastContextSignature != currentSignature
        let turnText = BonjourChatPromptBuilder.userTurn(
            message: trimmed,
            context: context,
            isFirstTurn: isFirstTurn,
            contextChanged: contextChanged
        )
        lastContextSignature = currentSignature
        return turnText
    }

    /// Consumes the stream into the placeholder assistant message,
    /// rolling the turn back on error or cancellation so a retry
    /// doesn't submit a doubled history.
    private func drainStream(
        request: OpenAIResponseRequest,
        apiKey: String,
        assistantId: UUID
    ) async {
        var collectedAssistantText = ""
        do {
            for try await chunk in client.streamMessage(request: request, apiKey: apiKey) {
                if Task.isCancelled { break }
                collectedAssistantText += chunk
                if let index = messages.firstIndex(where: { $0.id == assistantId }) {
                    messages[index].content += chunk
                }
            }
            finalizeAssistantTurn(text: collectedAssistantText, assistantId: assistantId)
        } catch is CancellationError {
            rollBackTurn(assistantId: assistantId)
        } catch {
            logger.error(
                """
                OpenAI stream failed — \
                kind: \(String(describing: error)), \
                description: \(error.localizedDescription)
                """
            )
            self.error = error.localizedDescription
            self.errorAction = Self.makeErrorAction(for: error)
            rollBackTurn(assistantId: assistantId)
        }
    }

    /// Maps a stream failure to an optional user-facing remediation,
    /// with the same per-case routing as the other cloud sessions.
    private static func makeErrorAction(for error: Error) -> ChatErrorAction? {
        guard let aiError = error as? AICloudError else { return nil }
        switch aiError {
        case .creditBalanceTooLow:
            return urlAction(
                "https://platform.openai.com/settings/organization/billing/overview",
                label: Strings.Chat.openBilling,
                hint: Strings.Accessibility.chatOpenBillingHint
            )
        case .invalidCredentials:
            return ChatErrorAction(
                kind: .openSignIn,
                label: Strings.Chat.signInAgain,
                accessibilityHint: Strings.Accessibility.chatSignInAgainHint
            )
        case .permissionDenied:
            return urlAction(
                "https://platform.openai.com/settings/organization/limits",
                label: Strings.Chat.openPlans,
                hint: Strings.Accessibility.chatOpenPlansHint
            )
        case .contextWindowExceeded:
            return ChatErrorAction(
                kind: .clearChat,
                label: Strings.Chat.clearHistory,
                accessibilityHint: Strings.Accessibility.chatErrorClearChatHint
            )
        case .serviceOverloaded:
            return urlAction(
                "https://status.openai.com/",
                label: Strings.Chat.openStatusPage,
                hint: Strings.Accessibility.chatOpenStatusPageHint
            )
        case .networkUnavailable:
            return ChatErrorAction(
                kind: .retry,
                label: Strings.Chat.tryAgain,
                accessibilityHint: Strings.Accessibility.chatTryAgainHint
            )
        case .missingCredentials,
                .rateLimited,
                .serverError,
                .invalidRequest,
                .decodingFailure,
                .keychainFailure,
                .cancelled,
                .unexpectedStatus:
            return nil
        }
    }

    /// Builds a ``ChatErrorAction`` from a hard-coded URL string,
    /// coalescing a malformed literal to `nil` rather than crashing.
    private static func urlAction(
        _ urlString: String,
        label: LocalizedStringResource,
        hint: LocalizedStringResource
    ) -> ChatErrorAction? {
        guard let url = URL(string: urlString) else { return nil }
        return ChatErrorAction(url: url, label: label, accessibilityHint: hint)
    }

    /// Persists the completed assistant text, or rolls an empty
    /// exchange out of both queues.
    private func finalizeAssistantTurn(text: String, assistantId: UUID) {
        if text.isEmpty {
            rollBackTurn(assistantId: assistantId)
        } else {
            conversationHistory.append(OpenAIInputMessage(role: .assistant, content: text))
        }
    }

    /// Removes the placeholder assistant bubble and the matching
    /// user turn.
    private func rollBackTurn(assistantId: UUID) {
        messages.removeAll { $0.id == assistantId }
        if !conversationHistory.isEmpty {
            conversationHistory.removeLast()
        }
    }

    // MARK: - Local Rejection

    public func appendLocalRejection(userMessage: String, refusalText: String) {
        // Rendered as chat turns but kept out of
        // `conversationHistory` — the model shouldn't see rejected
        // content.
        messages.append(BonjourChatMessage(role: .user, content: userMessage))
        messages.append(BonjourChatMessage(role: .assistant, content: refusalText))
    }

    // MARK: - Clear Error

    /// Clears ``errorAction`` with ``error`` — the two are a paired
    /// surface, and the protocol default clears only the message.
    public func clearError() {
        error = nil
        errorAction = nil
    }

    // MARK: - Reset

    public func reset() {
        messages.removeAll()
        conversationHistory.removeAll()
        instructions = nil
        currentResponseLengthSnapshot = nil
        currentModel = nil
        lastContextSignature = nil
        error = nil
        errorAction = nil
        isGenerating = false
        intentBroker.consume()
    }

    // MARK: - Restore

    public func restore(messages: [BonjourChatMessage]) {
        self.messages = messages
        // History isn't rebuilt from these messages — they may carry
        // locally-rejected turns, and replaying them would re-bill
        // the user. Same trade-off the other sessions make.
        conversationHistory.removeAll()
        instructions = nil
        currentResponseLengthSnapshot = nil
        currentModel = nil
        lastContextSignature = nil
        error = nil
        errorAction = nil
        isGenerating = false
    }

    // MARK: - Model Selection

    /// API identifier of the model to send (e.g. `gpt-5.4-mini`).
    /// A raw `String` rather than ``OpenAIModel`` because the
    /// catalog is fetched at runtime — see
    /// `PreferencesStore.aiCloudModelIdentifier(for:)`.
    public var selectedModel: String = OpenAIModel.default.rawValue
}
