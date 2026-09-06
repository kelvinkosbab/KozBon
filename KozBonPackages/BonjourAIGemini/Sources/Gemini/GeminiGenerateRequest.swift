//
//  GeminiGenerateRequest.swift
//  BonjourAIGemini
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourAICore

// MARK: - GeminiGenerateRequest

/// The body of a call to Gemini's
/// `:streamGenerateContent` endpoint.
///
/// Unlike Anthropic's `/v1/messages`, the model identifier travels
/// in the URL path rather than the body. It's still carried here —
/// a session picks its model at runtime, long after the client was
/// constructed — but excluded from ``CodingKeys`` so it never
/// reaches the JSON body, which the API would reject.
///
/// Component types are flat rather than nested, matching
/// ``AnthropicMessageRequest``: the prefix namespaces them well
/// enough, and callers construct each piece individually.
public struct GeminiGenerateRequest: Sendable, Equatable, Encodable {

    // MARK: - Properties

    /// The model to send to (e.g. `gemini-2.5-flash`), which
    /// ``GeminiClient`` splices into the request path. Not encoded
    /// — see the type's note.
    public let model: String

    /// The user / model turn history. The final element is always
    /// the user's latest message.
    public let contents: [GeminiContent]

    /// System instructions. Gemini takes these as a separate
    /// top-level field rather than a pseudo-turn in `contents`.
    ///
    /// Optional because the API rejects an empty `parts` array —
    /// a session with no instructions must omit the field
    /// entirely rather than send a blank one.
    public let systemInstruction: GeminiContent?

    /// Output limits and sampling knobs.
    public let generationConfig: GeminiGenerationConfig

    // MARK: - Init

    public init(
        model: String,
        contents: [GeminiContent],
        systemInstruction: GeminiContent? = nil,
        generationConfig: GeminiGenerationConfig
    ) {
        self.model = model
        self.contents = contents
        self.systemInstruction = systemInstruction
        self.generationConfig = generationConfig
    }

    // MARK: - Coding Keys

    /// `model` is deliberately absent — it addresses the endpoint
    /// rather than describing the generation.
    enum CodingKeys: String, CodingKey {
        case contents
        case systemInstruction
        case generationConfig
    }
}

// MARK: - GeminiContent

/// One turn — or the system-instruction block — in a
/// ``GeminiGenerateRequest``.
public struct GeminiContent: Sendable, Equatable, Encodable {

    /// Omitted for the system-instruction block, which carries no
    /// role.
    public let role: GeminiRole?

    /// Gemini models content as an array of parts so a single turn
    /// can mix text with inline images. KozBon sends text only.
    public let parts: [GeminiPart]

    public init(role: GeminiRole?, parts: [GeminiPart]) {
        self.role = role
        self.parts = parts
    }

    /// Convenience for the common single-text-part turn.
    public init(role: GeminiRole?, text: String) {
        self.init(role: role, parts: [GeminiPart(text: text)])
    }
}

// MARK: - GeminiPart

/// A single piece of content within a ``GeminiContent``.
public struct GeminiPart: Sendable, Equatable, Encodable {

    public let text: String

    public init(text: String) {
        self.text = text
    }
}

// MARK: - GeminiRole

/// Role of a ``GeminiContent`` turn.
///
/// Note the assistant is `model`, not `assistant` — the wire
/// spelling differs from Anthropic's, which is exactly why the
/// role is an enum rather than a raw string at the call site.
public enum GeminiRole: String, Sendable, Equatable, Codable {
    case user
    case model
}

// MARK: - GeminiGenerationConfig

/// Output limits and sampling parameters.
public struct GeminiGenerationConfig: Sendable, Equatable, Encodable {

    /// Maximum tokens the model is allowed to emit.
    public let maxOutputTokens: Int

    /// Optional sampling temperature. Left `nil` to inherit the
    /// per-model default.
    public let temperature: Double?

    public init(maxOutputTokens: Int, temperature: Double? = nil) {
        self.maxOutputTokens = maxOutputTokens
        self.temperature = temperature
    }
}
