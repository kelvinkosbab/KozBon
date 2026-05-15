//
//  GitHubStreamEventTests.swift
//  BonjourAIGitHub
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourAICore
@testable import BonjourAIGitHub

// MARK: - GitHubStreamEventTests

@Suite("GitHubStreamEvent")
struct GitHubStreamEventTests {

    // MARK: - Text Delta

    @Test("Choice with a non-empty content delta returns `.textDelta`")
    func decodesTextDelta() throws {
        let payload = #"""
        {"choices": [{"delta": {"content": "Hello"}, "index": 0}]}
        """#

        let event = try #require(try GitHubStreamEvent.decode(payload: payload))
        #expect(event == .textDelta("Hello"))
    }

    @Test("Empty delta object decodes to `.other` (e.g., function-call delta)")
    func decodesEmptyDeltaAsOther() throws {
        let payload = #"""
        {"choices": [{"delta": {}}]}
        """#

        let event = try #require(try GitHubStreamEvent.decode(payload: payload))
        #expect(event == .other)
    }

    @Test("Role-only delta (start of stream) decodes to `.other`")
    func decodesRoleOnlyDeltaAsOther() throws {
        let payload = #"""
        {"choices": [{"delta": {"role": "assistant"}}]}
        """#

        let event = try #require(try GitHubStreamEvent.decode(payload: payload))
        #expect(event == .other)
    }

    // MARK: - DONE Sentinel

    @Test("`[DONE]` sentinel decodes to nil so the consumer terminates")
    func decodesDoneSentinelAsNil() throws {
        let event = try GitHubStreamEvent.decode(payload: "[DONE]")
        #expect(event == nil)
    }

    @Test("`[DONE]` sentinel handles surrounding whitespace")
    func decodesDoneSentinelTrimmed() throws {
        let event = try GitHubStreamEvent.decode(payload: "  [DONE]\n")
        #expect(event == nil)
    }

    // MARK: - Inline Error

    @Test("Inline error event extracts message and type")
    func decodesInlineError() throws {
        let payload = #"""
        {"error": {"type": "rate_limit_exceeded", "message": "Rate limit exceeded"}}
        """#

        let event = try #require(try GitHubStreamEvent.decode(payload: payload))
        if case let .error(message, type) = event {
            #expect(message == "Rate limit exceeded")
            #expect(type == "rate_limit_exceeded")
        } else {
            Issue.record("Expected .error event, got \(event)")
        }
    }

    @Test("Error event with a missing inner `error` field uses a generic message")
    func decodesIncompleteError() throws {
        // The decoder treats `{"error": {}}` as inline-error
        // territory with the generic fallback message, so the
        // consumer surfaces something useful instead of a silent
        // `.other`.
        let payload = #"{"error": {}}"#
        let event = try #require(try GitHubStreamEvent.decode(payload: payload))
        if case let .error(message, _) = event {
            #expect(message == "Unknown error")
        } else {
            Issue.record("Expected .error event, got \(event)")
        }
    }

    // MARK: - Error Cases

    @Test("Malformed JSON throws `decodingFailure`")
    func malformedJSONThrows() {
        #expect(throws: AICloudError.self) {
            _ = try GitHubStreamEvent.decode(payload: "{not json")
        }
    }

    @Test("Top-level non-object payload throws `decodingFailure`")
    func topLevelArrayThrows() {
        #expect(throws: AICloudError.self) {
            _ = try GitHubStreamEvent.decode(payload: "[1, 2, 3]")
        }
    }

    @Test("Payload with no choices or error decodes to `.other`")
    func decodesUnknownShapeAsOther() throws {
        // OpenAI streams occasionally emit metadata frames
        // (`{"id": "...", "object": "chat.completion.chunk"}`)
        // with no `choices` or `error`. Treat as no-op.
        let payload = #"{"id": "chatcmpl-1", "object": "chat.completion.chunk"}"#
        let event = try #require(try GitHubStreamEvent.decode(payload: payload))
        #expect(event == .other)
    }
}
