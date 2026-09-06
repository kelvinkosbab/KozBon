//
//  GeminiModelCatalogClientTests.swift
//  BonjourAIGemini
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourAICore
@testable import BonjourAIGemini

// MARK: - GeminiModelCatalogClientTests

/// Pins how the raw `/v1beta/models` payload becomes picker rows.
///
/// The endpoint returns Google's whole lineup — embedding models,
/// image and TTS variants, retrieval helpers — and offering any of
/// those in a chat picker produces a request the API rejects. That
/// filtering, and the `models/` prefix strip, are the two places
/// this can go quietly wrong.
///
/// Uses its own ``StubCatalogURLProtocol`` rather than the
/// streaming suite's stub — see that type for why.
@Suite("GeminiModelCatalogClient", .serialized)
struct GeminiModelCatalogClientTests {

    // MARK: - Helpers

    private static func makeClient() -> GeminiModelCatalogClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubCatalogURLProtocol.self]
        return GeminiModelCatalogClient(
            configuration: GeminiConfiguration(
                baseURL: URL(string: "https://gemini.invalid").unsafelyUnwrapped
            ),
            urlSession: URLSession(configuration: configuration)
        )
    }

    private static let payload = Data(#"""
    {"models":[
      {"name":"models/gemini-2.5-pro","displayName":"Gemini 2.5 Pro",
       "supportedGenerationMethods":["generateContent","countTokens"]},
      {"name":"models/text-embedding-004","displayName":"Text Embedding 004",
       "supportedGenerationMethods":["embedContent"]},
      {"name":"models/gemini-2.5-flash","displayName":"Gemini 2.5 Flash",
       "supportedGenerationMethods":["generateContent"]},
      {"name":"gemini-bare-name","displayName":"Bare Name",
       "supportedGenerationMethods":["generateContent"]},
      {"name":"models/no-methods-listed","displayName":"No Methods"}
    ]}
    """#.utf8)

    // MARK: - Decoding

    @Test("Only models that can hold a conversation are offered")
    func filtersToGenerateContentModels() async throws {
        StubCatalogURLProtocol.handler = { _ in .success(statusCode: 200, body: Self.payload) }
        defer { StubCatalogURLProtocol.handler = nil }

        let options = try await Self.makeClient().listModels(apiKey: "AIzaTEST")

        // The embedding model and the one with no declared methods
        // are both dropped — offering either would produce a
        // request the API rejects.
        #expect(options.map(\.id) == ["gemini-2.5-pro", "gemini-2.5-flash", "gemini-bare-name"])
    }

    @Test("The `models/` prefix is stripped, since preferences and the path want the bare id")
    func stripsModelsPrefix() async throws {
        StubCatalogURLProtocol.handler = { _ in .success(statusCode: 200, body: Self.payload) }
        defer { StubCatalogURLProtocol.handler = nil }

        let options = try await Self.makeClient().listModels(apiKey: "AIzaTEST")
        let prefixed = options.filter { $0.id.hasPrefix("models/") }
        #expect(prefixed.isEmpty)
    }

    @Test("Catalog options are flagged as live, not built-in")
    func marksOptionsAsLive() async throws {
        StubCatalogURLProtocol.handler = { _ in .success(statusCode: 200, body: Self.payload) }
        defer { StubCatalogURLProtocol.handler = nil }

        let options = try await Self.makeClient().listModels(apiKey: "AIzaTEST")
        let noneBuiltIn = options.allSatisfy { !$0.isBuiltIn }
        #expect(noneBuiltIn)
    }

    @Test("A missing display name falls back to the identifier rather than blank")
    func fallsBackToIdentifierForMissingDisplayName() async throws {
        let body = Data(#"""
        {"models":[{"name":"models/gemini-x","supportedGenerationMethods":["generateContent"]}]}
        """#.utf8)
        StubCatalogURLProtocol.handler = { _ in .success(statusCode: 200, body: body) }
        defer { StubCatalogURLProtocol.handler = nil }

        let options = try await Self.makeClient().listModels(apiKey: "AIzaTEST")
        #expect(options.map(\.displayName) == ["gemini-x"])
    }

    // MARK: - Request Shape

    @Test("The key rides in a header, never the query string")
    func sendsKeyAsHeader() async throws {
        let captured = CapturedRequest()
        StubCatalogURLProtocol.handler = { request in
            captured.set(request)
            return .success(statusCode: 200, body: Data(#"{"models":[]}"#.utf8))
        }
        defer { StubCatalogURLProtocol.handler = nil }

        _ = try await Self.makeClient().listModels(apiKey: "AIzaSECRET")

        let request = try #require(captured.value)
        #expect(request.value(forHTTPHeaderField: "x-goog-api-key") == "AIzaSECRET")
        let url = try #require(request.url?.absoluteString)
        #expect(!url.contains("AIzaSECRET"))
    }

    // MARK: - Errors

    @Test("A 403 on a plain listing is treated as a bad key")
    func mapsForbiddenToInvalidCredentials() async {
        StubCatalogURLProtocol.handler = { _ in .success(statusCode: 403, body: Data()) }
        defer { StubCatalogURLProtocol.handler = nil }

        // Listing has no plan-tier dimension, so a 403 here is
        // overwhelmingly a bad key rather than a permission issue.
        await #expect(throws: AICloudError.invalidCredentials(provider: .gemini)) {
            _ = try await Self.makeClient().listModels(apiKey: "AIzaBAD")
        }
    }

    @Test("Malformed JSON surfaces as a decoding failure, not a crash")
    func mapsMalformedBodyToDecodingFailure() async {
        StubCatalogURLProtocol.handler = { _ in
            .success(statusCode: 200, body: Data("{not json".utf8))
        }
        defer { StubCatalogURLProtocol.handler = nil }

        await #expect(throws: AICloudError.self) {
            _ = try await Self.makeClient().listModels(apiKey: "AIzaTEST")
        }
    }
}
