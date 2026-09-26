//
//  BonjourChatView+EmptyState.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourAI
import BonjourLocalization

// MARK: - Empty State

extension BonjourChatView {

    /// The intro + suggestion buttons rendered at the top of the
    /// chat ScrollView. Always present in the layout (never
    /// conditionally swapped) so a fresh chat shows them first
    /// and a populated chat keeps them as scrolled-off-above
    /// content the user can scroll back to. The wrapping
    /// ScrollView and its `scrollDismissesKeyboard` modifier live
    /// on `messageList(session:)` — this function returns just
    /// the body of the section.
    ///
    /// The page title ("Ask about your network") lives in the
    /// navigation bar, not in this content block — duplicating it
    /// here would push the suggestions off the first viewport on
    /// compact iPhones and read as visual noise once the title
    /// collapses inline. A single subtitle line is the lead-in
    /// above the suggestions so they have one concise hint; the
    /// previous Apple-Intelligence sparkle glyph was removed
    /// because the chat surface is the obvious AI surface — the
    /// glyph was redundant signaling that ate the first ~40 pt
    /// of the empty-state viewport.
    @ViewBuilder
    func emptyStateContent(session: any BonjourChatSessionProtocol) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(Strings.Chat.emptySubtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("chat_empty_state")

            VStack(spacing: 8) {
                suggestionButton(
                    text: String(localized: Strings.Chat.suggestion1),
                    identifier: "chat_suggestion_1",
                    session: session
                )
                suggestionButton(
                    text: String(localized: Strings.Chat.suggestion2),
                    identifier: "chat_suggestion_2",
                    session: session
                )
                suggestionButton(
                    text: String(localized: Strings.Chat.suggestion3),
                    identifier: "chat_suggestion_3",
                    session: session
                )
                suggestionButton(
                    text: String(localized: Strings.Chat.suggestion4),
                    identifier: "chat_suggestion_4",
                    session: session
                )
                suggestionButton(
                    text: String(localized: Strings.Chat.suggestion5),
                    identifier: "chat_suggestion_5",
                    session: session
                )
                suggestionButton(
                    text: String(localized: Strings.Chat.suggestion6),
                    identifier: "chat_suggestion_6",
                    session: session
                )
                // "What's new in this version?" — each localized
                // value contains a phrase
                // `ChatWhatsNewIntentDetector` matches, so tapping
                // it injects KozBon's real release notes into the
                // assistant's context.
                suggestionButton(
                    text: String(localized: Strings.Chat.suggestion7),
                    identifier: "chat_suggestion_7",
                    session: session
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    fileprivate func suggestionButton(
        text: String,
        identifier: String,
        session: any BonjourChatSessionProtocol
    ) -> some View {
        Button {
            // Fire the submit haptic SYNCHRONOUSLY in the Button
            // action so the user feels the tap the instant it
            // registers. The VM's `sendMessage` is async; doing
            // this from inside the async path would fire the
            // haptic a few render cycles late, by which time the
            // press animation has been interrupted by the
            // ScrollView scroll-up.
            viewModel.submitCount &+= 1
            // Don't pre-focus the compose field. Triggering a
            // ~250 ms keyboard slide-up on top of the
            // suggestions-scroll-up and the bubble-insert drowns
            // out the press animation and adds perceived latency.
            // Users tap the input manually when they're ready
            // to type a follow-up.
            Task {
                await viewModel.sendMessage(
                    text,
                    using: session,
                    preferencesStore: preferencesStore,
                    reduceMotion: reduceMotion
                )
            }
        } label: {
            HStack {
                Text(text)
                    .multilineTextAlignment(.leading)
                Spacer()
                // Same `arrow.up` the compose bar's send button
                // uses, so a suggestion reads as "send this" rather
                // than "open this". Straight up is direction-neutral,
                // so unlike the previous diagonal glyph it needs no
                // RTL mirroring.
                Image.arrowUp
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
            }
            // Pill padding: roomier horizontally than vertically so
            // the capsule's rounded caps don't crowd the text.
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        // Custom ButtonStyle (instead of `.plain`) so the chip gets
        // a tactile press animation: scale-down + deeper fill +
        // dimmed label while the finger is down, snapping back on
        // release. Without this, taps land with no visual
        // confirmation, which on a chat surface where the streaming
        // response takes a beat to start reads as "did I tap it?".
        .buttonStyle(SuggestionCardButtonStyle(reduceMotion: reduceMotion))
        // Cap Dynamic Type on the suggestion chips. The chip's
        // HStack is `Text + Spacer + arrow`, so at sizes above
        // `.accessibility2` the multi-line text wraps tall enough
        // that the trailing arrow either truncates or pushes
        // off-screen on compact iPhones. Capping at `.accessibility2`
        // keeps both readable; users at the very largest text sizes
        // still see scaled-up text and a visible arrow, just not
        // the full system-max scaling. The rest of the chat surface
        // (subtitle, bubbles, input) keeps full Dynamic Type.
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .accessibilityLabel(text)
        .accessibilityHint(Strings.Accessibility.chatSuggestionHint)
        .accessibilityIdentifier(identifier)
    }
}

// MARK: - SuggestionCardButtonStyle

/// Press feedback for the recommended-prompt chips on the chat empty
/// state. The chip scales down to ~94%, its fill deepens, and the
/// whole label dims slightly while the finger is down — all snapping
/// back on release. Tuned to feel like a single press of a physical
/// key: enough visual difference to confirm the tap, brief enough
/// not to delay the user's perception of the response starting to
/// stream.
///
/// The `reduceMotion` flag swaps the spring scale for an opacity-only
/// flicker so users with the system Reduce Motion preference still
/// get press confirmation without the transform.
///
/// On iOS / iPadOS / visionOS the style additionally applies the
/// system `.hoverEffect()` so pointer-driven (iPad with trackpad)
/// and gaze-driven (Vision Pro) input gets the same lift/highlight
/// that the rest of Apple's UI uses on those platforms. Native
/// macOS doesn't expose `hoverEffect`, so the modifier is gated
/// out there — mouse hover on macOS still works because the
/// underlying `Button` provides its own focus ring and a hand
/// cursor by default.
///
/// `.contentShape(.capsule)` pins the hit area to the visible pill
/// rather than the label's intrinsic bounds, so taps near a
/// multi-line suggestion's empty trailing region still register.
private struct SuggestionCardButtonStyle: ButtonStyle {

    let reduceMotion: Bool

    /// Resting fill opacity.
    ///
    /// Well short of an iMessage bubble's solid fill: these chips
    /// are suggestions behind the ambient mesh wash, not sent
    /// messages, so the fill has to stay translucent enough that
    /// the wash reads through it and light enough that `.primary`
    /// label text keeps its contrast in both appearances.
    private static let restingFill: Double = 0.55

    /// Pressed fill opacity. The +0.20 delta is what makes a quick
    /// (~80 ms) tap visibly register.
    private static let pressedFill: Double = 0.75

    @ViewBuilder
    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        // System blue rather than the chat surface's backend accent:
        // these read as iMessage-style send affordances, and the
        // iMessage association only holds in blue. The compose
        // bar's send button and the user's own message bubbles
        // still follow `aiAccent`, so the active backend is still
        // visible on the surface.
        let chip = configuration.label
            .background(
                Capsule(style: .continuous)
                    .fill(Color.blue.opacity(pressed ? Self.pressedFill : Self.restingFill))
            )
            .contentShape(.capsule)
            .scaleEffect(reduceMotion ? 1.0 : (pressed ? 0.94 : 1.0))
            .opacity(pressed ? 0.70 : 1.0)
            .animation(
                reduceMotion
                    ? .easeOut(duration: 0.12)
                    : .spring(response: 0.18, dampingFraction: 0.6),
                value: pressed
            )

        #if !os(macOS)
        chip.hoverEffect(.highlight)
        #else
        chip
        #endif
    }
}
