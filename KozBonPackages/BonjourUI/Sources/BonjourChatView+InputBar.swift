//
//  BonjourChatView+InputBar.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourAI
import BonjourCore
import BonjourLocalization
import BonjourModels
import BonjourScanning

// MARK: - Input Bar

extension BonjourChatView {

    @ViewBuilder
    func inputBar(session: any BonjourChatSessionProtocol) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            // `.roundedBorder` renders a system-fixed height that looked too
            // thin for a chat surface. Switch to `.plain` and draw our own
            // padded capsule so the field has the same comfortable touch
            // depth as an iMessage compose bar, and so it grows cleanly
            // when the user types a multi-line message.
            //
            // On iOS 26+ the `.glassOrMaterialBackground` helper applies
            // Liquid Glass; older systems get `.ultraThinMaterial` instead.
            // Either way there is no solid tinted fill — the field
            // visually rides on top of whatever sits behind the compose
            // bar (the streaming chat messages blur through it cleanly).
            // Single-line (no `axis: .vertical`). iOS treats return as a
            // newline on a vertical TextField even with `.submitLabel(.send)`,
            // which is why the keyboard's Send key was producing a stray
            // `\n` in the input instead of submitting. Without the vertical
            // axis, `.onSubmit` fires on return as expected and the Send
            // label on the keyboard actually submits. Users who need to
            // send a long question can still type one — the field scrolls
            // horizontally and the send button remains reachable.
            TextField(
                String(localized: Strings.Chat.inputPlaceholder),
                text: $inputText
            )
            .textFieldStyle(.plain)
            .padding(.horizontal, .space14)
            .padding(.vertical, .space10)
            .glassOrMaterialBackground(
                in: RoundedRectangle(cornerRadius: .radius20, style: .continuous)
            )
            .submitLabel(.send)
            .focused($isInputFocused)
            .disabled(session.isGenerating)
            .accessibilityLabel(String(localized: Strings.Chat.inputPlaceholder))
            // Hint flips to the busy variant while the assistant is
            // streaming a response. Without this, VoiceOver still
            // announced the generic "type a question" hint after
            // the field went disabled, leaving users with no
            // explanation for why their typing wasn't being
            // accepted. The Send button below uses the same flag
            // so both controls read consistently.
            .accessibilityHint(
                session.isGenerating
                    ? String(localized: Strings.Accessibility.chatBusyHint)
                    : String(localized: Strings.Accessibility.chatInputHint)
            )
            .accessibilityIdentifier("chat_input_field")
            .onSubmit {
                // Synchronous haptic — see the suggestion-button
                // action in `BonjourChatView+EmptyState.swift` for
                // the rationale. Lifting the increment out of the
                // async `sendMessage` path lets feel and sight land
                // together when the user hits Return.
                submitCount &+= 1
                Task { await sendMessage(inputText, using: session) }
            }
            // No keyboard-accessory "Done" button. The `scrollDismissesKeyboard
            // (.interactively)` modifier on the message list already lets the
            // user dismiss the keyboard by dragging the chat downward, and
            // tapping `return` / the send button both dispatch the message.
            // A persistent "Done" bar above the keyboard was redundant and
            // competed visually with the compose UI.

