//
//  GitHubModelsClientTests+ErrorMapping.swift
//  BonjourAIGitHub
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourAICore
@testable import BonjourAIGitHub

// MARK: - GitHubModelsClientTests · HTTP Error Mapping

/// HTTP-status-code → ``AICloudError`` routing tests for
/// ``GitHubModelsClient.mapHTTPError``.
///
/// Declared as an extension on ``GitHubModelsClientTests`` (not a
/// separate `@Suite`) so the `.serialized` isolation propagates —
/// `StubURLProtocol.handler` is a process-global static and a
/// second suite would race on it.
extension GitHubModelsClientTests {

    // MARK: - Auth (401 / 403)

    @Test("HTTP 401 maps to `.invalidCredentials`")
    func http401MapsToInvalidCredentials() async {
        let session = Self.makeSession { _ in
            .success(
                statusCode: 401,
                body: Data(#"{"error":{"type":"authentication_error","message":"Invalid token"}}"#.utf8)
            )
        }
        let client = GitHubModelsClient(urlSession: session)

        await #expect(
            throws: AICloudError.invalidCredentials(provider: .github),
            performing: {
                for try await _ in client.streamChat(request: makeRequest(), apiKey: "wrong") {}
            }
        )
    }

    @Test("HTTP 403 routes to `.permissionDenied` with the API message")
    func http403RoutesToPermissionDenied() async throws {
        let permissionMessage = "Your account does not have access to gpt-4o."
        let body = #"{"error":{"type":"permission_error","message":"\#(permissionMessage)"}}"#
        let session = Self.makeSession { _ in
            .success(statusCode: 403, body: Data(body.utf8))
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
        case .permissionDenied(let provider, let message):
            #expect(provider == .github)
            #expect(message == permissionMessage)
        default:
            Issue.record("Expected .permissionDenied, got \(unwrapped)")
        }
    }

    // MARK: - Rate Limit & Server Errors

    @Test("HTTP 429 maps to `.rateLimited` with parsed `Retry-After`")
    func http429MapsToRateLimitedWithRetryAfter() async throws {
        // GitHub Models uses 429 for both per-minute rate limits
        // and free-tier quota exhaustion — both surface as
        // `.rateLimited` so the chat banner can render a single
        // remediation.
        let session = Self.makeSession { _ in
            .success(
                statusCode: 429,
                body: Data(#"{"error":{"type":"rate_limit_exceeded","message":"Too many requests"}}"#.utf8),
                headers: ["Retry-After": "60"]
            )
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
        case .rateLimited(let provider, let retry):
            #expect(provider == .github)
            #expect(retry == 60)
        default:
            Issue.record("Expected .rateLimited, got \(unwrapped)")
        }
    }

    @Test("HTTP 5xx maps to `.serverError` carrying the API message")
    func http500MapsToServerError() async throws {
        let session = Self.makeSession { _ in
            .success(
                statusCode: 503,
                body: Data(#"{"error":{"message":"Service unavailable"}}"#.utf8)
            )
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
            #expect(message == "Service unavailable")
        default:
            Issue.record("Expected .serverError, got \(unwrapped)")
        }
    }

    // MARK: - 400 Variants

    @Test("HTTP 400 surfaces as `.invalidRequest` with the API message extracted")
    func http400DefaultRoutesToInvalidRequest() async throws {
        let modelNotFoundMessage = "The model `gpt-99` does not exist"
        let body = #"""
        {"error":{"type":"invalid_request_error","message":"\#(modelNotFoundMessage)"}}
        """#
        let session = Self.makeSession { _ in
            .success(statusCode: 400, body: Data(body.utf8))
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
        case .invalidRequest(let provider, let message):
            #expect(provider == .github)
            #expect(message == modelNotFoundMessage)
        default:
            Issue.record("Expected .invalidRequest, got \(unwrapped)")
        }
    }

    @Test("HTTP 400 with a context-window message routes to `.contextWindowExceeded`")
    func http400WithContextWindowMessageRoutes() async throws {
        // OpenAI's wording is typically "This model's maximum
        // context length is N tokens..." — the detection
        // substrings cover the common shapes.
        let lengthMessage = "This model's maximum context length is 128000 tokens. However, your messages resulted in 200000 tokens."
        let body = #"""
        {"error":{"type":"invalid_request_error","message":"\#(lengthMessage)"}}
        """#
        let session = Self.makeSession { _ in
            .success(statusCode: 400, body: Data(body.utf8))
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
        case .contextWindowExceeded(let provider, let message):
            #expect(provider == .github)
            #expect(message == lengthMessage)
        default:
            Issue.record("Expected .contextWindowExceeded, got \(unwrapped)")
        }
    }
}
