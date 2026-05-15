//
//  AnthropicStreamEventTests.swift
//  BonjourAIAnthropic
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourAICore
@testable import BonjourAIAnthropic

// MARK: - AnthropicStreamEventTests

@Suite("AnthropicStreamEvent")
struct AnthropicStreamEventTests {

    // MARK: - Text Delta

    @Test("`content_block_delta` with a text_delta returns `.textDelta` carrying the text")
    func decodesTextDelta() throws {
        let payload = #"""
        {"type": "content_block_delta", "index": 0, "delta": {"type": "text_delta", "text": "Hello"}}
        """#

        let event = try #require(try AnthropicStreamEvent.decode(payload: payload))
        #expect(event == .textDelta("Hello"))
    }

    @Test("`content_block_delta` with an unsupported delta type falls through to `.other`")
    func decodesUnsupportedDeltaAsOther() throws {
        let payload = #"""
        {"type": "content_block_delta", "delta": {"type": "input_json_delta", "partial_json": "{}"}}
        """#

        let event = try #require(try AnthropicStreamEvent.decode(payload: payload))
        if case let .other(type) = event {
            #expect(type == "content_block_delta.input_json_delta")
        } else {
            Issue.record("Expected .other event, got \(event)")
        }
    }

    // MARK: - Message Stop

    @Test("`message_stop` decodes to the terminator event")
    func decodesMessageStop() throws {
        let payload = #"{"type": "message_stop"}"#
        let event = try #require(try AnthropicStreamEvent.decode(payload: payload))
        #expect(event == .messageStop)
    }

    // MARK: - Error

    @Test("Inline error event extracts message and type")
    func decodesInlineError() throws {
        let payload = #"""
        {"type": "error", "error": {"type": "overloaded_error", "message": "Server overloaded"}}
        """#

        let event = try #require(try AnthropicStreamEvent.decode(payload: payload))
        if case let .error(message, type) = event {
            #expect(message == "Server overloaded")
            #expect(type == "overloaded_error")
        } else {
            Issue.record("Expected .error event, got \(event)")
        }
    }

    @Test("Error event with a missing inner `error` field uses a generic message")
    func decodesIncompleteError() throws {
        let payload = #"{"type": "error"}"#
        let event = try #require(try AnthropicStreamEvent.decode(payload: payload))

        if case let .error(message, _) = event {
            #expect(message == "Unknown error")
        } else {
            Issue.record("Expected .error event, got \(event)")
        }
    }

    // MARK: - Other

    @Test("Recognized but unused event types decode to `.other`")
    func decodesRecognizedOtherEvents() throws {
        let payloads = [
            (#"{"type": "ping"}"#, "ping"),
            (#"{"type": "message_start", "message": {"id": "1"}}"#, "message_start"),
            (#"{"type": "content_block_start"}"#, "content_block_start"),
            (#"{"type": "content_block_stop"}"#, "content_block_stop"),
            (#"{"type": "message_delta"}"#, "message_delta")
        ]

        for (payload, expectedType) in payloads {
            let event = try #require(try AnthropicStreamEvent.decode(payload: payload))
            if case let .other(type) = event {
                #expect(type == expectedType)
            } else {
                Issue.record("Expected .other(\(expectedType)), got \(event)")
            }
        }
    }

    // MARK: - DONE Sentinel

    @Test("`[DONE]` sentinel decodes to nil so the consumer skips it")
    func decodesDoneSentinelAsNil() throws {
        let event = try AnthropicStreamEvent.decode(payload: "[DONE]")
        #expect(event == nil)
    }

    @Test("`[DONE]` sentinel handles surrounding whitespace")
    func decodesDoneSentinelTrimmed() throws {
        let event = try AnthropicStreamEvent.decode(payload: "  [DONE]\n")
        #expect(event == nil)
    }

    // MARK: - Error Cases

    @Test("Malformed JSON throws `decodingFailure`")
    func malformedJSONThrows() {
        #expect(throws: AICloudError.self) {
            _ = try AnthropicStreamEvent.decode(payload: "{not json")
        }
    }

    @Test("Missing `type` field throws `decodingFailure`")
    func missingTypeThrows() {
        #expect(throws: AICloudError.self) {
            _ = try AnthropicStreamEvent.decode(payload: #"{"foo": "bar"}"#)
        }
    }

    @Test("Top-level non-object payload throws `decodingFailure`")
    func topLevelArrayThrows() {
        #expect(throws: AICloudError.self) {
            _ = try AnthropicStreamEvent.decode(payload: "[1, 2, 3]")
        }
    }
}
