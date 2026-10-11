//
//  BonjourChatViewModelTests+KeyboardScroll.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Testing
import BonjourAI
@testable import BonjourUI

// MARK: - BonjourChatViewModelTests · Keyboard Scroll Target

/// Where focus sends the transcript when the compose field is
/// tapped.
///
/// An extension on the parent suite rather than a second `@Suite`,
/// so these share the helpers above.
///
/// This is the testable half of
/// `scrollLatestMessageAboveKeyboard`; the half holding a
/// `ScrollViewProxy` still isn't reachable from a unit test.
extension BonjourChatViewModelTests {

    @Test("An unfocused field moves nothing")
    func unfocusedHasNoTarget() {
        let (viewModel, _) = makeViewModel()
        #expect(viewModel.keyboardScrollTarget(focused: false, messages: []) == nil)
    }

    /// The regression this fixes: a fresh chat has no messages, so
    /// keying the scroll off `messages.last` alone left the intro
    /// and suggestions sitting behind the keyboard.
    @Test("A focused field on an empty chat still scrolls, targeting the empty state")
    func emptyChatTargetsEmptyState() {
        let (viewModel, _) = makeViewModel()
        #expect(viewModel.keyboardScrollTarget(focused: true, messages: []) == .emptyState)
    }

    @Test("With messages, focus rides the newest bubble up")
    func populatedChatTargetsLastMessage() {
        let (viewModel, _) = makeViewModel()
        let first = BonjourChatMessage(role: .user, content: "hi")
        let last = BonjourChatMessage(role: .assistant, content: "hello")

        #expect(
            viewModel.keyboardScrollTarget(focused: true, messages: [first, last])
                == .message(last.id)
        )
    }

    @Test("A single message is its own target — the gate is emptiness, not a count")
    func singleMessageTargetsItself() {
        let (viewModel, _) = makeViewModel()
        let only = BonjourChatMessage(role: .user, content: "hi")

        #expect(
            viewModel.keyboardScrollTarget(focused: true, messages: [only])
                == .message(only.id)
        )
    }

    @Test("Losing focus moves nothing, even mid-conversation")
    func blurHasNoTargetWithMessages() {
        let (viewModel, _) = makeViewModel()
        let message = BonjourChatMessage(role: .user, content: "hi")
        #expect(viewModel.keyboardScrollTarget(focused: false, messages: [message]) == nil)
    }
}
