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

    @Test func initialStateIsEmpty() {
        let mock = MockBonjourChatSession()
        #expect(mock.messages.isEmpty)
        #expect(!mock.isGenerating)
        #expect(mock.error == nil)
        #expect(mock.sendCallCount == 0)
        #expect(mock.resetCallCount == 0)
    }

    // MARK: - Send

    @Test func sendAppendsUserAndAssistantMessages() async {
        let mock = MockBonjourChatSession(cannedReply: "Test reply")
        await mock.send("Hello", context: emptyContext)
        #expect(mock.messages.count == 2)
        #expect(mock.messages[0].role == .user)
        #expect(mock.messages[0].content == "Hello")
        #expect(mock.messages[1].role == .assistant)
        #expect(mock.messages[1].content == "Test reply")
    }

    @Test func sendIncrementsCallCount() async {
        let mock = MockBonjourChatSession()
        await mock.send("One", context: emptyContext)
        await mock.send("Two", context: emptyContext)
        #expect(mock.sendCallCount == 2)
    }

    @Test func sendIgnoresEmptyInput() async {
        let mock = MockBonjourChatSession()
        await mock.send("", context: emptyContext)
        #expect(mock.sendCallCount == 0)
        #expect(mock.messages.isEmpty)
    }

    @Test func sendIgnoresWhitespaceOnlyInput() async {
        let mock = MockBonjourChatSession()
        await mock.send("   \n\t  ", context: emptyContext)
        #expect(mock.sendCallCount == 0)
    }

    @Test func sendTrimsWhitespace() async {
        let mock = MockBonjourChatSession()
        await mock.send("  hello  ", context: emptyContext)
        #expect(mock.messages[0].content == "hello")
    }

    @Test func sendStoresLastContext() async {
        let mock = MockBonjourChatSession()
        let context = BonjourChatPromptBuilder.ChatContext()
        await mock.send("Hi", context: context)
        #expect(mock.lastContext != nil)
    }

    // MARK: - Reset

    @Test func resetClearsMessages() async {
        let mock = MockBonjourChatSession()
        await mock.send("Hello", context: emptyContext)
        #expect(!mock.messages.isEmpty)

        mock.reset()
        #expect(mock.messages.isEmpty)
        #expect(mock.resetCallCount == 1)
    }

    @Test func resetClearsErrorAndGeneratingFlags() {
        let mock = MockBonjourChatSession()
        mock.error = "Something failed"
        mock.reset()
        #expect(mock.error == nil)
        #expect(!mock.isGenerating)
    }

    // MARK: - Canned Reply

    @Test func cannedReplyCanBeCustomized() async {
        let mock = MockBonjourChatSession(cannedReply: "Custom reply")
        await mock.send("Hi", context: emptyContext)
        #expect(mock.messages.last?.content == "Custom reply")
    }

    // MARK: - Multi-turn History

    @Test func multipleTurnsAllAppearInHistory() async {
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

    @Test func resetAfterMultipleTurnsClearsEverything() async {
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

    @Test func appendLocalRejectionAddsUserAndAssistantMessages() {
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

    @Test func appendLocalRejectionIncrementsDedicatedCounter() {
        // Tests asserting "was the rejection path taken" shouldn't rely
        // on `sendCallCount` (which is for the model-hitting path). A
        // separate counter keeps the two paths independently auditable.
        let mock = MockBonjourChatSession()
        mock.appendLocalRejection(userMessage: "x", refusalText: "y")
        mock.appendLocalRejection(userMessage: "x", refusalText: "y")

        #expect(mock.appendLocalRejectionCallCount == 2)
        #expect(mock.sendCallCount == 0, "rejection must not touch the send counter")
    }

    @Test func appendLocalRejectionDoesNotToggleIsGenerating() {
        // The client-side refusal path is synchronous — there's no
        // streaming response, so `isGenerating` must stay false.
        // Otherwise the send button's `sendDisabled` check would lock
        // the user out.
        let mock = MockBonjourChatSession()
        mock.appendLocalRejection(userMessage: "x", refusalText: "y")
        #expect(!mock.isGenerating)
    }

    @Test func rejectionAndRealSendInterleaveCleanly() async {
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
}
