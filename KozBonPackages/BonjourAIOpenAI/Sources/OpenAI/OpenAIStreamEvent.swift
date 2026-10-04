//
//  OpenAIStreamEvent.swift
//  BonjourAIOpenAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourAICore

// MARK: - OpenAIStreamEvent

/// A decoded Server-Sent Event from a streaming
/// `POST /v1/responses` call.
///
/// Each `data:` payload carries its own `type` tag, so — unlike
/// Gemini's — this decoder classifies by type rather than by
/// content. Only the handful of events KozBon acts on get their own
/// case; everything else (`response.created`, item and content-part
/// bookkeeping, reasoning summaries) decodes as ``other(type:)``.
enum OpenAIStreamEvent: Equatable, Sendable {

    /// Incremental assistant text the consumer should append.
    case textDelta(String)

    /// The response finished normally.
    case completed

    /// The response ended early — typically the output-token cap.
    case incomplete(reason: String?)

    /// The response failed server-side after streaming began.
    case failed(message: String?)

    /// A top-level `error` event.
    case error(message: String, code: String?)

    /// An event KozBon doesn't act on. Tagged rather than dropped so
    /// decoder gaps stay visible in logs.
    case other(type: String)

    // MARK: - Decoding

    /// Decodes a single `data: {...}` payload from an SSE frame.
    ///
    /// - Parameter payload: The raw JSON that followed `data:`.
    /// - Returns: The decoded event, or `nil` for an empty payload
    ///   or the `[DONE]` sentinel Chat Completions-style proxies
    ///   append.
    /// - Throws: ``AICloudError/decodingFailure(message:)`` when the
    ///   payload isn't a JSON object.
    static func decode(payload: String) throws -> OpenAIStreamEvent? {
        let trimmed = payload.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == "[DONE]" {
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

        return classify(raw)
    }

    // MARK: - Private Helpers

    /// Maps a parsed payload to an event by its `type` tag.
    private static func classify(_ raw: [String: Any]) -> OpenAIStreamEvent {
        let type = raw["type"] as? String ?? ""
        let response = raw["response"] as? [String: Any]

        switch type {
        case "response.output_text.delta":
            return .textDelta(raw["delta"] as? String ?? "")
        case "response.completed":
            return .completed
        case "response.incomplete":
            let details = response?["incomplete_details"] as? [String: Any]
            return .incomplete(reason: details?["reason"] as? String)
        case "response.failed":
            let error = response?["error"] as? [String: Any]
            return .failed(message: error?["message"] as? String)
        case "error":
            // The fields sit at the top level, or nested under
            // `error` depending on where the failure was raised.
            let nested = raw["error"] as? [String: Any]
            let message = raw["message"] as? String
                ?? nested?["message"] as? String
                ?? "Unknown error"
            let code = raw["code"] as? String ?? nested?["code"] as? String
            return .error(message: message, code: code)
        default:
            return .other(type: type.isEmpty ? "untyped" : type)
        }
    }
}
