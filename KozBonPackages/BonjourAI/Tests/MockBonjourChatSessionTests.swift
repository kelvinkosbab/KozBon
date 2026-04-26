//
//  MockBonjourChatSessionTests.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourAI
import BonjourCore
import BonjourModels

// MARK: - MockBonjourChatSessionTests

@Suite("MockBonjourChatSession")
@MainActor
struct MockBonjourChatSessionTests {

    private var emptyContext: BonjourChatPromptBuilder.ChatContext {
        BonjourChatPromptBuilder.ChatContext()
    }

    // MARK: - Initial State

    @Test("A fresh mock session starts with empty messages, no error, and zero call counts")
    func initialStateIsEmpty() {
        let mock = MockBonjourChatSession()
        #expect(mock.messages.isEmpty)
        #expect(!mock.isGenerating)
        #expect(mock.error == nil)
        #expect(mock.sendCallCount == 0)
        #expect(mock.resetCallCount == 0)
    }

    // MARK: - Send

    @Test("`send` appends both the user message and the canned assistant reply in order")
    func sendAppendsUserAndAssistantMessages() async {
        let mock = MockBonjourChatSession(cannedReply: "Test reply")
        await mock.send("Hello", context: emptyContext)
        #expect(mock.messages.count == 2)
        #expect(mock.messages[0].role == .user)
        #expect(mock.messages[0].content == "Hello")
        #expect(mock.messages[1].role == .assistant)
        #expect(mock.messages[1].content == "Test reply")
    }

    @Test("`sendCallCount` increments once per `send` invocation, regardless of context")
    func sendIncrementsCallCount() async {
        let mock = MockBonjourChatSession()
        await mock.send("One", context: emptyContext)
        await mock.send("Two", context: emptyContext)
        #expect(mock.sendCallCount == 2)
    }

    @Test("Empty input is silently dropped — no message appended, counter unchanged")
    func sendIgnoresEmptyInput() async {
        let mock = MockBonjourChatSession()
        await mock.send("", context: emptyContext)
        #expect(mock.sendCallCount == 0)
        #expect(mock.messages.isEmpty)
    }

    @Test("Whitespace-only input is also dropped (matches the real session's trim-then-check)")
    func sendIgnoresWhitespaceOnlyInput() async {
        let mock = MockBonjourChatSession()
        await mock.send("   \n\t  ", context: emptyContext)
        #expect(mock.sendCallCount == 0)
    }

    @Test("`send` trims surrounding whitespace before storing the user message")
    func sendTrimsWhitespace() async {
        let mock = MockBonjourChatSession()
        await mock.send("  hello  ", context: emptyContext)
        #expect(mock.messages[0].content == "hello")
    }

    @Test("`send` records the most recent context so tests can assert what was passed")
    func sendStoresLastContext() async {
        let mock = MockBonjourChatSession()
        let context = BonjourChatPromptBuilder.ChatContext()
        await mock.send("Hi", context: context)
        #expect(mock.lastContext != nil)
    }

    // MARK: - Reset

    @Test("`reset` clears the message history and bumps `resetCallCount`")
    func resetClearsMessages() async {
        let mock = MockBonjourChatSession()
        await mock.send("Hello", context: emptyContext)
        #expect(!mock.messages.isEmpty)

        mock.reset()
        #expect(mock.messages.isEmpty)
        #expect(mock.resetCallCount == 1)
    }

    @Test("`reset` clears any pending error and the `isGenerating` flag")
    func resetClearsErrorAndGeneratingFlags() {
        let mock = MockBonjourChatSession()
        mock.error = "Something failed"
        mock.reset()
        #expect(mock.error == nil)
        #expect(!mock.isGenerating)
    }

    // MARK: - Canned Reply

    @Test("Custom `cannedReply` controls the assistant content the mock returns from `send`")
    func cannedReplyCanBeCustomized() async {
        let mock = MockBonjourChatSession(cannedReply: "Custom reply")
        await mock.send("Hi", context: emptyContext)
        #expect(mock.messages.last?.content == "Custom reply")
    }

    // MARK: - Multi-turn History

    @Test("Three sends produce six messages in user/assistant alternating order")
    func multipleTurnsAllAppearInHistory() async {
        let mock = MockBonjourChatSession(cannedReply: "ack")
        await mock.send("First question", context: emptyContext)
        await mock.send("Second question", context: emptyContext)
        await mock.send("Third question", context: emptyContext)

        #expect(mock.messages.count == 6)
        #expect(mock.messages[0].role == .user)
        #expect(mock.messages[0].content == "First question")
        #expect(mock.messages[1].role == .assistant)
        #expect(mock.messages[2].role == .user)
        #expect(mock.messages[2].content == "Second question")
        #expect(mock.messages[4].role == .user)
        #expect(mock.messages[4].content == "Third question")
    }

    @Test("`reset` after multiple turns wipes the entire history, not just the latest pair")
    func resetAfterMultipleTurnsClearsEverything() async {
        let mock = MockBonjourChatSession()
        await mock.send("Q1", context: emptyContext)
        await mock.send("Q2", context: emptyContext)
        #expect(mock.messages.count == 4)

        mock.reset()
        #expect(mock.messages.isEmpty)
    }

