//
//  ChatMessagesSeenAction.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - ChatMessagesSeenAction

/// Environment-injected callback the chat surface invokes when
/// the user has visibly caught up to the bottom of the message
/// list.
///
/// Owned by `AppCoreViewModel` (which tracks the last-seen
/// assistant message id), injected into the environment by
/// `AppCoreScene`, and called from
/// ``BonjourChatView/messageList(session:)`` whenever the scroll
/// view's geometry says the user is currently at the bottom
/// edge of the content. The tab-bar badge clears as soon as
/// this action runs.
///
/// Modeled as a single-method `Sendable` action so the env
/// boundary stays clean: no class reference flows out of
/// `AppCoreViewModel`, and SwiftUI's environment plumbing
/// doesn't need to know anything about the badge-state owner.
public struct ChatMessagesSeenAction: Sendable {

    /// The closure that records the user as having seen the
    /// most recent assistant message. `@MainActor` because
    /// every caller (the chat scroll view) is also main-actor
    /// isolated, and the closure typically mutates
    /// view-model state.
    public typealias Closure = @MainActor @Sendable () -> Void

    private let closure: Closure

    /// Creates an action that runs the supplied closure.
    public init(_ closure: @escaping Closure) {
        self.closure = closure
    }

    /// No-op action — the default value when nothing has been
    /// injected. The chat view safely calls into this on every
    /// scroll-to-bottom in preview / standalone contexts where
    /// no app-level view model exists.
    public static let noop = ChatMessagesSeenAction { }

    @MainActor
    public func callAsFunction() {
        closure()
    }
}

// MARK: - EnvironmentValues

private struct ChatMessagesSeenActionKey: EnvironmentKey {
    static let defaultValue: ChatMessagesSeenAction = .noop
}

public extension EnvironmentValues {

    /// The action the chat surface should call when the user
    /// reaches the bottom of the message list. See
    /// ``ChatMessagesSeenAction``.
    var chatMessagesSeenAction: ChatMessagesSeenAction {
        get { self[ChatMessagesSeenActionKey.self] }
        set { self[ChatMessagesSeenActionKey.self] = newValue }
    }
}
