//
//  GitHubModelsClientTests.swift
//  BonjourAIGitHub
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourAICore
@testable import BonjourAIGitHub

// MARK: - GitHubModelsClientTests

/// Integration tests against ``GitHubModelsClient`` using
/// `URLProtocol` stubs.
///
/// Each test wires a `StubURLProtocol` into a freshly-configured
/// `URLSession` so the real client believes it's talking to
/// `models.inference.ai.azure.com` but actually reads canned SSE
/// bytes from memory. No network access required, deterministic,
/// fast.
///
/// Serialized because `URLProtocol` requires a static, process-
/// global handler hook (`StubURLProtocol.handler`). Running these
/// tests in parallel would race on the static slot. The runtime
/// cost of serialization is trivial.
@Suite("GitHubModelsClient", .serialized)
struct GitHubModelsClientTests {

    // MARK: - Helpers

    // Helpers are `internal` so the
    // `GitHubModelsClientTests+ErrorMapping` extension in a
    // sibling file can call them. Same pattern Anthropic uses
    // for the same SwiftLint reason.

    static func makeSession(handler: @escaping @Sendable (URLRequest) -> StubURLProtocol.Response) -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        let session = URLSession(configuration: config)
        StubURLProtocol.handler = handler
        return session
    }

    func makeRequest() -> GitHubMessageRequest {
        GitHubMessageRequest(
            model: "gpt-4o",
            messages: [
                GitHubMessage(role: .system, content: "System"),
                GitHubMessage(role: .user, content: "Hi")
            ],
            maxTokens: 128
        )
    }

    // MARK: - Streaming

    @Test("Successful stream yields decoded text deltas in order")
    func yieldsTextDeltasFromSSE() async throws {
        let sse = """
        data: {"choices":[{"delta":{"content":"Hello"}}]}

        data: {"choices":[{"delta":{"content":", world"}}]}

        data: [DONE]

        """

        let session = Self.makeSession { _ in
            .success(statusCode: 200, body: Data(sse.utf8))
        }
        let client = GitHubModelsClient(urlSession: session)

        var collected: [String] = []
        for try await chunk in client.streamChat(request: makeRequest(), apiKey: "ghp_test") {
            collected.append(chunk)
        }

        #expect(collected == ["Hello", ", world"])
    }

    @Test("Empty-delta frames between text frames are skipped without yielding")
    func skipsEmptyDeltaFrames() async throws {
        let sse = """
        data: {"choices":[{"delta":{"role":"assistant"}}]}

        data: {"choices":[{"delta":{"content":"ok"}}]}

        data: [DONE]

        """

        let session = Self.makeSession { _ in
            .success(statusCode: 200, body: Data(sse.utf8))
        }
        let client = GitHubModelsClient(urlSession: session)

        var collected: [String] = []
        for try await chunk in client.streamChat(request: makeRequest(), apiKey: "k") {
            collected.append(chunk)
        }
        #expect(collected == ["ok"])
    }

    @Test("Stream finishes naturally when the server omits the [DONE] sentinel")
    func finishesWithoutSentinel() async throws {
        // Some intermediaries strip `[DONE]`. The client should
        // still terminate cleanly when the bytes stream itself
        // ends — without this, the consumer would hang waiting
        // for a terminator that never arrives.
        let sse = """
        data: {"choices":[{"delta":{"content":"hi"}}]}

        """

        let session = Self.makeSession { _ in
            .success(statusCode: 200, body: Data(sse.utf8))
        }
        let client = GitHubModelsClient(urlSession: session)

        var collected: [String] = []
        for try await chunk in client.streamChat(request: makeRequest(), apiKey: "k") {
            collected.append(chunk)
        }
        #expect(collected == ["hi"])
    }

    // MARK: - Transport Errors

    @Test("URLSession-level failures route to `.networkUnavailable` so the chat banner can offer Retry")
    func urlSessionErrorRoutesToNetworkUnavailable() async throws {
        let session = Self.makeSession { _ in
            .failure(URLError(.notConnectedToInternet))
        }
        let client = GitHubModelsClient(urlSession: session)

        var caught: AICloudError?
        do {
            for try await _ in client.streamChat(request: makeRequest(), apiKey: "k") {}
        } catch let error as AICloudError {
            caught = error
        }

        #expect(caught == .networkUnavailable)
    }

    // MARK: - Inline Stream Error

    @Test("Inline `error` SSE event throws `.serverError`")
    func inlineErrorEventThrows() async throws {
        let sse = """
        data: {"error":{"type":"server_error","message":"overloaded"}}

        """

        let session = Self.makeSession { _ in
            .success(statusCode: 200, body: Data(sse.utf8))
        }
        let client = GitHubModelsClient(urlSession: session)

        var caught: AICloudError?
        do {
            for try await _ in client.streamChat(request: makeRequest(), apiKey: "k") {}
        } catch let error as AICloudError {
            caught = error
        }

        let unwrapped = try #require(caught)
        switch unwrapped {
        case .serverError(let provider, let message):
            #expect(provider == .github)
            #expect(message == "overloaded")
        default:
            Issue.record("Expected .serverError, got \(unwrapped)")
        }
    }

    // MARK: - Request Headers

    @Test("Outgoing request carries Bearer Authorization and the chat-completions path")
    func sendsRequiredHeaders() async throws {
        let captured = CapturedRequest()
        let session = Self.makeSession { request in
            captured.set(request)
            return .success(
                statusCode: 200,
                body: Data("data: [DONE]\n\n".utf8)
            )
        }
        let client = GitHubModelsClient(urlSession: session)

        for try await _ in client.streamChat(request: makeRequest(), apiKey: "ghp_capture") {}

        let request = try #require(captured.value)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer ghp_capture")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(request.value(forHTTPHeaderField: "Accept") == "text/event-stream")
        #expect(request.url?.path == "/chat/completions")
    }
}
