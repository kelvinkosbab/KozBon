//
//  SimulatorBonjourChatSession.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

#if targetEnvironment(simulator)

import Foundation

// MARK: - SimulatorBonjourChatSession

/// A simulator-only chat session that streams random lorem ipsum responses.
///
/// Used on the iOS simulator where `FoundationModels` can be imported but the
/// on-device language model isn't actually available. Lets developers test the
/// chat UI end-to-end on their Mac without a real AI device.
@MainActor
@Observable
public final class SimulatorBonjourChatSession: BonjourChatSessionProtocol {

    // MARK: - Properties

    public private(set) var messages: [BonjourChatMessage] = []
    public private(set) var isGenerating: Bool = false
    public var error: String?
    public var responseLength: BonjourServicePromptBuilder.ResponseLength = .standard

    /// Broker exposed for protocol conformance. The simulator stub
    /// never emits intents — tool calls aren't simulated. Holding
    /// a real broker means previews and dev builds still observe
    /// the same `pendingIntent`-watching `.onChange` plumbing as
    /// production, so a regression in that wiring shows up in
    /// development before it ships.
    public let intentBroker: BonjourChatIntentBroker

    public init(intentBroker: BonjourChatIntentBroker = BonjourChatIntentBroker()) {
        self.intentBroker = intentBroker
    }

    // MARK: - BonjourChatSessionProtocol

    public func send(_ text: String, context: BonjourChatPromptBuilder.ChatContext) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        error = nil
        isGenerating = true
        // `defer` guarantees the flag flips back on every exit path —
        // including task cancellation mid-stream. If `isGenerating`
        // gets stuck at true, the send button stays disabled and the
        // user can't fire a follow-up.
        defer { isGenerating = false }

        messages.append(BonjourChatMessage(role: .user, content: trimmed))

        let assistantId = UUID()
        messages.append(BonjourChatMessage(id: assistantId, role: .assistant, content: ""))

        // Stream a random lorem ipsum response word by word to mimic the real streaming UX.
        let fullResponse = SimulatorLoremIpsum.randomMarkdownResponse()
        var accumulated = ""

        for word in fullResponse.split(separator: " ", omittingEmptySubsequences: false) {
            if Task.isCancelled { break }
            if !accumulated.isEmpty {
                accumulated += " "
            }
            accumulated += word
            if let index = messages.firstIndex(where: { $0.id == assistantId }) {
                messages[index].content = accumulated
            }
            try? await Task.sleep(nanoseconds: 25_000_000) // 25ms per word
        }
    }

    public func appendLocalRejection(userMessage: String, refusalText: String) {
        messages.append(BonjourChatMessage(role: .user, content: userMessage))
        messages.append(BonjourChatMessage(role: .assistant, content: refusalText))
    }

    public func reset() {
        messages.removeAll()
        error = nil
        isGenerating = false
    }

    public func restore(messages: [BonjourChatMessage]) {
        // Same semantics as the production session: replace the
        // visible history wholesale, clear any in-flight error/
        // generating state. The simulator stub doesn't have a
        // language-model transcript to invalidate — there's nothing
        // beyond the messages array to manage.
        self.messages = messages
        error = nil
        isGenerating = false
    }
}

#endif
