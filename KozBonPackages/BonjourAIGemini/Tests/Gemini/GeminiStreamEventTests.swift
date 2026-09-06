//
//  GeminiStreamEventTests.swift
//  BonjourAIGemini
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourAICore
@testable import BonjourAIGemini

// MARK: - GeminiStreamEventTests

/// Pins the SSE decoder.
///
/// Gemini's stream has no per-event `type` tag and no terminal
/// stop event — every frame is a full `GenerateContentResponse`
/// and classification is by content. These tests fix that
/// classification so a wire-format change surfaces here rather
/// than as silently-dropped answer text.
@Suite("GeminiStreamEvent")
struct GeminiStreamEventTests {

    // MARK: - Text

    @Test("A candidate carrying text decodes as a delta")
    func decodesTextDelta() throws {
        let payload = #"""
        {"candidates":[{"content":{"role":"model","parts":[{"text":"Hello"}]}}]}
        """#
        #expect(try GeminiStreamEvent.decode(payload: payload) == .textDelta("Hello"))
    }

    @Test("Multiple parts in one candidate concatenate rather than dropping any")
    func joinsMultipleParts() throws {
        let payload = #"""
        {"candidates":[{"content":{"role":"model","parts":[{"text":"Hel"},{"text":"lo"}]}}]}
        """#
        #expect(try GeminiStreamEvent.decode(payload: payload) == .textDelta("Hello"))
    }

    @Test("Text wins over a finish reason in the same frame, so the tail isn't lost")
    func prefersTextOverFinishReason() throws {
        // The final frame routinely carries both. Reading the
        // finish reason first would silently truncate the answer.
        let payload = #"""
        {"candidates":[{"content":{"role":"model","parts":[{"text":"!"}]},"finishReason":"STOP"}]}
        """#
        #expect(try GeminiStreamEvent.decode(payload: payload) == .textDelta("!"))
    }

    // MARK: - Termination

    @Test("A textless candidate with a finish reason ends the stream")
    func decodesFinishReason() throws {
        let payload = #"""
        {"candidates":[{"content":{"role":"model","parts":[]},"finishReason":"STOP"}]}
        """#
        #expect(try GeminiStreamEvent.decode(payload: payload) == .finished(reason: "STOP"))
    }

    @Test("A truncation reason is preserved rather than normalized to STOP")
    func preservesTruncationReason() throws {
        let payload = #"""
        {"candidates":[{"finishReason":"MAX_TOKENS"}]}
        """#
        #expect(try GeminiStreamEvent.decode(payload: payload) == .finished(reason: "MAX_TOKENS"))
    }

    @Test("The [DONE] sentinel some proxies append is a no-op, not a failure")
    func ignoresDoneSentinel() throws {
        #expect(try GeminiStreamEvent.decode(payload: " [DONE] ") == nil)
        #expect(try GeminiStreamEvent.decode(payload: "   ") == nil)
    }

    // MARK: - Errors

    @Test("A mid-stream error object decodes as an error")
    func decodesInlineError() throws {
        let payload = #"""
        {"error":{"code":429,"message":"Resource has been exhausted","status":"RESOURCE_EXHAUSTED"}}
        """#
        #expect(
            try GeminiStreamEvent.decode(payload: payload)
                == .error(message: "Resource has been exhausted", status: "RESOURCE_EXHAUSTED")
        )
    }

    @Test("Malformed JSON throws rather than being silently skipped")
    func throwsOnMalformedJSON() {
        #expect(throws: AICloudError.self) {
            _ = try GeminiStreamEvent.decode(payload: "{not json")
        }
    }

    @Test("A non-object payload throws")
    func throwsOnNonObjectPayload() {
        #expect(throws: AICloudError.self) {
            _ = try GeminiStreamEvent.decode(payload: "[1, 2, 3]")
        }
    }

    // MARK: - Unremarkable Frames

    @Test("A usage-metadata-only frame is tagged, not dropped, so decoder bugs stay visible")
    func tagsFramesWithoutCandidates() throws {
        let payload = #"""
        {"usageMetadata":{"promptTokenCount":12,"totalTokenCount":12}}
        """#
        #expect(try GeminiStreamEvent.decode(payload: payload) == .other(reason: "no-candidates"))
    }

    @Test("A candidate with neither text nor a finish reason is tagged")
    func tagsEmptyCandidate() throws {
        let payload = #"""
        {"candidates":[{"content":{"role":"model","parts":[]}}]}
        """#
        #expect(try GeminiStreamEvent.decode(payload: payload) == .other(reason: "empty-candidate"))
    }
}
