//
//  ChatErrorAction.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - ChatErrorAction

/// A user-actionable remediation paired with a chat-surface
/// error. When the chat surface fails for a reason the user can
/// resolve — either by opening an external URL or by triggering
/// an in-app action — the session attaches one of these to its
/// error state. The chat view renders the action as a button
/// next to the error message so users can fix the underlying
/// problem in one tap.
///
/// Held as a value type so SwiftUI can diff it cheaply across
/// renders. The `label` is a `LocalizedStringResource` so the
/// button text translates with the rest of the app.
///
/// The session emits *semantic* action kinds (e.g.
/// ``Kind/clearChat``); the view layer binds those kinds to the
/// concrete button or link UI. This decouples session code from
/// view-model concerns like "what does Clear Chat actually call?"
/// — the session just states the intent.
public struct ChatErrorAction: Sendable, Equatable {

    /// The semantic action the banner button performs.
    ///
    /// Two flavors:
    /// - URL-based (``openURL``) — the banner renders a `Link`
    ///   internally; tapping leaves the app for the browser.
    /// - In-app (``openSignIn``, ``clearChat``, ``retry``) — the
    ///   banner renders a `Button` and invokes a closure supplied
    ///   by the parent view, which knows how to drive the
    ///   in-app affordance.
    public enum Kind: Sendable, Equatable {

        /// Open the given URL in the user's default browser.
        /// Used for billing console, keys console, plan
        /// management, status page, etc.
        case openURL(URL)

        /// Open the in-app Anthropic sign-in sheet so the user
        /// can paste a fresh API key. Used when the stored key
        /// is rejected (``AICloudError/invalidCredentials``);
        /// sending them to the keys console alone would leave
        /// them stuck — they'd still have to come back and
        /// re-enter the new key via Settings.
        case openSignIn

        /// Clear the chat history. Used when the conversation's
        /// accumulated history exceeds the model's context
        /// window (``AICloudError/contextWindowExceeded``);
        /// truncating the history is the only way to send
        /// another message in the same session.
        case clearChat

        /// Re-send the last user message. Used for transient
        /// failures the user can recover from without typing
        /// anything new — primarily
        /// ``AICloudError/networkUnavailable``, but the design
        /// generalizes to other "the next attempt might just
        /// work" cases.
        case retry
    }

    /// The semantic action to perform.
    public let kind: Kind

    /// Localized button label. The chat surface renders this
    /// inside a SwiftUI `Button` / `Link` so it picks up the
    /// active backend's accent color automatically.
    public let label: LocalizedStringResource

    /// Optional VoiceOver hint applied to the action button.
    /// Each URL action gets its own (billing console vs plans
    /// console vs status page) because the destination is
    /// invisible to screen-reader users; the button label
    /// alone ("Manage plan") doesn't tell them they're about
    /// to leave the app. In-app kinds also carry distinct
    /// hints — clearing chat vs re-sending are fundamentally
    /// different operations.
    ///
    /// `nil` is permitted for kinds the banner can default
    /// itself (e.g., the `retry` kind has a single
    /// well-defined hint). The banner falls back to
    /// per-kind defaults when this is `nil`.
    public let accessibilityHint: LocalizedStringResource?

    public init(
        kind: Kind,
        label: LocalizedStringResource,
        accessibilityHint: LocalizedStringResource? = nil
    ) {
        self.kind = kind
        self.label = label
        self.accessibilityHint = accessibilityHint
    }

    /// Convenience initializer for the common ``Kind/openURL``
    /// case. Kept around so existing call sites that built
    /// URL-flavored actions don't need to migrate.
    public init(
        url: URL,
        label: LocalizedStringResource,
        accessibilityHint: LocalizedStringResource? = nil
    ) {
        self.kind = .openURL(url)
        self.label = label
        self.accessibilityHint = accessibilityHint
    }
}
