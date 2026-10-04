//
//  OpenAIClientTests.swift
//  BonjourAIOpenAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourAICore
@testable import BonjourAIOpenAI

// MARK: - OpenAIClientTests

/// Exercises ``OpenAIClient`` against a `URLProtocol` stub — no
/// network, no key, deterministic bytes.
///
/// `.serialized` because `StubURLProtocol.handler` is a single
/// static slot shared by every test in this suite.
@Suite("OpenAIClient", .serialized)
struct OpenAIClientTests {

    // MARK: - Helpers
    //
    // Not `private`: the error-mapping extension lives in its own
    // file.

    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    static func makeClient(session: URLSession) -> OpenAIClient {
        OpenAIClient(
            configuration: OpenAIConfiguration(
                baseURL: URL(string: "https://openai.invalid").unsafelyUnwrapped
            ),
            urlSession: session
        )
    }

    static func makeRequest(model: String = "gpt-5.4-mini") -> OpenAIResponseRequest {
        OpenAIResponseRequest.make(
            model: model,
            instructions: "be brief",
            input: [OpenAIInputMessage(role: .user, content: "hi")],
            maxOutputTokens: 64
        )
    }

    /// Frames the payloads the way the API does: an `event:` line
    /// repeating the type, then the `data:` line.
    static func sse(_ payloads: [String]) -> Data {
        Data(payloads.map { "event: x\ndata: \($0)\n\n" }.joined().utf8)
    }

    static func delta(_ text: String) -> String {
        #"{"type":"response.output_text.delta","delta":"\#(text)"}"#
    }

    static let completed = #"{"type":"response.completed","response":{"status":"completed"}}"#

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

    @Test("Text deltas stream through in order, ignoring bookkeeping events")
    func streamsTextInOrder() async throws {
        StubURLProtocol.handler = { _ in
            .success(statusCode: 200, body: Self.sse([
                #"{"type":"response.created","response":{}}"#,
                Self.delta("Hel"),
                Self.delta("lo"),
                Self.completed
            ]))
        }
        defer { StubURLProtocol.handler = nil }

        let text = try await Self.collect(
            Self.makeClient(session: Self.makeSession())
                .streamMessage(request: Self.makeRequest(), apiKey: "sk-test")
        )
        #expect(text == "Hello")
    }

    @Test("`response.completed` ends the stream, so trailing frames are ignored")
    func stopsAtCompleted() async throws {
        StubURLProtocol.handler = { _ in
            .success(statusCode: 200, body: Self.sse([
                Self.delta("done"),
                Self.completed,
                Self.delta("IGNORED")
            ]))
        }
        defer { StubURLProtocol.handler = nil }

        let text = try await Self.collect(
            Self.makeClient(session: Self.makeSession())
                .streamMessage(request: Self.makeRequest(), apiKey: "sk-test")
        )
        #expect(text == "done")
    }

    @Test("An incomplete response after some text keeps the partial answer")
    func incompleteAfterTextFinishesNormally() async throws {
        StubURLProtocol.handler = { _ in
            .success(statusCode: 200, body: Self.sse([
                Self.delta("partial"),
                #"{"type":"response.incomplete","response":{"incomplete_details":{"reason":"max_output_tokens"}}}"#
            ]))
        }
        defer { StubURLProtocol.handler = nil }

        let text = try await Self.collect(
            Self.makeClient(session: Self.makeSession())
                .streamMessage(request: Self.makeRequest(), apiKey: "sk-test")
        )
        #expect(text == "partial")
    }

