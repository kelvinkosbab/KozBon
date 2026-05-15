//
//  AnthropicClientTests.swift
//  BonjourAIAnthropic
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourAICore
@testable import BonjourAIAnthropic

// MARK: - AnthropicClientTests

/// Integration tests against ``AnthropicClient`` using
/// `URLProtocol` stubs.
///
/// Each test wires a `StubURLProtocol` into a freshly-configured
/// `URLSession` so the real client believes it's talking to
/// `api.anthropic.com` but actually reads canned SSE bytes from
/// memory. No network access required, deterministic, fast.
///
/// Serialized because `URLProtocol` requires a static, process-
/// global handler hook (`StubURLProtocol.handler`). Running these
/// tests in parallel would race on the static slot — one test's
/// 401 stub could service another test's 200-expected request.
/// The runtime cost of serialization is trivial (~10 ms total).
@Suite("AnthropicClient", .serialized)
struct AnthropicClientTests {

    // MARK: - Helpers

    // Helpers are `internal` (no `private`) so the
    // `AnthropicClientTests+ErrorMapping` extension in a sibling
    // file can call them. The split keeps the type body under
    // SwiftLint's `type_body_length` threshold while letting all
    // tests share a single `.serialized` suite — both files'
    // tests run sequentially against the process-global
    // `StubURLProtocol.handler`, so they can't race on it.

    static func makeSession(handler: @escaping @Sendable (URLRequest) -> StubURLProtocol.Response) -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        let session = URLSession(configuration: config)
        StubURLProtocol.handler = handler
        return session
    }

    func makeRequest() -> AnthropicMessageRequest {
        AnthropicMessageRequest(
            model: "claude-sonnet-4-5",
            maxTokens: 128,
            system: [AnthropicSystemBlock(text: "System")],
            messages: [AnthropicMessage(role: .user, content: "Hi")]
        )
    }

    // MARK: - Streaming

    @Test("Successful stream yields decoded text deltas in order")
    func yieldsTextDeltasFromSSE() async throws {
        let sse = """
        event: content_block_delta
        data: {"type": "content_block_delta", "index": 0, "delta": {"type": "text_delta", "text": "Hello"}}

        event: content_block_delta
        data: {"type": "content_block_delta", "index": 0, "delta": {"type": "text_delta", "text": ", world"}}

        event: message_stop
        data: {"type": "message_stop"}

        """

        let session = Self.makeSession { _ in
            .success(statusCode: 200, body: Data(sse.utf8))
        }
        let client = AnthropicClient(urlSession: session)

        var collected: [String] = []
        for try await chunk in client.streamMessage(request: makeRequest(), apiKey: "sk-ant-test") {
            collected.append(chunk)
        }

        #expect(collected == ["Hello", ", world"])
    }

    @Test("Lines without `data:` prefix are skipped without yielding")
    func skipsNonDataLines() async throws {
        let sse = """
        : comment line

        event: ping
        data: {"type": "ping"}

        event: content_block_delta
        data: {"type": "content_block_delta", "delta": {"type": "text_delta", "text": "ok"}}

        data: {"type": "message_stop"}

        """

        let session = Self.makeSession { _ in
            .success(statusCode: 200, body: Data(sse.utf8))
        }
        let client = AnthropicClient(urlSession: session)

        var collected: [String] = []
        for try await chunk in client.streamMessage(request: makeRequest(), apiKey: "k") {
            collected.append(chunk)
        }
        #expect(collected == ["ok"])
    }

    // MARK: - Transport Errors
    //
    // Per-status HTTP-error routing tests live in
    // `AnthropicClientErrorMappingTests` so neither file exceeds
    // SwiftLint's `type_body_length` threshold. This suite covers
    // failure modes that occur *before* the HTTP layer parses a
    // status code — URLSession-level errors (DNS / TLS / no
    // connection) and the inline-SSE error case where the
    // response is a 200 but the stream itself carries an error
    // event.

    @Test("URLSession-level failures route to `.networkUnavailable` so the chat banner can offer Retry")
    func urlSessionErrorRoutesToNetworkUnavailable() async throws {
        // The user is offline / DNS is down / TLS rejected the
        // connection — URLSession surfaces these as `URLError`.
        // The client maps them to the typed
        // ``.networkUnavailable`` so the chat banner can attach
        // a Retry button (in-app action) instead of leaving the
        // user with a generic localized URLError string and no
        // recovery affordance.
        let session = Self.makeSession { _ in
            .failure(URLError(.notConnectedToInternet))
        }
        let client = AnthropicClient(urlSession: session)

        var caught: AICloudError?
        do {
            for try await _ in client.streamMessage(request: makeRequest(), apiKey: "k") {}
        } catch let error as AICloudError {
            caught = error
        }

        #expect(caught == .networkUnavailable)
    }

    // MARK: - Inline Stream Error

    @Test("Inline `error` SSE event throws `.serverError`")
    func inlineErrorEventThrows() async throws {
        let sse = """
        data: {"type": "error", "error": {"type": "overloaded_error", "message": "overloaded"}}

        """

        let session = Self.makeSession { _ in
            .success(statusCode: 200, body: Data(sse.utf8))
        }
        let client = AnthropicClient(urlSession: session)

        var caught: AICloudError?
        do {
            for try await _ in client.streamMessage(request: makeRequest(), apiKey: "k") {}
        } catch let error as AICloudError {
            caught = error
        }

        let unwrapped = try #require(caught)
        switch unwrapped {
        case .serverError(_, let message):
            #expect(message == "overloaded")
        default:
            Issue.record("Expected .serverError, got \(unwrapped)")
        }
    }

    // MARK: - Request Headers

    @Test("Outgoing request carries x-api-key and anthropic-version headers")
    func sendsRequiredHeaders() async throws {
        // The handler captures the request via a Mutex-guarded
        // box. `URLProtocol.handler` is `@Sendable`, so we need
        // a thread-safe container — the regular `var` won't do.
        let captured = CapturedRequest()
        let session = Self.makeSession { request in
            captured.set(request)
            return .success(
                statusCode: 200,
                body: Data("data: {\"type\": \"message_stop\"}\n\n".utf8)
            )
        }
        let client = AnthropicClient(urlSession: session)

        for try await _ in client.streamMessage(request: makeRequest(), apiKey: "sk-ant-cap") {}

        let request = try #require(captured.value)
        #expect(request.value(forHTTPHeaderField: "x-api-key") == "sk-ant-cap")
        #expect(request.value(forHTTPHeaderField: "anthropic-version") == "2023-06-01")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(request.value(forHTTPHeaderField: "Accept") == "text/event-stream")
        // URL path is /v1/messages
        #expect(request.url?.path == "/v1/messages")
    }
}
