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
#if canImport(UIKit) && !os(watchOS)
import UIKit
#endif

// MARK: - Input Bar

extension BonjourChatView {

    @ViewBuilder
    func inputBar(session: any BonjourChatSessionProtocol) -> some View {
        // Single shared rounded-rectangle that holds both the
        // TextField and the Send button — same Messages / Mail
        // pattern, where the send affordance lives on the trailing
        // edge inside the field rather than as a separate sibling
        // widget.
        //
        // Single-line (no `axis: .vertical`) — iOS treats return
        // as a newline on a vertical TextField even with
        // `.submitLabel(.send)`, which is why the keyboard's Send
        // key was producing a stray `\n` in the input instead of
        // submitting. Without the vertical axis, `.onSubmit` fires
        // on return as expected. Long messages still scroll
        // horizontally inside the field; the trailing send button
        // stays reachable because it's pinned to the container's
        // edge, not to the text content.
        @Bindable var bindable = viewModel
        HStack(alignment: .center, spacing: .space8) {
            TextField(
                String(localized: Strings.Chat.inputPlaceholder),
                text: $bindable.inputText
            )
            .textFieldStyle(.plain)
            .submitLabel(.send)
            .focused($isInputFocused)
            .disabled(session.isGenerating)
            // Short, dedicated VoiceOver label ("Message") matching
            // Apple's pattern in Mail / Messages. The visible
            // placeholder ("Ask about your network…") is still
            // shown to sighted users, but its trailing ellipsis
            // reads awkwardly when announced aloud — `.accessibilityLabel`
            // overrides the placeholder fallback for VoiceOver.
            .accessibilityLabel(Strings.Accessibility.chatInputLabel)
            // Hint flips to the busy variant while the assistant
            // is streaming a response. The Send button below uses
            // the same flag so both controls read consistently.
            .accessibilityHint(
                session.isGenerating
                    ? String(localized: Strings.Accessibility.chatBusyHint)
                    : String(localized: Strings.Accessibility.chatInputHint)
            )
            .accessibilityIdentifier("chat_input_field")
            .onSubmit { submitTypedMessage(session: session) }

            // Capsule send button anchored to the trailing edge
            // inside the shared container. Sized 44 pt × 32 pt
            // (~1.4:1 width-to-height) so it reads as a
            // deliberate horizontal pill — recognizably "send"
            // rather than an undifferentiated icon.
            //
            // On iOS 26+ the background is a *tinted* Liquid
            // Glass capsule (via `.platformGlassBackground`),
            // which preserves the brand color while
            // participating in the glass layer hierarchy and
            // getting system press/hover feedback for free.
            // Older systems fall back to a solid fill so the
            // primary action still reads.
            //
            // The tint binds to `aiAccent` so the Send capsule
            // follows the active AI backend's brand — blue for
            // Apple Intelligence, Anthropic Cara orange for the
            // cloud path.
            Button {
                submitTypedMessage(session: session)
            } label: {
                Image.arrowUp
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
                    .frame(width: .size44, height: .size32)
                    .platformGlassBackground(tint: aiAccent, in: Capsule())
                    // Make the entire 44×32 capsule tappable, not
                    // just the tiny intrinsic-size arrow glyph at
                    // its center.
                    .contentShape(Capsule())
                    .opacity(viewModel.sendDisabled(session: session, isOffline: isOffline(session)) ? 0.4 : 1.0)
                    .animation(
                        reduceMotion ? nil : .easeInOut(duration: 0.15),
                        value: viewModel.sendDisabled(session: session, isOffline: isOffline(session))
                    )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.sendDisabled(session: session, isOffline: isOffline(session)))
            .accessibilityLabel(Strings.Chat.send)
            // Three-way hint so VoiceOver can explain *why* the
            // button is in its current state: busy / empty input
            // / enabled.
            .accessibilityHint(
                viewModel.sendButtonAccessibilityHint(session: session, isOffline: isOffline(session))
            )
            .accessibilityIdentifier("chat_send_button")
            // Cap Dynamic Type on the Send capsule. The 44 × 32 pt
            // frame is fixed, so at `.accessibility5` the SF
            // Symbol scales past the available space and clips
            // against the capsule's rounded ends.
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            // Press-and-hold magnification for users with low
            // vision (Settings → Accessibility → Larger Text →
            // "Show Larger Content Views").
            .accessibilityShowsLargeContentViewer()
            // Pointer / gaze hover effect on iPad with trackpad
            // and Vision Pro. macOS doesn't expose `.hoverEffect`,
            // so the modifier is gated out.
            #if !os(macOS)
            .hoverEffect(.highlight)
            #endif
        }
        // Inner padding of the shared field container. Leading
        // `.space14` for comfortable text inset, trailing
        // `.space8` so the Send capsule has visible breathing
        // room from the rounded-rect edge, vertical `.space6`
        // × 2 + 32 pt button = 44 pt total container height.
        .padding(.leading, .space14)
        .padding(.trailing, .space8)
        .padding(.vertical, .space6)
        .platformGlassBackground(
            in: RoundedRectangle(cornerRadius: .radius20, style: .continuous)
        )
        // Outer page-level padding stays symmetric so the rounded
        // container is the same distance from both screen edges.
        .padding()
    }

    /// Sends what the user typed, from Return or the Send button,
    /// and puts the keyboard away so the reply has the full screen.
    /// Suggestion chips don't come through here.
    func submitTypedMessage(session: any BonjourChatSessionProtocol) {
        // Synchronous haptic — see the suggestion-button action in
        // `BonjourChatView+EmptyState.swift` for the rationale.
        // Lifting the increment out of the async `sendMessage` path
        // lets feel and sight land together.
        viewModel.submitCount &+= 1
        dismissKeyboard()
        Task {
            await viewModel.sendMessage(
                viewModel.inputText,
                using: session,
                preferencesStore: preferencesStore,
                reduceMotion: reduceMotion,
                areCloudProvidersOffered: aiBackendAvailability.offersCloudProviders,
                isOffline: isOffline(session)
            )
        }
    }

    /// Clearing the focus state alone didn't reliably put the
    /// keyboard away after a send; the field is disabled as
    /// generation starts, in the same few updates. Resigning
    /// through the responder chain dismisses it directly.
    func dismissKeyboard() {
        isInputFocused = false
        #if canImport(UIKit) && !os(watchOS)
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
        #endif
    }
}
