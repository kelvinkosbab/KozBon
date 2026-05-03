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
                Image.arrowUpRight
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding()
        }
        // Custom ButtonStyle (instead of `.plain`) so the card gets
        // a tactile press animation: subtle scale-down + dimmed tint
        // + slightly darker background while the finger is down,
        // snapping back on release. Without this, taps on the
        // recommended-prompt cards land instantly with no visual
        // confirmation, which on a chat surface where the
        // streaming response takes a beat to start can read as
        // "did I tap it?". The press feedback closes that gap.
        .buttonStyle(SuggestionCardButtonStyle(reduceMotion: reduceMotion))
        // Cap Dynamic Type on the suggestion cards. The card's HStack
        // is `Text + Spacer + chevron`, so at sizes above
        // `.accessibility2` the multi-line text wraps tall enough
        // that the trailing chevron either truncates or pushes
        // off-screen on compact iPhones. Capping at `.accessibility2`
        // keeps both readable; users at the very largest text sizes
        // still see scaled-up text and a visible chevron, just not
        // the full system-max scaling. The rest of the chat surface
        // (subtitle, bubbles, input) keeps full Dynamic Type.
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .accessibilityLabel(text)
        .accessibilityHint(String(localized: Strings.Accessibility.chatSuggestionHint))
        .accessibilityIdentifier(identifier)
    }
}

// MARK: - SuggestionCardButtonStyle

/// Press feedback for the recommended-prompt cards on the chat empty
/// state. The card scales down to ~97%, the background tint deepens,
/// and the whole label dims slightly while the finger is down — all
/// snapping back on release. Tuned to feel like a single press of a
/// physical key: enough visual difference to confirm the tap, brief
/// enough not to delay the user's perception of the response
/// starting to stream.
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
/// `.contentShape(...)` on the inner background pins the hit area to
/// the visible pill rather than the label's intrinsic bounds, so
/// taps near the multi-line text's empty trailing region still
/// register on the card. The previous `.plain` button style passed
/// through the label's bounds, which on wrapped suggestions
/// silently missed tall empty regions.
private struct SuggestionCardButtonStyle: ButtonStyle {

    let reduceMotion: Bool

    @ViewBuilder
    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        // Press feedback values tuned together so a quick tap
        // (~80 ms — most taps don't hold long enough to see a
        // full settle animation) still produces a visible squish:
        //
        //   - scale 0.94 (was 0.97) — 6% reduction is large enough
        //     to register at a glance even when the surrounding
        //     ScrollView is scrolling messages into place.
        //   - opacity 0.70 (was 0.85) — pairs the scale with a
        //     dimming pulse, so the press reads as a deliberate
        //     "depress" rather than a subtle hover state.
        //   - background tint 0.25 (was 0.2) — slightly deeper
        //     ink while pressed for the same reason.
        //   - spring response 0.18 (was 0.25) — faster
        //     attack/release so the visual change starts right
        //     when the finger lands and unwinds promptly on
        //     release. Damping stays low enough to look elastic
        //     without feeling jittery.
        //
        // Reduce Motion swaps the spring scale for an opacity-
        // only flicker; the new values still apply (so reduce-
        // motion users get the dimming and tint shift).
        let card = configuration.label
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.kozBonBlue.opacity(pressed ? 0.25 : 0.1))
            )
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .scaleEffect(reduceMotion ? 1.0 : (pressed ? 0.94 : 1.0))
            .opacity(pressed ? 0.70 : 1.0)
            .animation(
                reduceMotion
                    ? .easeOut(duration: 0.12)
                    : .spring(response: 0.18, dampingFraction: 0.6),
                value: pressed
            )

        #if !os(macOS)
        card.hoverEffect(.highlight)
        #else
        card
        #endif
    }
}
