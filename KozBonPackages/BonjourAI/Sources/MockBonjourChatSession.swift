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

    /// The canned reply returned by ``send(_:context:)``.
    public var cannedReply: String

    /// The number of times ``send(_:context:)`` has been called.
    public var sendCallCount = 0

    /// The number of times ``reset()`` has been called.
    public var resetCallCount = 0

    /// The most recent context passed to ``send(_:context:)``.
    public var lastContext: BonjourChatPromptBuilder.ChatContext?

    public init(cannedReply: String = "This is a mock chat response.") {
        self.cannedReply = cannedReply
    }

    // MARK: - BonjourChatSessionProtocol

    public func send(_ text: String, context: BonjourChatPromptBuilder.ChatContext) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        sendCallCount += 1
        lastContext = context
        error = nil
        isGenerating = true

        messages.append(BonjourChatMessage(role: .user, content: trimmed))
        messages.append(BonjourChatMessage(role: .assistant, content: cannedReply))

        isGenerating = false
    }

    public func reset() {
        resetCallCount += 1
        messages.removeAll()
        error = nil
        isGenerating = false
    }
}
