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
                // RTL mirroring. The solid accent disc keeps the white
                // glyph legible on the glass chip in both appearances
                // and mirrors the send button's backend tint.
                Image.arrowUp
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(Circle().fill(aiAccent))
                    .accessibilityHidden(true)
            }
            // Pill padding: roomier horizontally than vertically so
            // the capsule's rounded caps don't crowd the text.
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        // Custom ButtonStyle (instead of `.plain`) so the chip gets
        // visible press feedback. Without it, taps land with no
        // visual confirmation, which on a chat surface where the
        // streaming response takes a beat to start reads as "did I
        // tap it?".
        .buttonStyle(SuggestionCardButtonStyle())
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

/// Press feedback and surface for the recommended-prompt chips on the
/// chat empty state.
///
/// The chips are controls floating over the ambient mesh, so they use
/// interactive Liquid Glass: the system supplies the press bounce and
/// highlight, and adapts the glass to light, dark, Reduce Transparency,
/// and Increase Contrast. A translucent colored fill used to sit here,
/// but it blended with the wash behind it into an off-tone blue.
///
/// The label also dims while pressed, so press confirmation survives
/// Reduce Motion, which tones down the glass's own animation.
///
/// On iOS / iPadOS / visionOS the style additionally applies the
/// system `.hoverEffect()` so pointer-driven (iPad with trackpad)
/// and gaze-driven (Vision Pro) input gets the same highlight the
/// rest of Apple's UI uses. Native macOS doesn't expose
/// `hoverEffect`; the underlying `Button` provides its own focus
/// ring and cursor there.
///
/// `.contentShape(.capsule)` pins the hit area to the visible pill
/// rather than the label's intrinsic bounds, so taps near a
/// multi-line suggestion's empty trailing region still register.
private struct SuggestionCardButtonStyle: ButtonStyle {

    @ViewBuilder
    func makeBody(configuration: Configuration) -> some View {
        let chip = configuration.label
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            #if os(visionOS)
            .glassBackgroundEffect(in: Capsule(style: .continuous))
            #else
            .glassEffect(.regular.interactive(), in: Capsule(style: .continuous))
            #endif
            .contentShape(.capsule)

        #if !os(macOS)
        chip.hoverEffect(.highlight)
        #else
        chip
        #endif
    }
}
