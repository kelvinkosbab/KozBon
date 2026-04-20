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
/// refuses off-topic queries. Supports **multi-turn conversation** by keeping a
/// single `LanguageModelSession` alive across messages so the model remembers
/// prior turns.
///
/// The system prompt contains only the static rules (scope, refusal, language,
/// tone, length). Live service context is injected into each user turn via a
/// `<context>` preamble when it has materially changed, so follow-up questions
/// always have an up-to-date view of the network without losing conversation
/// history.
@available(iOS 26, macOS 26, visionOS 26, *)
@MainActor
@Observable
public final class BonjourChatSession: BonjourChatSessionProtocol {

    // MARK: - Properties

    public private(set) var messages: [BonjourChatMessage] = []
    public private(set) var isGenerating: Bool = false
    public var error: String?
    public var responseLength: BonjourServicePromptBuilder.ResponseLength = .standard

    /// The current session. Created lazily on first send and kept alive across turns
    /// so conversation history is preserved.
    private var session: LanguageModelSession?

    /// The response length used when the current session was created. If it changes,
    /// the session is recreated (history is lost).
    private var sessionResponseLengthSnapshot: BonjourServicePromptBuilder.ResponseLength?

    /// The last context block sent to the model. Used to detect when the live
    /// service context has materially changed.
    private var lastContextBlock: String?

    public init() {}

    // MARK: - Send

    public func send(_ text: String, context: BonjourChatPromptBuilder.ChatContext) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        error = nil
        isGenerating = true

        // Append the user message as it appears to the user (without the context
        // preamble — the preamble is internal guidance for the model).
        messages.append(BonjourChatMessage(role: .user, content: trimmed))

        // Build or reuse the session. Only recreate when the response-length
        // preference changes (since it affects the static instructions).
        // Changes to the live context do NOT recreate the session — that
        // would destroy conversation history.
        if session == nil || sessionResponseLengthSnapshot != responseLength {
            let instructions = BonjourChatPromptBuilder.systemInstructions(
                responseLength: responseLength
            )
            session = LanguageModelSession(instructions: instructions)
            sessionResponseLengthSnapshot = responseLength
            // Fresh session — treat the next turn as the first turn so context
            // is injected.
            lastContextBlock = nil
        }

        // Determine whether to prepend a context preamble.
        let currentContextBlock = BonjourChatPromptBuilder.contextBlock(context: context)
        let isFirstTurn = (lastContextBlock == nil)
        let contextChanged = lastContextBlock != currentContextBlock
        let turnToSend = BonjourChatPromptBuilder.userTurn(
            message: trimmed,
            context: context,
            isFirstTurn: isFirstTurn,
            contextChanged: contextChanged
        )
        lastContextBlock = currentContextBlock

        // Create a placeholder assistant message that we stream into.
        let assistantId = UUID()
        messages.append(BonjourChatMessage(id: assistantId, role: .assistant, content: ""))

        guard let session = session else {
            isGenerating = false
            return
        }

        do {
            let stream = session.streamResponse(to: turnToSend)
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
        sessionResponseLengthSnapshot = nil
        lastContextBlock = nil
        error = nil
        isGenerating = false
    }
}

#endif
