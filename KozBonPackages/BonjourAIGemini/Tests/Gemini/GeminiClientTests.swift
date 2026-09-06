//
//  GeminiClientTests.swift
//  BonjourAIGemini
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourAICore
@testable import BonjourAIGemini

// MARK: - GeminiClientTests

/// Exercises ``GeminiClient`` against a `URLProtocol` stub — no
/// network, no key, deterministic bytes.
///
/// `.serialized` because `StubURLProtocol.handler` is a single
/// static slot: run in parallel, these tests hand each other's
/// canned responses back. Same reason the Anthropic client suite
/// is serialized.
@Suite("GeminiClient", .serialized)
struct GeminiClientTests {

    // MARK: - Helpers
    //
    // Not `private`: `private` doesn't span files, and the
    // error-mapping extension lives in its own file.

    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    static func makeClient(
        session: URLSession,
        model: GeminiModel = .flash
    ) -> GeminiClient {
        GeminiClient(
            configuration: GeminiConfiguration(
                baseURL: URL(string: "https://gemini.invalid").unsafelyUnwrapped,
                model: model
            ),
            urlSession: session
        )
    }

    static func makeRequest(model: String = "gemini-2.5-flash") -> GeminiGenerateRequest {
        GeminiGenerateRequest(
            model: model,
            contents: [GeminiContent(role: .user, text: "hi")],
            systemInstruction: GeminiContent(role: nil, text: "be brief"),
            generationConfig: GeminiGenerationConfig(maxOutputTokens: 64)
        )
    }

    static func sse(_ frames: [String]) -> Data {
        Data(frames.map { "data: \($0)\n\n" }.joined().utf8)
    }

    static func collect(
        _ stream: AsyncThrowingStream<String, Error>
    ) async throws -> String {
        var output = ""
        for try await chunk in stream {
            output += chunk
        }
        return output
    }

    // MARK: - Streaming

    @Test("Text frames stream through in order")
    func streamsTextInOrder() async throws {
        StubURLProtocol.handler = { _ in
            .success(statusCode: 200, body: Self.sse([
                #"{"candidates":[{"content":{"parts":[{"text":"Hel"}]}}]}"#,
                #"{"candidates":[{"content":{"parts":[{"text":"lo"}]}}]}"#,
                #"{"candidates":[{"finishReason":"STOP"}]}"#,
            ]))
        }
        defer { StubURLProtocol.handler = nil }

        let client = Self.makeClient(session: Self.makeSession())
        let text = try await Self.collect(
            client.streamMessage(request: Self.makeRequest(), apiKey: "AIzaTEST")
        )

        #expect(text == "Hello")
    }

    @Test("A finish reason ends the stream, so trailing frames are ignored")
    func stopsAtFinishReason() async throws {
        StubURLProtocol.handler = { _ in
            .success(statusCode: 200, body: Self.sse([
                #"{"candidates":[{"content":{"parts":[{"text":"done"}]}}]}"#,
                #"{"candidates":[{"finishReason":"STOP"}]}"#,
                #"{"candidates":[{"content":{"parts":[{"text":"IGNORED"}]}}]}"#,
            ]))
        }
        defer { StubURLProtocol.handler = nil }

        let client = Self.makeClient(session: Self.makeSession())
        let text = try await Self.collect(
            client.streamMessage(request: Self.makeRequest(), apiKey: "AIzaTEST")
        )

        #expect(text == "done")
    }

    // MARK: - Request Shape

    @Test("The key rides in a header, never the query string")
    func sendsKeyAsHeaderNotQuery() async throws {
        let captured = CapturedRequest()
        StubURLProtocol.handler = { request in
            captured.set(request)
            return .success(statusCode: 200, body: Self.sse([
                #"{"candidates":[{"finishReason":"STOP"}]}"#,
            ]))
        }
        defer { StubURLProtocol.handler = nil }

        let client = Self.makeClient(session: Self.makeSession())
        _ = try await Self.collect(
            client.streamMessage(request: Self.makeRequest(), apiKey: "AIzaSECRET")
        )

        let request = try #require(captured.value)
        #expect(request.value(forHTTPHeaderField: "x-goog-api-key") == "AIzaSECRET")

        // A credential in the query string leaks into logs,
        // proxies, and crash reports.
        let url = try #require(request.url?.absoluteString)
        #expect(!url.contains("AIzaSECRET"))
        #expect(!url.contains("key="))
    }

    @Test("The request's model addresses the endpoint, and alt=sse is set")
    func buildsStreamingURLFromRequestModel() async throws {
        let captured = CapturedRequest()
        StubURLProtocol.handler = { request in
            captured.set(request)
            return .success(statusCode: 200, body: Self.sse([
                #"{"candidates":[{"finishReason":"STOP"}]}"#,
            ]))
        }
        defer { StubURLProtocol.handler = nil }

        // Configuration says flash; the request says pro. The
        // request wins — a session picks its model long after the
        // client is built.
        let client = Self.makeClient(session: Self.makeSession(), model: .flash)
        _ = try await Self.collect(
            client.streamMessage(
                request: Self.makeRequest(model: "gemini-2.5-pro"),
                apiKey: "AIzaTEST"
            )
        )

        let url = try #require(captured.value?.url?.absoluteString)
        #expect(url.contains("/v1beta/models/gemini-2.5-pro:streamGenerateContent"))
        #expect(url.contains("alt=sse"))
    }

    @Test("The model is not encoded into the body, which the API would reject")
    func omitsModelFromBody() throws {
        let data = try JSONEncoder().encode(Self.makeRequest(model: "gemini-2.5-pro"))
        let json = try #require(
            try JSONSerialization.jsonObject(with: data) as? [String: Any]
        )

        #expect(json["model"] == nil)
        #expect(json["contents"] != nil)
        #expect(json["systemInstruction"] != nil)
    }

    @Test("A session with no instructions omits systemInstruction rather than sending it empty")
    func omitsAbsentSystemInstruction() throws {
        let request = GeminiGenerateRequest(
            model: "gemini-2.5-flash",
            contents: [GeminiContent(role: .user, text: "hi")],
            systemInstruction: nil,
            generationConfig: GeminiGenerationConfig(maxOutputTokens: 64)
        )
        let data = try JSONEncoder().encode(request)
        let json = try #require(
            try JSONSerialization.jsonObject(with: data) as? [String: Any]
        )

        // The API rejects an empty `parts` array, so the field has
        // to be absent rather than blank.
        #expect(json["systemInstruction"] == nil)
    }

    @Test("The assistant role is spelled `model` on the wire, not `assistant`")
    func encodesAssistantRoleAsModel() throws {
        let request = GeminiGenerateRequest(
            model: "gemini-2.5-flash",
            contents: [GeminiContent(role: .model, text: "prior answer")],
            generationConfig: GeminiGenerationConfig(maxOutputTokens: 64)
        )
        let json = try #require(String(data: try JSONEncoder().encode(request), encoding: .utf8))
        #expect(json.contains("\"role\":\"model\""))
        #expect(!json.contains("assistant"))
    }
}
