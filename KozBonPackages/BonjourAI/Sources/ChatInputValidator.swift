//
//  ChatInputValidator.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - ChatInputValidator

/// Validates user input before it's sent to the on-device chat model.
///
/// Provides a client-side pre-filter for obvious prompt-injection attempts,
/// sensitive-data extraction requests, and off-topic queries that the user
/// doesn't need to wait for the model to process.
///
/// This is **defense in depth** — the system prompt already instructs the
/// model to refuse off-topic queries, but client-side validation catches
/// common issues faster and without model latency.
public enum ChatInputValidator {

    // MARK: - Result

    /// The result of validating user input.
    public enum Result: Sendable, Equatable {

        /// The input passed all checks and can be sent to the model.
        case allowed

        /// The input was rejected for the given reason.
        case rejected(Reason)
    }

    /// Why a chat input was rejected.
    public enum Reason: Sendable, Equatable {

        /// The input was empty or whitespace-only.
        case empty

        /// The input exceeded the maximum allowed length.
        case tooLong(limit: Int)

        /// The input contains a prompt-injection attempt
        /// (e.g., "ignore previous instructions", "system prompt", etc.).
        case promptInjection

        /// The input appears to request sensitive/off-topic information.
        case offTopic
    }

    // MARK: - Limits

    /// The maximum number of characters allowed in a single chat message.
    public static let maxCharacterCount = 2000

    // MARK: - Patterns

    /// Phrases commonly used in prompt-injection attempts.
    ///
    /// Matches are case-insensitive. When any phrase is detected in the
    /// input, the message is rejected before reaching the model.
    private static let promptInjectionPatterns: [String] = [
        "ignore previous instructions",
        "ignore prior instructions",
        "ignore the above",
        "ignore all prior",
        "disregard previous",
        "disregard prior",
        "disregard the above",
        "forget your instructions",
        "forget the instructions",
        "forget everything above",
        "you are now",
        "pretend you are",
        "act as if you are",
        "roleplay as",
        "new instructions:",
        "new system prompt",
        "system prompt:",
        "developer mode",
        "jailbreak",
        "reveal your prompt",
        "show me your prompt",
        "print your instructions",
        "repeat your instructions",
        "what are your instructions"
    ]

    /// Phrases that indicate clearly off-topic requests.
    ///
    /// These are obvious off-topic requests that don't need model latency
    /// to refuse. The system prompt also instructs the model to refuse
    /// off-topic queries, but catching them client-side saves time.
    private static let offTopicPatterns: [String] = [
        "write me a",
        "write a poem",
        "write a story",
        "write a song",
        "generate a poem",
        "generate a story",
        "tell me a joke",
        "what's the weather",
        "what is the weather",
        "weather in",
        "who won",
        "who is the president",
        "solve this equation",
        "solve the following",
        "calculate ",
        "what is the meaning of life",
        "recommend a movie",
        "recommend a book",
        "recommend a recipe",
        "recipe for"
    ]

    // MARK: - Validate

    /// Validates the given chat input text.
    ///
    /// - Parameter text: The raw user input.
    /// - Returns: Whether the input should be allowed, or a specific rejection reason.
    public static func validate(_ text: String) -> Result {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return .rejected(.empty)
        }

        if trimmed.count > maxCharacterCount {
            return .rejected(.tooLong(limit: maxCharacterCount))
        }

        let lowered = trimmed.lowercased()

        for pattern in promptInjectionPatterns where lowered.contains(pattern) {
            return .rejected(.promptInjection)
        }

        for pattern in offTopicPatterns where lowered.contains(pattern) {
            return .rejected(.offTopic)
        }

        return .allowed
    }
}
