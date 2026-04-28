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
        // Creative-writing requests — the model should redirect
        // to networking topics rather than spending tokens
        // refusing.
        "write me a",
        "write a poem",
        "write a story",
        "write a song",
        "generate a poem",
        "generate a story",
        "tell me a joke",
        "tell me a story",
        "tell me a fun fact",

        // Code-generation requests — the chat is for explaining
        // services, not as a generic coding assistant.
        "write a function",
        "write a script",
        "implement a",
        "in python",
        "in javascript",
        "in typescript",
        "in swift",
        "in rust",
        "in java",
        "in c++",
        "in go",
        "code example for",
        "show me code",

        // Weather / news / general knowledge — common test
        // queries for any chat assistant.
        "what's the weather",
        "what is the weather",
        "weather in",
        "the weather like",
        "who won",
        "who is the president",
        "who is the prime minister",
        "latest news",
        "what's in the news",
        "what is the capital of",
        "how tall is",
        "when was ",

        // Math / logic puzzles.
        "solve this equation",
        "solve the following",
        "calculate ",
        "what is the meaning of life",

        // Personal advice — out of scope.
        "should i ",
        "help me decide",
        "what do you think about",

        // Translation requests — model is locale-pinned via
        // system prompt; users shouldn't be using this surface
        // as a translator.
        "translate this",
        "translate the following",
        "in french",
        "in spanish",
        "in german",
        "in chinese",
        "in japanese",

        // Recommendation requests.
        "recommend a movie",
        "recommend a book",
        "recommend a recipe",
        "recipe for",

        // Pasted-conversation patterns — almost always the user
        // dumping a transcript from another chat to try to
        // override the assistant's role.
        "user:\n",
        "user: ",
        "assistant:\n",
        "assistant: ",
        "human:\n",
        "human: ",
        "ai:\n",
        "ai: "
    ]

    // MARK: - Validate

    /// Validates the given chat input text.
    ///
    /// Pattern matching runs against a Unicode-normalized
    /// lowercased copy so an attacker can't bypass rejection by
    /// sprinkling zero-width spaces or Unicode-tag-block characters
    /// between the letters of a pattern (`i\u{200B}gnore previous
    /// instructions`). The user keeps their original text in the
    /// chat history regardless of normalization — only the
    /// in-flight pattern check operates on the cleaned form.
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

        // Normalize Unicode before pattern matching so invisible
        // payloads (tag block, zero-width space, BIDI overrides,
        // C0/C1 controls) can't sneak past substring checks.
        let normalized = PromptInjectionSanitizer.normalizeUnicode(trimmed)
        let lowered = normalized.lowercased()

        for pattern in promptInjectionPatterns where lowered.contains(pattern) {
            return .rejected(.promptInjection)
        }

        for pattern in offTopicPatterns where lowered.contains(pattern) {
            return .rejected(.offTopic)
        }

        return .allowed
    }
}
