//
//  ChatErrorBanner.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourAI
import BonjourLocalization

// MARK: - ChatErrorBanner

/// Inline error row rendered at the foot of the chat thread when
/// ``BonjourChatSessionProtocol/error`` is non-nil. Replaces the
/// previous plain red `Text` with a richer banner that pairs the
/// localized error string with an optional remediation button.
///
/// The button is driven by the session's
/// ``BonjourChatSessionProtocol/errorAction``. When `nil`, the
/// banner falls back to the message-only shape — same as the old
/// plain-text behavior — so non-actionable failures (rate limits,
/// generic server errors, etc.) read identically across all
/// backends.
///
/// Two flavors of action are supported:
/// - ``ChatErrorAction/Kind/openURL`` — banner renders an
///   internal `Link` that opens the URL in the user's browser.
///   No closure required from the parent.
/// - In-app kinds (``ChatErrorAction/Kind/openSignIn``,
///   ``ChatErrorAction/Kind/clearChat``,
///   ``ChatErrorAction/Kind/retry``) — banner renders a `Button`
///   that invokes ``onInAppAction`` with the kind. The parent
///   view dispatches the kind to the right view-model affordance
///   (sheet toggle, pending-clear flag, retry pipeline).
///
/// Layout uses leading/trailing exclusively so the banner mirrors
/// cleanly under RTL locales (Arabic, Hebrew). The triangle icon
/// stays oriented the same in both directions — its meaning isn't
/// directional.
struct ChatErrorBanner: View {

    /// Localized error description, already converted to `String`
    /// by the caller. Comes straight from
    /// `session.error` — the chat surface stores
    /// `error.localizedDescription` there per backend.
    let message: String

    /// Optional remediation. When present, renders as a button or
    /// link after the message; when `nil`, only the message
    /// shows.
    let action: ChatErrorAction?

    /// Dispatcher closure invoked by the banner button for any
    /// non-URL action kind. The closure receives the action's
    /// ``ChatErrorAction/Kind`` so the parent can pattern-match
    /// it to the matching affordance (e.g.,
    /// ``ChatErrorAction/Kind/clearChat`` triggers the chat-clear
    /// flow on the view model; ``ChatErrorAction/Kind/retry``
    /// kicks off a retry of the last user message).
    ///
    /// `nil` is permitted — useful for previews and the
    /// degenerate case where the parent doesn't need to handle
    /// any in-app action. In that case the in-app buttons render
    /// but tap is a no-op. Production call sites always supply a
    /// closure.
    let onInAppAction: ((ChatErrorAction.Kind) -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Icon carries the error color on its own — keeps the
            // "something went wrong" signal without painting the
            // message text in low-contrast red.
            Image.errorBanner
                .font(.title3)
                .foregroundStyle(.red)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 10) {
                Text(message)
                    .font(.subheadline)
                    // `.primary` reads against the tinted background;
                    // the previous `.red` text-on-red-tint was low
                    // contrast and hard to skim.
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                if let action {
                    actionButton(for: action)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        // Fill the width of the surrounding VStack — same
        // `maxWidth: .infinity` + tiny outer inset as the
        // long-conversation banner. Without this the banner
        // shrink-wraps to its text content and reads as
        // noticeably narrower than the message bubbles around
        // it.
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            // Soft red tint reads as a status surface, not a
            // stop sign. The icon + button carry the error
            // color signal at full saturation.
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.red.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.red.opacity(0.25), lineWidth: 1)
        )
        // Match the long-conversation banner's 4pt outer inset.
        // The chat's outer VStack already supplies the chat-width
        // padding; this is just a hair of breathing room from
        // the message-bubble edges.
        .padding(.horizontal, 4)
        // Combine icon + message into a single VoiceOver element so
        // swiping through the chat thread doesn't surface the
        // decorative icon separately. The action button stays a
        // distinct focusable element — VoiceOver users need to
        // reach it independently to activate the remediation.
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Strings.Accessibility.error(message))
    }

    // MARK: - Action Button

    /// Renders the right SwiftUI primitive for the action's kind:
    /// a `Link` for ``ChatErrorAction/Kind/openURL`` (so iOS
    /// handles the URL open + universal-link routing), or a
    /// `Button` for in-app kinds (so the parent's closure runs in
    /// the app's process).
    @ViewBuilder
    private func actionButton(for action: ChatErrorAction) -> some View {
        switch action.kind {
        case .openURL(let url):
            // `.tint(.red)` overrides the chat's surrounding
            // accent color so the button reads as "fix the
            // error" rather than picking up the Anthropic
            // orange accent and clashing with the red banner
            // context. The accessibility hint disambiguates URL
            // destinations by action kind.
            Link(destination: url) {
                Text(action.label)
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .tint(.red)
            .accessibilityHint(resolvedHint(for: action))

        case .openSignIn, .clearChat, .retry:
            Button {
                onInAppAction?(action.kind)
            } label: {
                Text(action.label)
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .tint(.red)
            .accessibilityHint(resolvedHint(for: action))
        }
    }

    /// Resolves the right VoiceOver hint for the action. Prefers
    /// the action's own ``ChatErrorAction/accessibilityHint``
    /// (which the session sets per failure kind, so billing /
    /// plans / status get distinct hints), falling back to a
    /// per-kind default when the session didn't supply one.
    private func resolvedHint(for action: ChatErrorAction) -> LocalizedStringResource {
        if let hint = action.accessibilityHint {
            return hint
        }
        switch action.kind {
        case .openURL:
            // No URL-specific default — call sites should always
            // pass `accessibilityHint` for URL actions because
            // the destination differs (billing vs plans vs
            // status). Coalesce to billing as the most common
            // historical case.
            return Strings.Accessibility.chatOpenBillingHint
        case .openSignIn:
            return Strings.Accessibility.chatSignInAgainHint
        case .clearChat:
            return Strings.Accessibility.chatErrorClearChatHint
        case .retry:
            return Strings.Accessibility.chatTryAgainHint
        }
    }
}
