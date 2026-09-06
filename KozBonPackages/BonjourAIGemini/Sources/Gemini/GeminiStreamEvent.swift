//
//  GeminiStreamEvent.swift
//  BonjourAIGemini
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourAICore

// MARK: - GeminiStreamEvent

/// A decoded Server-Sent Event from Gemini's
/// `:streamGenerateContent?alt=sse` response.
///
/// Gemini's stream differs from Anthropic's in a way that shapes
/// this type: there are no per-event `type` tags and no terminal
/// `message_stop`. Every frame is a full `GenerateContentResponse`
/// carrying whatever new text exists, and the stream ends when the
/// connection closes — usually after a frame whose candidate has a
/// `finishReason`. So the decoder classifies by *content* rather
/// than by a type field, and never throws on unknown shapes, only
/// on actively malformed JSON.
enum GeminiStreamEvent: Equatable, Sendable {

    /// Incremental assistant text the consumer should append.
    case textDelta(String)

    /// The candidate reported a `finishReason` — no more text is
    /// coming.
    ///
    /// - Parameter reason: The raw reason. `STOP` is the normal
    ///   completion; `MAX_TOKENS`, `SAFETY`, and `RECITATION`
    ///   are truncations the consumer may want to surface.
    case finished(reason: String)

    /// An error the API embedded in the stream body.
    case error(message: String, status: String?)

    /// A frame with nothing actionable — usage-metadata-only
    /// frames, or a candidate whose parts are empty. Tagged
    /// rather than dropped so decoder bugs stay visible in logs.
    case other(reason: String)

    // MARK: - Decoding

    /// Decodes a single `data: {...}` payload from an SSE frame.
    ///
    /// - Parameter payload: The raw JSON that followed `data:` on
    ///   one SSE line.
    /// - Returns: The decoded event, or `nil` for the `[DONE]`
    ///   sentinel some proxies append.
    /// - Throws: ``AICloudError/decodingFailure(message:)`` when
    ///   the payload isn't a JSON object.
    static func decode(payload: String) throws -> GeminiStreamEvent? {
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

        // An error can arrive mid-stream as a top-level `error`
        // object instead of a candidates payload.
        if let error = raw["error"] as? [String: Any] {
            let message = error["message"] as? String ?? "Unknown error"
            return .error(message: message, status: error["status"] as? String)
        }

        guard let candidates = raw["candidates"] as? [[String: Any]],
              let candidate = candidates.first else {
            // Frames carrying only `usageMetadata` land here.
            return .other(reason: "no-candidates")
        }

        // Text first: a frame can carry both a final chunk of text
        // and the `finishReason`, and dropping the text would lose
        // the tail of the answer.
        if let text = extractText(from: candidate), !text.isEmpty {
            return .textDelta(text)
        }

        if let reason = candidate["finishReason"] as? String {
            return .finished(reason: reason)
        }

        return .other(reason: "empty-candidate")
    }

    // MARK: - Private Helpers

    /// Joins every text part in the candidate's content.
    ///
    /// Usually one part, but the API is specified as an array and
    /// concatenating is the lossless reading.
    private static func extractText(from candidate: [String: Any]) -> String? {
        guard let content = candidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]] else {
            return nil
        }
        let texts = parts.compactMap { $0["text"] as? String }
        return texts.isEmpty ? nil : texts.joined()
    }
}
