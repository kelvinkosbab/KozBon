//
//  BonjourChatSession.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels

// MARK: - BonjourChatSession

/// On-device chat session for asking questions about the user's network and the KozBon app.
///
/// Uses Apple's FoundationModels framework with a strict system prompt that
/// refuses off-topic queries. Supports multi-turn conversation by keeping a
/// `LanguageModelSession` alive across messages.
@available(iOS 26, macOS 26, visionOS 26, *)
@MainActor
@Observable
public final class BonjourChatSession: BonjourChatSessionProtocol {

    // MARK: - Properties

    public private(set) var messages: [BonjourChatMessage] = []
    public private(set) var isGenerating: Bool = false
    public var error: String?

    /// The current session. Created lazily on first send.
    private var session: LanguageModelSession?

    /// The context used to create the current session. If this changes, we start a fresh session.
    private var sessionContextSnapshot: String?

    public init() {}

    // MARK: - Send

    public func send(_ text: String, context: BonjourChatPromptBuilder.ChatContext) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        error = nil
        isGenerating = true

        // Append the user message.
        messages.append(BonjourChatMessage(role: .user, content: trimmed))

        // Build or reuse the session. If context changed significantly (e.g. new services
        // discovered), create a fresh session with updated system instructions.
        let instructions = BonjourChatPromptBuilder.systemInstructions(context: context)
        if session == nil || sessionContextSnapshot != instructions {
            session = LanguageModelSession(instructions: instructions)
            sessionContextSnapshot = instructions
        }

        // Create a placeholder assistant message that we stream into.
        let assistantId = UUID()
        messages.append(BonjourChatMessage(id: assistantId, role: .assistant, content: ""))

        guard let session = session else {
            isGenerating = false
            return
        }

        do {
            let stream = session.streamResponse(to: trimmed)
            for try await partial in stream {
                if let index = messages.firstIndex(where: { $0.id == assistantId }) {
                    messages[index].content = partial.content
                }
            }
        } catch {
            self.error = error.localizedDescription
            // Remove the empty assistant placeholder on error.
            messages.removeAll { $0.id == assistantId }
        }

        isGenerating = false
    }

    // MARK: - Reset

    public func reset() {
        messages.removeAll()
        session = nil
        sessionContextSnapshot = nil
        error = nil
        isGenerating = false
    }
}

#endif
