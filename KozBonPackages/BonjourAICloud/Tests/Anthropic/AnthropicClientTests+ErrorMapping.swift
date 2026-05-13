//
//  AnthropicClientTests+ErrorMapping.swift
//  BonjourAICloud
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourAICloud

// MARK: - AnthropicClientTests · HTTP Error Mapping

/// HTTP-status-code → ``AICloudError`` routing tests for
/// ``AnthropicClient.mapHTTPError``.
///
/// Declared as an extension on ``AnthropicClientTests`` (not a
/// separate `@Suite`) for two reasons:
/// 1. SwiftLint's `type_body_length` rule measures a single
///    declaration's body; extension bodies don't accumulate
///    toward it, so splitting via extension keeps each file
///    under threshold without inline disables.
/// 2. `StubURLProtocol.handler` is a process-global static.
///    Splitting into a second `@Suite` would let the two suites
///    run in parallel and race on the handler. Keeping
///    everything in the parent's `.serialized` suite preserves
///    test isolation.
extension AnthropicClientTests {

    // MARK: - Auth (401 / 403)

    @Test("HTTP 401 maps to `.invalidCredentials`")
    func http401MapsToInvalidCredentials() async {
        let session = Self.makeSession { _ in
            .success(
                statusCode: 401,
                body: Data(#"{"type":"error","error":{"type":"authentication_error","message":"Invalid API key"}}"#.utf8)
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

    @Test("HTTP 403 routes to `.permissionDenied` with the API message (distinct from `.invalidCredentials`)")
    func http403RoutesToPermissionDenied() async throws {
        // Split from 401 so the chat surface can offer a
        // plan-management action rather than the re-sign-in
        // affordance. 403 means "valid key, no permission for
        // this resource" — typically a model the account's
        // plan tier doesn't include.
        let permissionMessage = "Your plan does not include claude-opus-4-1."
        let body = #"{"type":"error","error":{"type":"permission_error","message":"\#(permissionMessage)"}}"#
        let session = Self.makeSession { _ in
            .success(statusCode: 403, body: Data(body.utf8))
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
        case .permissionDenied(let provider, let message):
            #expect(provider == .anthropic)
            #expect(message == permissionMessage)
        default:
            Issue.record("Expected .permissionDenied, got \(unwrapped)")
        }
    }

    // MARK: - Rate Limit & Server Errors

    @Test("HTTP 429 maps to `.rateLimited` with parsed `Retry-After`")
    func http429MapsToRateLimitedWithRetryAfter() async throws {
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
    func http500MapsToServerError() async throws {
        let session = Self.makeSession { _ in
            .success(
                statusCode: 503,
                body: Data(#"{"error":{"message":"Service unavailable"}}"#.utf8)
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

    @Test("HTTP 529 routes to `.serviceOverloaded` (distinct from generic 5xx `.serverError`)")
    func http529RoutesToServiceOverloaded() async throws {
        // Anthropic-specific overloaded status. Carved out from
        // generic 5xx so the chat banner can attach a status-page
        // link — users can confirm the outage is wide rather than
        // their request.
        let overloadMessage = "Anthropic API is temporarily overloaded."
        let body = #"{"type":"error","error":{"type":"overloaded_error","message":"\#(overloadMessage)"}}"#
        let session = Self.makeSession { _ in
            .success(statusCode: 529, body: Data(body.utf8))
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
        case .serviceOverloaded(let provider, let message):
            #expect(provider == .anthropic)
            #expect(message == overloadMessage)
        default:
            Issue.record("Expected .serviceOverloaded, got \(unwrapped)")
        }
    }

    // MARK: - 400 Variants

    @Test("HTTP 400 surfaces as `.invalidRequest` with the API message extracted")
    func http400DefaultRoutesToInvalidRequest() async throws {
        // The user-reported regression: a 400 from Anthropic
        // (e.g., "model not found" when a stale identifier
        // ships) was previously collapsed into the bare
        // `.unexpectedStatus(statusCode: 400)` case that
        // dropped the API's explanation on the floor. The new
        // mapping routes 4xx (other than auth / rate-limit) to
        // `.invalidRequest` with the extracted message, so the
        // user sees exactly what Anthropic complained about.
        let modelNotFoundMessage = "model: claude-opus-4-5 not found"
        let body = #"""
        {"type":"error","error":{"type":"invalid_request_error","message":"\#(modelNotFoundMessage)"}}
        """#
        let session = Self.makeSession { _ in
            .success(statusCode: 400, body: Data(body.utf8))
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
        case .invalidRequest(let provider, let message):
            #expect(provider == .anthropic)
            #expect(message == modelNotFoundMessage)
        default:
            Issue.record("Expected .invalidRequest, got \(unwrapped)")
        }
    }

    @Test("HTTP 400 with a `credit balance` message routes to `.creditBalanceTooLow`")
    func http400WithCreditBalanceRoutes() async throws {
        // Anthropic returns a 400 with an `invalid_request_error`
        // type and a "credit balance is too low" message when an
        // account has no credits / payment method. The mapper
        // detects the message substring (case-insensitive) and
        // routes to the dedicated `.creditBalanceTooLow` case so
        // the chat surface can attach a billing-console deep link
        // — the user-facing fix is account-level, not in-app.
        let lowBalanceMessage = "Your credit balance is too low to access the Anthropic API."
        let body = #"""
        {"type":"error","error":{"type":"invalid_request_error","message":"\#(lowBalanceMessage)"}}
        """#
        let session = Self.makeSession { _ in
            .success(statusCode: 400, body: Data(body.utf8))
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
        case .creditBalanceTooLow(let provider, let message):
            #expect(provider == .anthropic)
            #expect(message?.contains("credit balance is too low") == true)
        default:
            Issue.record("Expected .creditBalanceTooLow, got \(unwrapped)")
        }
    }

    @Test("HTTP 400 with a context-window message routes to `.contextWindowExceeded`")
    func http400WithContextWindowMessageRoutes() async throws {
        // Carved out from `.invalidRequest` so the chat banner
        // can offer a Clear-chat action — the user-facing fix
        // is in-app (truncate the history that put the request
        // over the limit), not anywhere in Anthropic's console.
        let lengthMessage = "prompt is too long: 200000 tokens > 199998 maximum"
        let body = #"""
        {"type":"error","error":{"type":"invalid_request_error","message":"\#(lengthMessage)"}}
        """#
        let session = Self.makeSession { _ in
            .success(statusCode: 400, body: Data(body.utf8))
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
        case .contextWindowExceeded(let provider, let message):
            #expect(provider == .anthropic)
            #expect(message == lengthMessage)
        default:
            Issue.record("Expected .contextWindowExceeded, got \(unwrapped)")
        }
    }
}
