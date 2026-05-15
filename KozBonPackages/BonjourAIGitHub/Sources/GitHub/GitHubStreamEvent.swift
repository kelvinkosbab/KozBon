//
//  GitHubStreamEvent.swift
//  BonjourAIGitHub
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourAICore

// MARK: - GitHubStreamEvent

/// A decoded Server-Sent Event from GitHub Models'
/// `chat/completions` streaming response.
///
/// Models only the variants ``GitHubModelsClient`` cares about.
/// OpenAI's full SSE surface includes function-call deltas and
/// tool messages — those are decoded into ``other`` and ignored
/// at the consumer layer. The decoder never throws on unknown
/// shapes, only on actively malformed JSON.
enum GitHubStreamEvent: Equatable, Sendable {

    /// A token (or short token run) of the assistant's response.
    /// The value is the raw incremental text the consumer should
    /// append to the current message. Multiple `textDelta` events
    /// per response are typical.
    case textDelta(String)

    /// An error event the API embedded inline (rate limit reached
    /// mid-stream, content-policy block, etc.). OpenAI-style:
    /// `{"error": {"message": "...", "type": "..."}}`.
    case error(message: String, type: String?)

    /// Any other recognized payload with no specific
    /// consumer-facing meaning (an empty delta, a finish-reason
    /// marker, etc.). Kept as a tagged case so the decoder can
    /// pass them along without raising — silently dropping
    /// unknown shapes would make decoder bugs invisible.
    case other

    // MARK: - Decoding

    /// Decodes a single `data: {...}` payload extracted from an
    /// SSE frame.
    ///
    /// - Parameter payload: The raw JSON string that followed
    ///   `data: ` on a single SSE line.
    /// - Returns: The decoded event, or `nil` for the `[DONE]`
    ///   sentinel (end-of-stream marker).
    /// - Throws: ``AICloudError/decodingFailure(message:)`` if
    ///   the JSON is malformed.
    static func decode(payload: String) throws -> GitHubStreamEvent? {
        // OpenAI-compatible streams terminate with the literal
        // string `[DONE]` after the final delta. Treat it as a
        // no-op — the consumer iterates until the stream itself
        // finishes.
        let trimmed = payload.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed == "[DONE]" {
            return nil
        }

        guard let data = trimmed.data(using: .utf8) else {
            throw AICloudError.decodingFailure(message: "Non-UTF8 SSE payload.")
        }

        let raw: [String: Any]
        do {
            guard let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw AICloudError.decodingFailure(message: "SSE payload is not a JSON object.")
            }
            raw = parsed
        } catch let error as AICloudError {
            throw error
        } catch {
            throw AICloudError.decodingFailure(message: "Invalid JSON: \(error.localizedDescription)")
        }

        // Inline error events take precedence over choice
        // decoding — when both are present (rare), the error is
        // what the consumer needs to surface.
        if let errorEvent = decodeError(from: raw) {
            return errorEvent
        }

        return decodeTextDelta(from: raw)
    }

    // MARK: - Private Helpers

    private static func decodeTextDelta(from raw: [String: Any]) -> GitHubStreamEvent {
        // OpenAI streaming shape:
        // `{"choices": [{"delta": {"content": "Hello"}, ...}], ...}`
        // Empty `delta` objects (e.g., role markers, function-call
        // openers) decode to `.other`.
        guard let choices = raw["choices"] as? [[String: Any]],
              let first = choices.first,
              let delta = first["delta"] as? [String: Any],
              let content = delta["content"] as? String,
              !content.isEmpty else {
            return .other
        }
        return .textDelta(content)
    }

    private static func decodeError(from raw: [String: Any]) -> GitHubStreamEvent? {
        guard let error = raw["error"] as? [String: Any] else {
            return nil
        }
        let message = error["message"] as? String ?? "Unknown error"
        let errorType = error["type"] as? String
        return .error(message: message, type: errorType)
    }
}
