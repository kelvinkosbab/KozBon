//
//  GeminiClientTests+ErrorMapping.swift
//  BonjourAIGemini
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourAICore
@testable import BonjourAIGemini

// MARK: - GeminiClientTests · HTTP Error Mapping

/// HTTP-status-code → ``AICloudError`` routing for
/// ``GeminiClient``.
///
/// The mapping decides which remediation the chat surface offers,
/// so a mis-mapped status is a user-visible dead end rather than a
/// cosmetic issue — Google's overloaded 403 is the sharp edge.
///
/// An extension on ``GeminiClientTests`` rather than a second
/// `@Suite`, for the same two reasons the Anthropic side is:
/// SwiftLint's `type_body_length` measures one declaration's body,
/// and `StubURLProtocol.handler` is a process-global static that
/// two parallel suites would race on. `.serialized` only orders
/// tests *within* a suite.
extension GeminiClientTests {

    // MARK: - Helpers

    private static func errorBody(_ message: String, status: String = "INVALID_ARGUMENT") -> Data {
        Data(#"{"error":{"code":400,"message":"\#(message)","status":"\#(status)"}}"#.utf8)
    }

    /// Runs one request and returns whatever the stream threw.
    private static func failure(
        statusCode: Int,
        body: Data,
        headers: [String: String] = [:]
    ) async -> (any Error)? {
        StubURLProtocol.handler = { _ in
            .success(statusCode: statusCode, body: body, headers: headers)
        }
        defer { StubURLProtocol.handler = nil }

        do {
            for try await _ in makeClient(session: makeSession()).streamMessage(
                request: makeRequest(),
                apiKey: "AIzaTEST"
            ) {}
            return nil
        } catch {
            return error
        }
    }

    // MARK: - Credentials

    @Test("401 maps to invalid credentials")
    func mapsUnauthorized() async throws {
        let error = try #require(await Self.failure(statusCode: 401, body: Self.errorBody("nope")))
        #expect(error as? AICloudError == .invalidCredentials(provider: .gemini))
    }

    @Test("A 403 saying the key is invalid maps to credentials, not permissions")
    func mapsInvalidKey403ToCredentials() async throws {
        // Google returns 403 for both a bad key and a genuine
        // permission problem. Routing this one to permissions
        // would tell the user to check a plan when what they
        // actually need is to re-enter their key.
        let error = try #require(
            await Self.failure(
                statusCode: 403,
                body: Self.errorBody("API key not valid. Please pass a valid API key.")
            )
        )
        #expect(error as? AICloudError == .invalidCredentials(provider: .gemini))
    }

    @Test("A 403 about permissions stays a permission error")
    func mapsPermission403() async throws {
        let error = try #require(
            await Self.failure(
                statusCode: 403,
                body: Self.errorBody("Permission denied on resource project.")
            )
        )
        guard case .permissionDenied(let provider, _)? = error as? AICloudError else {
            Issue.record("Expected permissionDenied, got \(error)")
            return
        }
        #expect(provider == .gemini)
    }

    // MARK: - Throttling and Outages

    @Test("429 carries Retry-After through when it's numeric")
    func mapsRateLimitWithRetryAfter() async throws {
        let error = try #require(
            await Self.failure(
                statusCode: 429,
                body: Self.errorBody("quota"),
                headers: ["Retry-After": "42"]
            )
        )
        #expect(error as? AICloudError == .rateLimited(provider: .gemini, retryAfterSeconds: 42))
    }

    @Test("503 is an overload, split from generic 5xx so the banner can link a status page")
    func mapsOverloaded() async throws {
        let error = try #require(
            await Self.failure(statusCode: 503, body: Self.errorBody("overloaded"))
        )
        guard case .serviceOverloaded(let provider, _)? = error as? AICloudError else {
            Issue.record("Expected serviceOverloaded, got \(error)")
            return
        }
        #expect(provider == .gemini)
    }

    @Test("500 is a plain server error")
    func mapsServerError() async throws {
        let error = try #require(
            await Self.failure(statusCode: 500, body: Self.errorBody("boom"))
        )
        guard case .serverError(let provider, _)? = error as? AICloudError else {
            Issue.record("Expected serverError, got \(error)")
            return
        }
        #expect(provider == .gemini)
    }

    // MARK: - 400 Carve-Outs

    @Test("An over-long prompt maps to the context-window case, which offers Clear Chat")
    func mapsContextWindowExceeded() async throws {
        let error = try #require(
            await Self.failure(
                statusCode: 400,
                body: Self.errorBody("The input token count exceeds the maximum for this model.")
            )
        )
        guard case .contextWindowExceeded(let provider, _)? = error as? AICloudError else {
            Issue.record("Expected contextWindowExceeded, got \(error)")
            return
        }
        #expect(provider == .gemini)
    }

    @Test("A billing 400 routes to the billing remediation, not a generic bad request")
    func mapsBillingProblem() async throws {
        let error = try #require(
            await Self.failure(
                statusCode: 400,
                body: Self.errorBody("Billing account not configured for this project.")
            )
        )
        guard case .creditBalanceTooLow(let provider, _)? = error as? AICloudError else {
            Issue.record("Expected creditBalanceTooLow, got \(error)")
            return
        }
        #expect(provider == .gemini)
    }

    @Test("An unrelated 400 stays a plain invalid request and keeps the server's own wording")
    func mapsOtherBadRequest() async throws {
        let error = try #require(
            await Self.failure(
                statusCode: 400,
                body: Self.errorBody("Unknown field: bogus")
            )
        )
        guard case .invalidRequest(let provider, let message)? = error as? AICloudError else {
            Issue.record("Expected invalidRequest, got \(error)")
            return
        }
        #expect(provider == .gemini)
        // Surfacing the provider's text beats a bare status code.
        #expect(message == "Unknown field: bogus")
    }

    @Test("An unexpected status falls through to the catch-all")
    func mapsUnexpectedStatus() async throws {
        let error = try #require(
            await Self.failure(statusCode: 302, body: Data())
        )
        #expect(
            error as? AICloudError == .unexpectedStatus(provider: .gemini, statusCode: 302)
        )
    }
}