            // Fixed-size capsule send button. The height matches the single-
            // line text field height (`.size40` ≈ vertical padding + body line
            // height), so in the common one-line case the field and the button
            // read as a matched pair. The HStack's `alignment: .bottom` then
            // pins the button to the bottom of the text field when the user
            // composes a multi-line message — same behavior as iMessage.
            //
            // Width is deliberately larger than height (`.size56` × `.size40`,
            // ~1.4:1) to give the capsule its horizontal pill shape rather
            // than appearing as a circle.
            //
            // On iOS 26+ the background is a *tinted* Liquid Glass capsule
            // (`.glassEffect(.regular.tint(.kozBonBlue).interactive())`),
            // which preserves the brand color while participating in the
            // glass layer hierarchy and getting system press/hover
            // feedback for free. Older systems fall back to the solid
            // `.kozBonBlue` fill so the primary action still reads.
            Button {
                // Synchronous haptic — see the suggestion-button
                // action for the rationale. Same pattern as
                // `.onSubmit` above.
                submitCount &+= 1
                Task { await sendMessage(inputText, using: session) }
            } label: {
                Image.arrowUp
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    // The glyph is purely decorative — the Button's own
                    // a11y label ("Send") is what VoiceOver should
                    // announce. Hiding the Image keeps the tree clean
                    // and prevents the SF Symbol default name from ever
                    // leaking through in edge cases.
                    .accessibilityHidden(true)
                    .frame(width: .size56, height: .size40)
                    .glassOrTintedBackground(tint: .kozBonBlue, in: Capsule())
                    // Make the entire `.size56 × .size40` capsule tappable,
                    // not just the tiny intrinsic-size arrow glyph at its
                    // center. `.buttonStyle(.plain)` defaults to hit-
                    // testing the label's intrinsic content — with a small
                    // `Image` inside a much larger `.frame`, most of the
                    // visually-filled pill was NOT tappable, and taps near
                    // the capsule edges silently missed. This was the
                    // "follow-up send doesn't work" symptom: users were
                    // hitting the pill, not the glyph.
                    .contentShape(Capsule())
                    .opacity(sendDisabled(session: session) ? 0.4 : 1.0)
                    .animation(
                        reduceMotion ? nil : .easeInOut(duration: 0.15),
                        value: sendDisabled(session: session)
                    )
            }
            .buttonStyle(.plain)
            .disabled(sendDisabled(session: session))
            .accessibilityLabel(String(localized: Strings.Chat.send))
            // Three-way hint so VoiceOver can explain *why* the
            // button is in its current state:
            //
            //   - generating: "Wait for the response to finish…"
            //   - empty input: "Type a message to enable this button"
            //   - enabled: "Sends your message and asks the assistant"
            //
            // Previously both disabled cases shared the empty-input
            // hint, which was actively misleading while the
            // assistant was still streaming — the user had typed
            // and submitted, then heard "type a message to
            // enable" when they tried to fire a follow-up.
            .accessibilityHint(sendButtonAccessibilityHint(session: session))
            .accessibilityIdentifier("chat_send_button")
        }
        .padding()
    }

    fileprivate func sendDisabled(session: any BonjourChatSessionProtocol) -> Bool {
        session.isGenerating
            || inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Returns the localized VoiceOver hint that matches the Send
    /// button's current state. Split out so the three-way logic
    /// (busy vs empty vs enabled) reads as a single guarded switch
    /// rather than a nested ternary at the call site.
    fileprivate func sendButtonAccessibilityHint(session: any BonjourChatSessionProtocol) -> String {
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

    func sendMessage(_ text: String, using session: any BonjourChatSessionProtocol) async {
        guard !session.isGenerating else { return }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // The submit haptic and input-text clear are driven by
        // callers (suggestion button action, send-button action,
        // TextField `.onSubmit`) — they fire `submitCount &+= 1`
        // synchronously the instant the user taps, which is what
        // makes the press animation, haptic, and (on the input
        // bar) text clear all land on the same render frame.
        // Doing it here would re-introduce the original bug
        // where the haptic ran one Task hop late.
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
            inputText = ""
        }
        isInputFocused = false

        // Client-side pre-filter catches obvious prompt-injection and
        // off-topic patterns without paying model latency. On rejection
        // we render the exchange as a normal chat turn (user message +
        // assistant refusal) — identical to how the model itself would
        // refuse — so the Chat surface stays coherent and the refusal
        // is visible even on a previously-empty chat.
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

        // Append the user's bubble to the visible conversation
        // synchronously, BEFORE any awaits. The fresh-scan path inside
        // `buildChatContext(forMessage:)` can stall for ~3 seconds on
        // live-state questions, and the production `session.send` was
        // previously what appended this message — meaning the user's
        // bubble didn't appear until after both awaits resolved. That
        // looked like the chat surface was frozen post-tap. Splitting
        // append from send via the protocol's
        // `appendUserMessage(_:)` puts the bubble on screen the moment
        // SwiftUI runs its next render pass.
        session.appendUserMessage(trimmed)

        let context = await buildChatContext(forMessage: trimmed)

        // Response length is derived from the user's Detail level
        // preference now — the standalone "Response length" picker was
        // removed because users found the two settings confusing
        // (both seemed to control "how much detail you get"). Basic
        // pairs with .standard, Technical pairs with .thorough.
        let detailLevel = BonjourServicePromptBuilder.ExpertiseLevel(
            rawValue: preferencesStore.aiExpertiseLevel
        ) ?? .basic
        session.responseLength = detailLevel.responseLength

        await session.send(trimmed, context: context)
    }

    /// Builds the `ChatContext` the assistant sees for the user's
    /// current message. When the message looks like a question about
    /// live network state ("what's on my network?", "list devices",
    /// "scan", and similar), runs a fresh `BonjourOneShotScanner`
    /// pass first so the assistant answers from current data instead
    /// of whatever the continuous scanner happened to have collected.
    /// Otherwise — for concept questions ("what is Matter?", "explain
    /// HomeKit") — passes through the cached
    /// ``BonjourServicesViewModel/flatActiveServices`` snapshot,
    /// which is what the chat used before fresh-scan-on-demand
    /// existed.
    ///
    /// The fresh-scan path takes ~3 s of additional latency before the
    /// model starts streaming — the typing indicator covers it. The
    /// detector ``ChatScanIntentDetector/wantsFreshScan(message:)`` is
    /// deliberately lenient because a false positive only costs that
    /// 3 s, while a false negative means the assistant answers a live-
    /// state question with stale data. We err toward more scanning.
    ///
    /// A fresh `BonjourServiceScanner` instance is used per scan
    /// rather than the shared one driving Discover, so the chat's
    /// snapshot doesn't disturb Discover's continuous observation —
    /// they run in parallel for the ~3 s window. Same isolation
    /// pattern the Siri intents (`ScanForServicesIntent`,
    /// `ListDiscoveredServicesIntent`) use.
    fileprivate func buildChatContext(
        forMessage message: String
    ) async -> BonjourChatPromptBuilder.ChatContext {
        let library = BonjourServiceType.fetchAll()
        let publishedServices = viewModel.sortedPublishedServices

        if ChatScanIntentDetector.wantsFreshScan(message: message) {
            let runner = BonjourOneShotScanner(scanner: BonjourServiceScanner())
            let freshServices = await runner.run(
                publishedServices: viewModel.publishManager.publishedServices
            )
            return BonjourChatPromptBuilder.ChatContext(
                discoveredServices: freshServices,
                publishedServices: publishedServices,
                serviceTypeLibrary: library,
                // The just-completed scan is by definition the most
                // recent; pin `lastScanTime` to now so the assistant's
                // freshness-aware phrasing reads as "data is fresh"
                // rather than "data may be stale."
                lastScanTime: Date(),
                isScanning: false
            )
        }

        return BonjourChatPromptBuilder.ChatContext(
            discoveredServices: viewModel.flatActiveServices,
            publishedServices: publishedServices,
            serviceTypeLibrary: library,
            lastScanTime: viewModel.lastScanTime,
            isScanning: viewModel.serviceScanner.isProcessing
        )
    }

    /// Returns a localized error message for the given validation rejection reason.
    fileprivate static func errorMessage(for reason: ChatInputValidator.Reason) -> String {
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
