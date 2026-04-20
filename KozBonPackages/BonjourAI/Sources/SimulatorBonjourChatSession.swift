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

    public init() {}

    // MARK: - BonjourChatSessionProtocol

    public func send(_ text: String, context: BonjourChatPromptBuilder.ChatContext) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        error = nil
        isGenerating = true

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

        isGenerating = false
    }

    public func reset() {
        messages.removeAll()
        error = nil
        isGenerating = false
    }
}

#endif
