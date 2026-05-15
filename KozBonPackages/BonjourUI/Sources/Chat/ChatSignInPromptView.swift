//
//  ChatSignInPromptView.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourCore
import BonjourLocalization

// MARK: - ChatSignInPromptView

/// Full-surface prompt rendered in the chat tab when the user
/// has selected the Anthropic backend but hasn't signed in yet.
/// Replaces the message list + compose bar so the user can't
/// type a question that wouldn't have anywhere to go — instead
/// they're guided to the sign-in flow.
///
/// The chat view's `chatContent` branches to this view when
/// `needsClaudeSignIn` is true. Tapping the primary action
/// surfaces the same `AICloudSignInSheet` Settings uses, so the
/// sign-in flow is reachable from both places without
/// duplicating logic.
struct ChatSignInPromptView: View {

    /// Closure that triggers the parent chat view to present the
    /// sign-in sheet. The view owns the sheet's `isPresented`
    /// binding because the chat view also needs to refresh its
    /// `hasAnthropicKey` flag when the sheet dismisses — passing
    /// the trigger up keeps both concerns colocated.
    let onSignInTapped: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Claude brand glyph (template-rendered, so the
            // `.foregroundStyle(.kozBonAnthropic)` tint colors
            // the silhouette in Cara orange). Sized to match
            // `ContentUnavailableView`'s default symbol scale so
            // the prompt reads as a native empty state, not an
            // ad-hoc panel.
            //
            // Dynamic Type cap: at `.accessibility4` and above,
            // the 56pt glyph would dominate the prompt on a
            // compact iPhone and push the title + body off-
            // screen. Capping the icon at `.accessibility3`
            // keeps it visible while the surrounding text
            // continues scaling through the full system range.
            Image.anthropicClaude
                .font(.system(size: 56))
                .foregroundStyle(Color.kozBonAnthropic)
                .dynamicTypeSize(...DynamicTypeSize.accessibility3)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text(Strings.Chat.signInToClaudeTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    // VoiceOver's heading rotor is one of the
                    // most-used navigation aids; promoting the
                    // title to a header lets blind users jump
                    // straight to "what is this screen?"
                    // without swiping through every element.
                    .accessibilityAddTraits(.isHeader)

                Text(Strings.Chat.signInToClaudeBody)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)

            Button {
                onSignInTapped()
            } label: {
                Label {
                    Text(Strings.Settings.aiCloudSignIn)
                } icon: {
                    Image.signIn
                        .accessibilityHidden(true)
                }
                .font(.body.weight(.semibold))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.kozBonAnthropic)
            .accessibilityHint(String(localized: Strings.Accessibility.aiCloudSignInHint))
            .accessibilityIdentifier("chat_sign_in_prompt_button")
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Page-level identifier so UI tests can verify the prompt
        // surfaces in the right scenarios.
        .accessibilityIdentifier("chat_sign_in_prompt")
        // Actively announce the prompt when it mounts. The
        // prompt swaps in for the chat surface — typically
        // either on first land (user picked Anthropic without
        // a key, then opened the chat tab) or after a
        // mid-session sign-out (the credentials-changed
        // notification refreshes the backend and the chat view
        // re-renders to this prompt). A VoiceOver user gets no
        // signal that the chat content disappeared without an
        // active announcement; the read-out lands their focus
        // on the new state right away.
        .onAppear {
            AccessibilityNotification.Announcement(
                String(localized: Strings.Chat.signInToClaudeTitle)
            ).post()
        }
    }
}
