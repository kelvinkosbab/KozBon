//
//  ChatSignInPromptView.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourAICore
import BonjourCore
import BonjourLocalization

// MARK: - ChatSignInPromptView

/// Full-surface prompt rendered in the chat tab when the user
/// has selected a cloud backend but hasn't signed in yet.
/// Replaces the message list + compose bar so the user can't
/// type a question that wouldn't have anywhere to go — instead
/// they're guided to the sign-in flow.
///
/// The chat view's `chatContent` branches to this view when
/// `needsCloudSignIn` is true. Tapping the primary action
/// surfaces the same `AICloudSignInSheet` Settings uses, so the
/// sign-in flow is reachable from both places without
/// duplicating logic.
struct ChatSignInPromptView: View {

    /// Which backend the user picked — drives the brand glyph,
    /// tint, headline, and body copy. The Anthropic and GitHub
    /// branches share layout; only the per-provider strings and
    /// styling diverge.
    let backend: AIBackend

    /// Closure that triggers the parent chat view to present the
    /// sign-in sheet. The view owns the sheet's `isPresented`
    /// binding because the chat view also needs to refresh its
    /// key-state cache when the sheet dismisses — passing the
    /// trigger up keeps both concerns colocated.
    let onSignInTapped: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Provider brand glyph. Sized to match
            // `ContentUnavailableView`'s default symbol scale so
            // the prompt reads as a native empty state.
            //
            // Dynamic Type cap: at `.accessibility4` and above
            // the 56pt glyph would dominate the prompt on a
            // compact iPhone. Capping at `.accessibility3` keeps
            // it visible while the surrounding text continues
            // scaling through the full system range.
            backend.icon
                .font(.system(size: 56))
                .foregroundStyle(backend.accentColor)
                .dynamicTypeSize(...DynamicTypeSize.accessibility3)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text(promptTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    // VoiceOver's heading rotor is one of the
                    // most-used navigation aids; promoting the
                    // title to a header lets blind users jump
                    // straight to "what is this screen?"
                    // without swiping through every element.
                    .accessibilityAddTraits(.isHeader)

                Text(promptBody)
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
                    Text(signInLabel)
                } icon: {
                    Image.signIn
                        .accessibilityHidden(true)
                }
                .font(.body.weight(.semibold))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(backend.accentColor)
            .accessibilityHint(String(localized: Strings.Accessibility.aiCloudSignInHint))
            .accessibilityIdentifier("chat_sign_in_prompt_button")
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Page-level identifier so UI tests can verify the prompt
        // surfaces in the right scenarios.
        .accessibilityIdentifier("chat_sign_in_prompt")
        // Actively announce the prompt when it mounts. A
        // VoiceOver user gets no signal that the chat content
        // disappeared without an active announcement; the
        // read-out lands their focus on the new state right
        // away.
        .onAppear {
            AccessibilityNotification.Announcement(
                String(localized: promptTitle)
            ).post()
        }
    }

    // MARK: - Per-Backend Copy

    private var promptTitle: LocalizedStringResource {
        switch backend {
        case .anthropic, .appleIntelligence:
            // The Apple branch is defensive — the chat view
            // gates this prompt to cloud backends only, but a
            // future refactor that broadens it (e.g., an
            // on-device-unavailable banner) should still get
            // sensible copy. Falls back to the Claude string.
            return Strings.Chat.signInToClaudeTitle
        case .github:
            return Strings.Chat.signInToGitHubTitle
        }
    }

    private var promptBody: LocalizedStringResource {
        switch backend {
        case .anthropic, .appleIntelligence:
            return Strings.Chat.signInToClaudeBody
        case .github:
            return Strings.Chat.signInToGitHubBody
        }
    }

    private var signInLabel: LocalizedStringResource {
        switch backend {
        case .anthropic, .appleIntelligence:
            return Strings.Settings.aiCloudSignIn
        case .github:
            return Strings.Settings.aiCloudSignInGitHub
        }
    }
}
