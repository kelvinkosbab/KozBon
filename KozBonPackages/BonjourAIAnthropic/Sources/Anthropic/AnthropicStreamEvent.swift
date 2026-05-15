//
//  AnthropicStreamEvent.swift
//  BonjourAIAnthropic
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourAICore

// MARK: - AnthropicStreamEvent

/// A decoded Server-Sent Event from Anthropic's streaming
/// `/v1/messages` response.
///
/// Models only the variants ``AnthropicClient`` cares about for
/// chat / Insights. The full SSE surface from Anthropic includes
/// ping events, message-level metadata, and per-block start /
/// stop markers — those are decoded into ``other`` and ignored
/// at the consumer layer. The decoder never throws on unknown
/// event types, only on actively malformed JSON.
enum AnthropicStreamEvent: Equatable, Sendable {

    /// A token (or short token run) of the assistant's response.
    /// The value is the raw incremental text the consumer should
    /// append to the current message. Multiple `textDelta` events
    /// per response are typical.
    case textDelta(String)

    /// The stream finished normally — Anthropic emitted the
    /// `message_stop` event. The consumer should treat this as
    /// "no more text is coming."
    case messageStop

    /// An error event the API embedded inline (rate limit
    /// reached mid-stream, content-policy block, etc.).
    case error(message: String, type: String?)

    /// Any other recognized event type with no specific
    /// consumer-facing meaning (ping, content_block_start,
    /// content_block_stop, message_start, message_delta). Kept
    /// as a tagged case so the decoder can pass them along
    /// without raising — silently dropping unknown events would
    /// make decoder bugs invisible.
    case other(type: String)

    // MARK: - Decoding

    /// Decodes a single `data: {...}` payload extracted from an
    /// SSE frame.
    ///
    /// - Parameter payload: The raw JSON string that followed
    ///   `data: ` on a single SSE line.
    /// - Returns: The decoded event, or `nil` for payloads that
    ///   carry no actionable content (specifically, Anthropic's
    ///   `[DONE]` sentinel emitted at end-of-stream by some API
    ///   versions).
    /// - Throws: ``AICloudError/decodingFailure(message:)`` if
    ///   the JSON is malformed or the `type` field is missing.
    static func decode(payload: String) throws -> AnthropicStreamEvent? {
        // Some Anthropic API versions terminate with the literal
        // string "[DONE]" rather than a JSON event. Treat it as a
        // no-op — `messageStop` is what the consumer cares about,
        // and that's emitted as its own event before this sentinel.
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

        guard let type = raw["type"] as? String else {
            throw AICloudError.decodingFailure(message: "SSE payload missing `type` field.")
        }

        switch type {
        case "content_block_delta":
            return decodeTextDelta(from: raw)
        case "message_stop":
            return .messageStop
        case "error":
            return decodeError(from: raw)
        default:
            return .other(type: type)
        }
    }

    // MARK: - Private Helpers

    private static func decodeTextDelta(from raw: [String: Any]) -> AnthropicStreamEvent {
        // `{"type": "content_block_delta", "delta": {"type": "text_delta", "text": "Hello"}}`
        // Anthropic also emits `input_json_delta` for tool calls, which we
        // don't use yet — pass those through as `.other` so they're
        // visible to logs but ignored by the chat consumer.
        guard let delta = raw["delta"] as? [String: Any],
              let deltaType = delta["type"] as? String else {
            return .other(type: "content_block_delta")
        }

        if deltaType == "text_delta", let text = delta["text"] as? String {
            return .textDelta(text)
        }
        return .other(type: "content_block_delta.\(deltaType)")
    }

    private static func decodeError(from raw: [String: Any]) -> AnthropicStreamEvent {
        // `{"type": "error", "error": {"type": "overloaded_error", "message": "..."}}`
        guard let error = raw["error"] as? [String: Any] else {
            return .error(message: "Unknown error", type: nil)
        }
        let message = error["message"] as? String ?? "Unknown error"
        let errorType = error["type"] as? String
        return .error(message: message, type: errorType)
    }
}
