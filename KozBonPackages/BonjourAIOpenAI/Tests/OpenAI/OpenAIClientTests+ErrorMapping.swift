//
//  OpenAIClientTests+ErrorMapping.swift
//  BonjourAIOpenAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourAICore
@testable import BonjourAIOpenAI

// MARK: - OpenAIClientTests · HTTP Error Mapping

/// HTTP-status → ``AICloudError`` routing for ``OpenAIClient``.
///
/// The mapping decides which remediation the chat surface offers.
/// OpenAI's sharp edge is 429, which means either "slow down" or
/// "out of credit" depending on the error code.
///
/// An extension rather than a second `@Suite` so it shares the
/// serialized suite's `StubURLProtocol` slot.
extension OpenAIClientTests {

    // MARK: - Helpers

    private static func errorBody(_ message: String, code: String? = nil) -> Data {
        let codeJSON = code.map { #""\#($0)""# } ?? "null"
        return Data(#"{"error":{"message":"\#(message)","type":"x","param":null,"code":\#(codeJSON)}}"#.utf8)
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
                apiKey: "sk-test"
            ) {}
            return nil
        } catch {
            return error
        }
    }

    // MARK: - Credentials and Permissions

    @Test("401 maps to invalid credentials")
    func mapsUnauthorized() async throws {
        let error = try #require(
            await Self.failure(statusCode: 401, body: Self.errorBody("Incorrect API key", code: "invalid_api_key"))
        )
        #expect(error as? AICloudError == .invalidCredentials(provider: .openai))
    }

    @Test("403 maps to a permission problem")
    func mapsForbidden() async throws {
        let error = try #require(
            await Self.failure(
                statusCode: 403,
                body: Self.errorBody("Country not supported", code: "unsupported_country_region_territory")
            )
        )
        guard case .permissionDenied(let provider, _)? = error as? AICloudError else {
            Issue.record("Expected permissionDenied, got \(error)")
            return
        }
        #expect(provider == .openai)
    }

    // MARK: - 429

    @Test("A quota 429 routes to billing, since waiting won't clear it")
    func mapsInsufficientQuotaToBilling() async throws {
        let error = try #require(
            await Self.failure(
                statusCode: 429,
                body: Self.errorBody("You exceeded your current quota", code: "insufficient_quota")
            )
        )
        guard case .creditBalanceTooLow(let provider, _)? = error as? AICloudError else {
            Issue.record("Expected creditBalanceTooLow, got \(error)")
            return
        }
        #expect(provider == .openai)
    }

    @Test("A rate-limit 429 carries Retry-After through when it's numeric")
    func mapsRateLimitWithRetryAfter() async throws {
        let error = try #require(
            await Self.failure(
                statusCode: 429,
                body: Self.errorBody("Rate limit reached", code: "rate_limit_exceeded"),
                headers: ["Retry-After": "7"]
            )
        )
        #expect(error as? AICloudError == .rateLimited(provider: .openai, retryAfterSeconds: 7))
    }

    // MARK: - Outages

    @Test("503 is an overload, split from generic 5xx so the banner can link a status page")
    func mapsOverloaded() async throws {
        let error = try #require(await Self.failure(statusCode: 503, body: Self.errorBody("overloaded")))
        guard case .serviceOverloaded(let provider, _)? = error as? AICloudError else {
            Issue.record("Expected serviceOverloaded, got \(error)")
            return
        }
        #expect(provider == .openai)
    }

    @Test("500 is a plain server error")
    func mapsServerError() async throws {
        let error = try #require(await Self.failure(statusCode: 500, body: Self.errorBody("boom")))
        #expect(error as? AICloudError == .serverError(provider: .openai, message: "boom"))
    }

    // MARK: - 400

    @Test("A context-length 400 maps to the context-window case, which offers Clear Chat")
    func mapsContextWindowExceeded() async throws {
        let error = try #require(
            await Self.failure(
                statusCode: 400,
                body: Self.errorBody("Input is too long.", code: "context_length_exceeded")
            )
        )
        guard case .contextWindowExceeded(let provider, _)? = error as? AICloudError else {
            Issue.record("Expected contextWindowExceeded, got \(error)")
            return
        }
        #expect(provider == .openai)
    }

    @Test("An unknown model 404 stays an invalid request with the server's wording")
    func mapsUnknownModel() async throws {
        let message = "The model `gpt-9` does not exist or you do not have access to it."
        let error = try #require(
            await Self.failure(statusCode: 404, body: Self.errorBody(message, code: "model_not_found"))
        )
        #expect(error as? AICloudError == .invalidRequest(provider: .openai, message: message))
    }

    @Test("An unexpected status falls through to the catch-all")
    func mapsUnexpectedStatus() async throws {
        let error = try #require(await Self.failure(statusCode: 302, body: Data()))
        #expect(error as? AICloudError == .unexpectedStatus(provider: .openai, statusCode: 302))
    }
}
