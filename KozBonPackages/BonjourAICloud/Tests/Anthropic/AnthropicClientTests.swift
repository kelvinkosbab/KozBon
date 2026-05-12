//
//  AnthropicClientTests.swift
//  BonjourAICloud
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourAICloud

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

    private static func makeSession(handler: @escaping @Sendable (URLRequest) -> StubURLProtocol.Response) -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        let session = URLSession(configuration: config)
        StubURLProtocol.handler = handler
        return session
    }

    private func makeRequest() -> AnthropicMessageRequest {
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

    // MARK: - HTTP Error Mapping

    @Test("HTTP 401 maps to `.invalidCredentials`")
    func mapsAuthErrorTo401() async {
        let session = Self.makeSession { _ in
            .success(
                statusCode: 401,
                body: Data(#"{"type": "error", "error": {"type": "authentication_error", "message": "Invalid API key"}}"#.utf8)
            )
        }
        let client = AnthropicClient(urlSession: session)

        await #expect(
            throws: AICloudError.invalidCredentials(provider: .anthropic),
            performing: {
                for try await _ in client.streamMessage(request: makeRequest(), apiKey: "wrong") {}
            }
        )
    }

    @Test("HTTP 429 maps to `.rateLimited` with parsed `Retry-After`")
    func mapsRateLimitWithRetryAfter() async throws {
        let session = Self.makeSession { _ in
            .success(
                statusCode: 429,
                body: Data(#"{"type":"error","error":{"type":"rate_limit_error","message":"Too many requests"}}"#.utf8),
                headers: ["Retry-After": "30"]
            )
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
        case .rateLimited(let provider, let retry):
            #expect(provider == .anthropic)
            #expect(retry == 30)
        default:
            Issue.record("Expected .rateLimited, got \(unwrapped)")
        }
    }

    @Test("HTTP 500 maps to `.serverError` carrying the API message")
    func mapsServerError() async throws {
        let session = Self.makeSession { _ in
            .success(
                statusCode: 503,
                body: Data(#"{"error": {"message": "Service unavailable"}}"#.utf8)
            )
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
        case .serverError(let provider, let message):
            #expect(provider == .anthropic)
            #expect(message == "Service unavailable")
        default:
            Issue.record("Expected .serverError, got \(unwrapped)")
        }
    }

    @Test("HTTP 418 (unmapped) surfaces as `.unexpectedStatus`")
    func mapsUnknownStatus() async throws {
        let session = Self.makeSession { _ in
            .success(statusCode: 418, body: Data())
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
        case .unexpectedStatus(let provider, let statusCode):
            #expect(provider == .anthropic)
            #expect(statusCode == 418)
        default:
            Issue.record("Expected .unexpectedStatus, got \(unwrapped)")
        }
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
