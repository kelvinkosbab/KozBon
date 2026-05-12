//
//  AnthropicMessageRequest.swift
//  BonjourAICloud
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - AnthropicMessageRequest

/// The shape of a single call to Anthropic's `POST /v1/messages`
/// endpoint.
///
/// Bundles the model identifier, the cached system instructions
/// block, and the user / assistant turn history. The encoder
/// produces snake-case keys so the resulting JSON matches the
/// API's spelling without manual key massaging at the call site.
///
/// Held as a value type so a request can be constructed,
/// inspected by tests, and sent without the client owning any
/// extra state. The component types (``AnthropicSystemBlock``,
/// ``AnthropicMessage``, ``AnthropicMessageRole``) are flat
/// rather than nested to satisfy the project's type-nesting
/// budget — the prefix is enough to namespace them, and external
/// callers (`AnthropicBonjourChatSession`, future
/// `AnthropicBonjourServiceExplainer`) need to construct each
/// piece individually anyway.
public struct AnthropicMessageRequest: Sendable, Equatable, Encodable {

    // MARK: - Properties

    /// The model identifier (Anthropic's canonical name, e.g.
    /// `claude-sonnet-4-5`). Stored as a string here rather than
    /// `AnthropicModel` so requests can carry retired identifiers
    /// for replay-style debugging.
    public let model: String

    /// Maximum tokens the assistant is allowed to emit.
    public let maxTokens: Int

    /// Whether to request a streaming response. Always `true` for
    /// production use — the chat surface and the explainer both
    /// render tokens as they arrive. Kept as a stored property
    /// (rather than a hard-coded constant) so tests can construct
    /// non-streaming requests when verifying the encoder.
    public let stream: Bool

    /// The system instructions block, expressed as an array of
    /// content blocks so the last block can carry an
    /// ``AnthropicCacheControl`` marker. Anthropic's prompt cache
    /// reuses the cached prefix across requests with the same
    /// system block, dramatically reducing first-token latency on
    /// repeated sessions.
    public let system: [AnthropicSystemBlock]

    /// The user / assistant turn history. The final element is
    /// always the user's latest message — Anthropic's API expects
    /// the assistant to be the next-token producer.
    public let messages: [AnthropicMessage]

    /// Optional sampling temperature. Left `nil` to inherit
    /// Anthropic's per-model default (typically 1.0).
    public let temperature: Double?

    // MARK: - Init

    public init(
        model: String,
        maxTokens: Int,
        stream: Bool = true,
        system: [AnthropicSystemBlock],
        messages: [AnthropicMessage],
        temperature: Double? = nil
    ) {
        self.model = model
        self.maxTokens = maxTokens
        self.stream = stream
        self.system = system
        self.messages = messages
        self.temperature = temperature
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case stream
        case system
        case messages
        case temperature
    }
}

// MARK: - AnthropicSystemBlock

/// A single content block inside the `system` array of an
/// ``AnthropicMessageRequest``.
///
/// Anthropic accepts the system instructions either as a plain
/// string or as an array of content blocks. The array form is
/// required to attach `cache_control` to the block, which is why
/// this type always renders as a one-element array even when the
/// call site has a single string.
public struct AnthropicSystemBlock: Sendable, Equatable, Encodable {

    public let type: String
    public let text: String
    public let cacheControl: AnthropicCacheControl?

    public init(text: String, cacheControl: AnthropicCacheControl? = nil) {
        self.type = "text"
        self.text = text
        self.cacheControl = cacheControl
    }

    enum CodingKeys: String, CodingKey {
        case type
        case text
        case cacheControl = "cache_control"
    }
}

// MARK: - AnthropicCacheControl

/// Marker that tells Anthropic to cache everything up to and
/// including the carrying content block.
///
/// The cache TTL is short (a few minutes) but covers the hot
/// path: a user who fires several chat turns within the same
/// session reuses the cached system block on every call, paying
/// full encoding cost only on the first turn.
public struct AnthropicCacheControl: Sendable, Equatable, Encodable {

    public let type: String

    public init(type: String = "ephemeral") {
        self.type = type
    }

    /// The default cache-control marker — Anthropic's only
    /// supported value as of `anthropic-version: 2023-06-01`.
    public static let ephemeral = AnthropicCacheControl()
}

// MARK: - AnthropicMessage

/// A single user or assistant turn in the conversation history
/// sent to Anthropic.
public struct AnthropicMessage: Sendable, Equatable, Encodable {

    public let role: AnthropicMessageRole
    public let content: String

    public init(role: AnthropicMessageRole, content: String) {
        self.role = role
        self.content = content
    }
}

// MARK: - AnthropicMessageRole

/// Role of a single ``AnthropicMessage``.
public enum AnthropicMessageRole: String, Sendable, Equatable, Codable {
    case user
    case assistant
}
