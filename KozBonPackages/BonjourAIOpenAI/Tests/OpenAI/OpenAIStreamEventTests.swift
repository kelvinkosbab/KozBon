//
//  OpenAIStreamEventTests.swift
//  BonjourAIOpenAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourAICore
@testable import BonjourAIOpenAI

// MARK: - OpenAIStreamEventTests

/// Pins the Responses API SSE decoder, so a wire-format change
/// surfaces here rather than as silently-dropped answer text.
@Suite("OpenAIStreamEvent")
struct OpenAIStreamEventTests {

    @Test("A text delta decodes with its text")
    func decodesTextDelta() throws {
        let payload = #"{"type":"response.output_text.delta","item_id":"msg_1","delta":"Hello"}"#
        #expect(try OpenAIStreamEvent.decode(payload: payload) == .textDelta("Hello"))
    }

    @Test("Completion decodes as completed")
    func decodesCompleted() throws {
        let payload = #"{"type":"response.completed","response":{"status":"completed"}}"#
        #expect(try OpenAIStreamEvent.decode(payload: payload) == .completed)
    }

    @Test("An incomplete response carries its reason")
    func decodesIncomplete() throws {
        let payload = #"""
        {"type":"response.incomplete","response":{"incomplete_details":{"reason":"max_output_tokens"}}}
        """#
        #expect(try OpenAIStreamEvent.decode(payload: payload) == .incomplete(reason: "max_output_tokens"))
    }

    @Test("A failed response carries the server's message")
    func decodesFailed() throws {
        let payload = #"{"type":"response.failed","response":{"error":{"code":"server_error","message":"boom"}}}"#
        #expect(try OpenAIStreamEvent.decode(payload: payload) == .failed(message: "boom"))
    }

    @Test("A top-level error decodes its message and code")
    func decodesError() throws {
        let payload = #"{"type":"error","code":"rate_limit_exceeded","message":"slow down"}"#
        #expect(
            try OpenAIStreamEvent.decode(payload: payload)
                == .error(message: "slow down", code: "rate_limit_exceeded")
        )
    }

    @Test("Bookkeeping events decode as other, tagged with their type")
    func decodesOtherEvents() throws {
        let payload = #"{"type":"response.output_item.added","item":{}}"#
        #expect(try OpenAIStreamEvent.decode(payload: payload) == .other(type: "response.output_item.added"))
    }

    @Test("Empty payloads and the [DONE] sentinel decode to nil")
    func skipsSentinels() throws {
        #expect(try OpenAIStreamEvent.decode(payload: "") == nil)
        #expect(try OpenAIStreamEvent.decode(payload: " [DONE] ") == nil)
    }

    @Test("Malformed JSON throws a decoding failure rather than crashing")
    func throwsOnMalformedJSON() {
        #expect(throws: AICloudError.self) {
            _ = try OpenAIStreamEvent.decode(payload: "{not json")
        }
    }
}
