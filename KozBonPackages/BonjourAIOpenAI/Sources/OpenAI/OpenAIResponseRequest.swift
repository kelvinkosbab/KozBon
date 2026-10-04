//
//  OpenAIResponseRequest.swift
//  BonjourAIOpenAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourAICore

// MARK: - OpenAIResponseRequest

/// The body of a call to OpenAI's `POST /v1/responses` endpoint.
///
/// The Responses API rather than Chat Completions: OpenAI's newer
/// models are offered there first (some only there), and it takes
/// system instructions as a top-level field the way Gemini does.
///
/// `stream` and `store` are fixed rather than configurable. Every
/// KozBon surface streams, and `store: false` keeps OpenAI from
/// retaining the conversation server-side — the app replays its
/// own history on every turn, so stored responses would be pure
/// data retention with no benefit.
public struct OpenAIResponseRequest: Sendable, Equatable, Encodable {

    // MARK: - Properties

    /// The model to send to (e.g. `gpt-5.4-mini`).
    public let model: String

    /// System instructions. Optional because a request with none
    /// should omit the field rather than send it blank.
    public let instructions: String?

    /// The user / assistant turn history. The final element is
    /// always the user's latest message.
    public let input: [OpenAIInputMessage]

    /// Cap on generated tokens. For reasoning models this budget
    /// covers the hidden reasoning as well as the visible answer.
    public let maxOutputTokens: Int

    /// Reasoning settings, sent only to models that accept them —
    /// see ``OpenAIReasoning/forModel(_:)``.
    public let reasoning: OpenAIReasoning?

    public let stream: Bool = true
    public let store: Bool = false

    // MARK: - Init

    public init(
        model: String,
        instructions: String?,
        input: [OpenAIInputMessage],
        maxOutputTokens: Int,
        reasoning: OpenAIReasoning? = nil
    ) {
        self.model = model
        self.instructions = instructions
        self.input = input
        self.maxOutputTokens = maxOutputTokens
        self.reasoning = reasoning
    }

    /// Builds a request with the reasoning setting that suits
    /// `model`.
    public static func make(
        model: String,
        instructions: String?,
        input: [OpenAIInputMessage],
        maxOutputTokens: Int
    ) -> OpenAIResponseRequest {
        OpenAIResponseRequest(
            model: model,
            instructions: instructions,
            input: input,
            maxOutputTokens: maxOutputTokens,
            reasoning: OpenAIReasoning.forModel(model)
        )
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case model
        case instructions
        case input
        case maxOutputTokens = "max_output_tokens"
        case reasoning
        case stream
        case store
    }
}

// MARK: - OpenAIInputMessage

/// One turn in an ``OpenAIResponseRequest``.
public struct OpenAIInputMessage: Sendable, Equatable, Encodable {

    public let role: OpenAIRole

    /// Plain-text content. The API also accepts an array of typed
    /// content parts; KozBon sends text only, and the string form
    /// is valid for both roles.
    public let content: String

    public init(role: OpenAIRole, content: String) {
        self.role = role
        self.content = content
    }
}

// MARK: - OpenAIRole

/// Role of an ``OpenAIInputMessage``. System instructions travel in
/// ``OpenAIResponseRequest/instructions``, so there's no system case.
public enum OpenAIRole: String, Sendable, Equatable, Codable {
    case user
    case assistant
}

// MARK: - OpenAIReasoning

/// The `reasoning` object for models that think before answering.
public struct OpenAIReasoning: Sendable, Equatable, Encodable {

    /// `low`, `medium`, or `high`.
    public let effort: String

    public init(effort: String) {
        self.effort = effort
    }

    /// The reasoning setting to send for `model`, or `nil` to omit
    /// the field.
    ///
    /// Low effort, because the API's default (medium) spends most of
    /// the output budget thinking about questions like "what is
    /// `_ipp._tcp`?" — slower answers, and occasionally a budget
    /// exhausted before any visible text. Omitted for models that
    /// reject the parameter: non-reasoning families, the `-chat`
    /// variants, and `-pro` models, which accept only high effort.
    /// An unrecognized family gets nothing, since sending an
    /// unsupported parameter fails the whole request.
    public static func forModel(_ model: String) -> OpenAIReasoning? {
        let id = model.lowercased()
        let reasoningFamilies = ["gpt-5", "gpt-6", "o3", "o4"]
        guard reasoningFamilies.contains(where: id.hasPrefix),
              !id.contains("-chat"),
              !id.contains("-pro") else {
            return nil
        }
        return OpenAIReasoning(effort: "low")
    }
}
