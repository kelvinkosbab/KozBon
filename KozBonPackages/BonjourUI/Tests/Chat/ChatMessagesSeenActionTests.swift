//
//  ChatMessagesSeenActionTests.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Testing
@testable import BonjourUI

// MARK: - ChatMessagesSeenActionTests

/// Pins the contract of ``ChatMessagesSeenAction`` — the
/// environment-injected callback the chat scroll view fires when
/// the user has scrolled to the bottom. The action is a `Sendable`
/// wrapper around a `@MainActor` closure; this suite verifies the
/// noop default doesn't crash, the closure is invoked on call,
/// and multiple invocations re-fire the closure each time.
@Suite("ChatMessagesSeenAction")
@MainActor
struct ChatMessagesSeenActionTests {

    @Test("`noop` is invocable and runs without effect")
    func noopIsInvocable() {
        // No-op should not crash — it's the default value when
        // nothing's been injected (previews, standalone tests).
        ChatMessagesSeenAction.noop()
        ChatMessagesSeenAction.noop()
    }

    @Test("`callAsFunction` invokes the underlying closure exactly once per call")
    func callAsFunctionInvokesClosure() {
        let counter = Counter()
        let action = ChatMessagesSeenAction { counter.bump() }

        #expect(counter.value == 0)
        action()
        #expect(counter.value == 1)
    }

    @Test("Multiple invocations run the closure multiple times")
    func multipleInvocationsCount() {
        let counter = Counter()
        let action = ChatMessagesSeenAction { counter.bump() }

        for _ in 0..<5 {
            action()
        }
        #expect(counter.value == 5)
    }

    // MARK: - Helpers

    /// `@MainActor` counter. The closure passed into
    /// `ChatMessagesSeenAction` is `@MainActor`-isolated, so its
    /// captured state has to be reachable from main without
    /// crossing actor boundaries.
    @MainActor
    private final class Counter {
        var value = 0
        func bump() { value += 1 }
    }
}