    @Test("An incomplete response with no text throws rather than ending silently")
    func incompleteWithoutTextThrows() async {
        // A reasoning model can spend its whole budget thinking.
        // Finishing normally would make the chat roll the turn back
        // with no explanation.
        StubURLProtocol.handler = { _ in
            .success(statusCode: 200, body: Self.sse([
                #"{"type":"response.incomplete","response":{"incomplete_details":{"reason":"max_output_tokens"}}}"#
            ]))
        }
        defer { StubURLProtocol.handler = nil }

        await #expect(throws: AICloudError.self) {
            _ = try await Self.collect(
                Self.makeClient(session: Self.makeSession())
                    .streamMessage(request: Self.makeRequest(), apiKey: "sk-test")
            )
        }
    }

    @Test("A failed response surfaces as a server error")
    func failedResponseThrows() async {
        StubURLProtocol.handler = { _ in
            .success(statusCode: 200, body: Self.sse([
                #"{"type":"response.failed","response":{"error":{"code":"server_error","message":"boom"}}}"#
            ]))
        }
        defer { StubURLProtocol.handler = nil }

        await #expect(throws: AICloudError.serverError(provider: .openai, message: "boom")) {
            _ = try await Self.collect(
                Self.makeClient(session: Self.makeSession())
                    .streamMessage(request: Self.makeRequest(), apiKey: "sk-test")
            )
        }
    }

    // MARK: - Request Shape

    @Test("The request posts to /v1/responses with a bearer token")
    func buildsResponsesRequest() async throws {
        let captured = CapturedRequest()
        StubURLProtocol.handler = { request in
            captured.set(request)
            return .success(statusCode: 200, body: Self.sse([Self.completed]))
        }
        defer { StubURLProtocol.handler = nil }

        _ = try await Self.collect(
            Self.makeClient(session: Self.makeSession())
                .streamMessage(request: Self.makeRequest(), apiKey: "sk-SECRET")
        )

        let request = try #require(captured.value)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/v1/responses")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer sk-SECRET")
        let url = try #require(request.url?.absoluteString)
        #expect(!url.contains("sk-SECRET"))
    }

    @Test("The body streams, opts out of server-side storage, and uses snake_case limits")
    func encodesBody() throws {
        let data = try JSONEncoder().encode(Self.makeRequest())
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(json["model"] as? String == "gpt-5.4-mini")
        #expect(json["instructions"] as? String == "be brief")
        #expect(json["stream"] as? Bool == true)
        // KozBon replays its own history, so a stored copy at
        // OpenAI would be retention with no benefit.
        #expect(json["store"] as? Bool == false)
        #expect(json["max_output_tokens"] as? Int == 64)
    }

    @Test("A request with no instructions omits the field rather than sending it blank")
    func omitsAbsentInstructions() throws {
        let request = OpenAIResponseRequest(
            model: "gpt-5.4-mini",
            instructions: nil,
            input: [OpenAIInputMessage(role: .user, content: "hi")],
            maxOutputTokens: 64
        )
        let data = try JSONEncoder().encode(request)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(json["instructions"] == nil)
        #expect(json["reasoning"] == nil)
    }

    @Test("Prior answers are sent with the `assistant` role")
    func encodesAssistantRole() throws {
        let message = OpenAIInputMessage(role: .assistant, content: "prior answer")
        let json = try #require(String(data: try JSONEncoder().encode(message), encoding: .utf8))
        #expect(json.contains(#""role":"assistant""#))
    }

    // MARK: - Reasoning

    @Test(
        "Reasoning families get low effort",
        arguments: ["gpt-5.4-mini", "gpt-6-astra", "o4-mini", "o3"]
    )
    func reasoningModelsGetLowEffort(model: String) {
        #expect(OpenAIReasoning.forModel(model) == OpenAIReasoning(effort: "low"))
    }

    @Test(
        "Models that reject the reasoning parameter don't receive it",
        arguments: ["gpt-4.1", "gpt-4o", "gpt-5.2-chat-latest", "gpt-5-pro", "some-future-model"]
    )
    func otherModelsOmitReasoning(model: String) {
        // Sending an unsupported parameter fails the whole request.
        #expect(OpenAIReasoning.forModel(model) == nil)
    }
}
