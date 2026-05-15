//
//  GitHubMessageRequest.swift
//  BonjourAIGitHub
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourAICore

// MARK: - GitHubMessageRequest

/// The shape of a single call to GitHub Models'
/// `POST /chat/completions` endpoint.
///
/// OpenAI-compatible: the system prompt is the first `role: system`
/// message in ``messages`` (not a separate top-level field like
/// Anthropic), there is no prompt-caching marker, and every
/// request re-sends the full conversation history.
///
/// Held as a value type so a request can be constructed, inspected
/// by tests, and sent without the client owning any extra state.
public struct GitHubMessageRequest: Sendable, Equatable, Encodable {

    // MARK: - Properties

    /// The model identifier (`gpt-4o`).
    public let model: String

    /// Conversation messages — leading `system` entry followed by
    /// `user` / `assistant` turns in chronological order.
    public let messages: [GitHubMessage]

    /// Whether to request a streaming response. Always `true` for
    /// production use — the chat surface and the explainer both
    /// render tokens as they arrive. Kept as a stored property
    /// (rather than a hard-coded constant) so tests can construct
    /// non-streaming requests when verifying the encoder.
    public let stream: Bool

    /// Maximum tokens the assistant is allowed to emit.
    public let maxTokens: Int

    /// Optional sampling temperature. Left `nil` to inherit
    /// OpenAI's per-model default (typically 1.0).
    public let temperature: Double?

    // MARK: - Init

    public init(
        model: String,
        messages: [GitHubMessage],
        stream: Bool = true,
        maxTokens: Int,
        temperature: Double? = nil
    ) {
        self.model = model
        self.messages = messages
        self.stream = stream
        self.maxTokens = maxTokens
        self.temperature = temperature
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case stream
        case maxTokens = "max_tokens"
        case temperature
    }
}

// MARK: - GitHubMessage

/// A single message in a GitHub Models request.
///
/// Carries `role` + `content` — no nested content blocks (unlike
/// Anthropic's `system: [block]` shape). System prompts ride here
/// as the leading element with `role == .system`.
public struct GitHubMessage: Sendable, Equatable, Encodable {

    public let role: GitHubMessageRole
    public let content: String

    public init(role: GitHubMessageRole, content: String) {
        self.role = role
        self.content = content
    }
}

// MARK: - GitHubMessageRole

/// Role of a single ``GitHubMessage``. OpenAI-compatible —
/// `system` is a first-class role (unlike Anthropic where it's a
/// top-level field on the request).
public enum GitHubMessageRole: String, Sendable, Equatable, Codable {
    case system
    case user
    case assistant
}
