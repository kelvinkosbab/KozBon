//
//  MockBonjourChatSession.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - MockBonjourChatSession

/// A mock implementation of ``BonjourChatSessionProtocol`` for testing and previews.
@MainActor
@Observable
public final class MockBonjourChatSession: BonjourChatSessionProtocol {

    // MARK: - Properties

    public private(set) var messages: [BonjourChatMessage] = []
    public private(set) var isGenerating: Bool = false
    public var error: String?
    public var responseLength: BonjourServicePromptBuilder.ResponseLength = .standard

    /// Broker exposed for protocol conformance. The mock never
    /// emits intents through it, but tests can call
    /// ``BonjourChatIntentBroker/publish(_:)`` directly to drive
    /// view-side intent handling under test.
    public let intentBroker: BonjourChatIntentBroker

    /// The canned reply returned by ``send(_:context:)``.
    public var cannedReply: String

    /// The number of times ``send(_:context:)`` has been called.
    public var sendCallCount = 0

    /// The number of times ``appendUserMessage(_:)`` has been called.
    /// Tests can assert on this to verify the chat view appends the
    /// user bubble synchronously before awaiting fresh-scan + send.
    public var appendUserMessageCallCount = 0

    /// The number of times ``reset()`` has been called.
    public var resetCallCount = 0

    /// The number of times ``restore(messages:)`` has been called.
    /// Tests can assert on this to verify the chat-history-restoration
    /// path runs when persistence is on.
    public var restoreCallCount = 0

    /// The number of times ``appendLocalRejection(userMessage:refusalText:)``
    /// has been called. Tests can assert on this to verify client-side
    /// rejection paths are taken.
    public var appendLocalRejectionCallCount = 0

    /// The most recent context passed to ``send(_:context:)``.
    public var lastContext: BonjourChatPromptBuilder.ChatContext?

    public init(
        cannedReply: String = "This is a mock chat response.",
        intentBroker: BonjourChatIntentBroker = BonjourChatIntentBroker()
    ) {
        self.cannedReply = cannedReply
        self.intentBroker = intentBroker
    }

    // MARK: - BonjourChatSessionProtocol

    public func appendUserMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        appendUserMessageCallCount += 1
        messages.append(BonjourChatMessage(role: .user, content: trimmed))
    }

    public func send(_ text: String, context: BonjourChatPromptBuilder.ChatContext) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        sendCallCount += 1
        lastContext = context
        error = nil
        isGenerating = true

        // User message already appended via `appendUserMessage(_:)`.
        // The assistant bubble is appended here so tests that
        // exercise `send` directly without first calling
        // `appendUserMessage` see only an assistant message —
        // which is the same pattern the production session
        // follows.
        messages.append(BonjourChatMessage(role: .assistant, content: cannedReply))

        isGenerating = false
    }

    public func appendLocalRejection(userMessage: String, refusalText: String) {
        appendLocalRejectionCallCount += 1
        messages.append(BonjourChatMessage(role: .user, content: userMessage))
        messages.append(BonjourChatMessage(role: .assistant, content: refusalText))
    }

    public func reset() {
        resetCallCount += 1
        messages.removeAll()
        error = nil
        isGenerating = false
    }

    public func restore(messages: [BonjourChatMessage]) {
        restoreCallCount += 1
        self.messages = messages
        error = nil
        isGenerating = false
    }
}