    // MARK: - Local Rejection
    //
    // Pinning the contract added to `BonjourChatSessionProtocol` for the
    // client-side refusal path: when `ChatInputValidator` rejects input,
    // the chat view calls `appendLocalRejection` to render the exchange
    // as a normal turn instead of silently dropping the tap. These tests
    // make sure mock sessions (used by previews + unit tests) cover the
    // same behavior real sessions do.

    @Test("`appendLocalRejection` renders the rejected exchange as a normal user/assistant pair")
    func appendLocalRejectionAddsUserAndAssistantMessages() {
        let mock = MockBonjourChatSession()
        mock.appendLocalRejection(
            userMessage: "Write me a poem",
            refusalText: "That's outside what I can help with."
        )

        #expect(mock.messages.count == 2)
        #expect(mock.messages[0].role == .user)
        #expect(mock.messages[0].content == "Write me a poem")
        #expect(mock.messages[1].role == .assistant)
        #expect(mock.messages[1].content == "That's outside what I can help with.")
    }

    @Test("Local-rejection counter is independent from `sendCallCount` so the two paths stay auditable")
    func appendLocalRejectionIncrementsDedicatedCounter() {
        // Tests asserting "was the rejection path taken" shouldn't rely
        // on `sendCallCount` (which is for the model-hitting path). A
        // separate counter keeps the two paths independently auditable.
        let mock = MockBonjourChatSession()
        mock.appendLocalRejection(userMessage: "x", refusalText: "y")
        mock.appendLocalRejection(userMessage: "x", refusalText: "y")

        #expect(mock.appendLocalRejectionCallCount == 2)
        #expect(mock.sendCallCount == 0, "rejection must not touch the send counter")
    }

    @Test("Local-rejection path leaves `isGenerating` false so the send button stays enabled")
    func appendLocalRejectionDoesNotToggleIsGenerating() {
        // The client-side refusal path is synchronous — there's no
        // streaming response, so `isGenerating` must stay false.
        // Otherwise the send button's `sendDisabled` check would lock
        // the user out.
        let mock = MockBonjourChatSession()
        mock.appendLocalRejection(userMessage: "x", refusalText: "y")
        #expect(!mock.isGenerating)
    }

    @Test("Interleaving a rejection then a real `send` yields four messages in chronological order")
    func rejectionAndRealSendInterleaveCleanly() async {
        // A realistic session: user gets rejected, then sends something
        // valid. The message history should contain both exchanges in
        // order, without send/reject paths corrupting each other's state.
        let mock = MockBonjourChatSession(cannedReply: "Fine answer")
        mock.appendLocalRejection(
            userMessage: "calculate 2+2",
            refusalText: "Off topic"
        )
        await mock.send("What is AirPlay?", context: emptyContext)

        #expect(mock.messages.count == 4)
        #expect(mock.messages[0].content == "calculate 2+2")
        #expect(mock.messages[1].content == "Off topic")
        #expect(mock.messages[2].content == "What is AirPlay?")
        #expect(mock.messages[3].content == "Fine answer")
    }

    // MARK: - Restore (Persisted-History Replay)

    @Test("`restore` replaces messages with the supplied list and bumps `restoreCallCount`")
    func restoreReplacesMessages() {
        let mock = MockBonjourChatSession()
        let restored: [BonjourChatMessage] = [
            BonjourChatMessage(role: .user, content: "previous question"),
            BonjourChatMessage(role: .assistant, content: "previous answer")
        ]
        mock.restore(messages: restored)
        #expect(mock.messages == restored)
        #expect(mock.restoreCallCount == 1)
    }

    @Test("`restore` overwrites any existing in-flight messages — the supplied list wins")
    func restoreOverwritesExistingMessages() async {
        // Real flow: a session that already has live messages
        // shouldn't receive a `restore` call (the chat view guards
        // on `session.messages.isEmpty`), but if it did the
        // semantics should be deterministic — replace, don't merge.
        let mock = MockBonjourChatSession()
        await mock.send("live question", context: emptyContext)
        #expect(mock.messages.count == 2)

        let restored = [BonjourChatMessage(role: .user, content: "from disk")]
        mock.restore(messages: restored)
        #expect(mock.messages == restored)
    }

    @Test("`restore` with an empty array clears any prior messages cleanly")
    func restoreWithEmptyArrayClearsMessages() async {
        let mock = MockBonjourChatSession()
        await mock.send("anything", context: emptyContext)
        mock.restore(messages: [])
        #expect(mock.messages.isEmpty)
    }

    @Test("`restore` clears any pending error and the `isGenerating` flag")
    func restoreClearsErrorAndGenerating() {
        let mock = MockBonjourChatSession()
        mock.error = "previous failure"
        mock.restore(messages: [BonjourChatMessage(role: .user, content: "ok")])
        #expect(mock.error == nil)
        #expect(!mock.isGenerating)
    }
}
