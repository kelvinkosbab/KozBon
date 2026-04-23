//
//  BonjourChatSessionProtocol.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - BonjourChatSessionProtocol

/// Protocol for an on-device chat session about Bonjour services and the app.
///
/// Provides an abstraction over `LanguageModelSession` so views can be
/// tested and previewed without requiring FoundationModels.
@MainActor
public protocol BonjourChatSessionProtocol: AnyObject, Observable {

    /// All messages in the current conversation, in chronological order.
    var messages: [BonjourChatMessage] { get }

    /// Whether the assistant is currently generating a response.
    var isGenerating: Bool { get }

    /// An error message if the last send failed.
    var error: String? { get set }

    /// The desired verbosity of assistant responses.
    var responseLength: BonjourServicePromptBuilder.ResponseLength { get set }

    /// Sends a user message and streams the assistant's response.
    ///
    /// - Parameters:
    ///   - text: The user's message text (trimmed, non-empty).
    ///   - context: A snapshot of the user's current services and library.
    func send(_ text: String, context: BonjourChatPromptBuilder.ChatContext) async

    /// Appends a user message and an immediate assistant refusal to the
    /// conversation **without hitting the model**. Used when client-side
    /// validation (`ChatInputValidator`) rejects an input.
    ///
    /// Rendering the exchange as real chat turns — rather than silently
    /// dropping the input — keeps the Chat surface coherent: every user
    /// tap produces a visible outcome. Previously, on an empty chat, a
    /// client-rejected send would fall through to `session.error` which
    /// is only rendered once at least one real message exists, so the
    /// user saw nothing happen and reported the send button as broken.
    ///
    /// - Parameters:
    ///   - userMessage: The trimmed user text the validator rejected.
    ///   - refusalText: The localized refusal reason to display as the
    ///     assistant's reply.
    func appendLocalRejection(userMessage: String, refusalText: String)

    /// Clears the conversation history and starts a new session.
    func reset()
}
