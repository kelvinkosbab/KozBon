//
//  OpenAIModelCatalogClientTests.swift
//  BonjourAIOpenAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourAICore
@testable import BonjourAIOpenAI

// MARK: - OpenAIModelCatalogClientTests

/// Pins how the raw `/v1/models` payload becomes picker rows.
///
/// The endpoint lists every model the key can reach — embedding,
/// speech, image, moderation — with no capability field, so the
/// name-based filter is where this can go quietly wrong.
@Suite("OpenAIModelCatalogClient", .serialized)
struct OpenAIModelCatalogClientTests {

    // MARK: - Helpers

    private static func makeClient() -> OpenAIModelCatalogClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubCatalogURLProtocol.self]
        return OpenAIModelCatalogClient(
            configuration: OpenAIConfiguration(
                baseURL: URL(string: "https://openai.invalid").unsafelyUnwrapped
            ),
            urlSession: URLSession(configuration: configuration)
        )
    }

    private static let payload = Data(#"""
    {"object":"list","data":[
      {"id":"gpt-5.4-mini","object":"model","created":200,"owned_by":"system"},
      {"id":"text-embedding-3-large","object":"model","created":300,"owned_by":"system"},
      {"id":"gpt-6-astra","object":"model","created":400,"owned_by":"system"},
      {"id":"gpt-5.4-mini-2026-03-17","object":"model","created":210,"owned_by":"system"},
      {"id":"gpt-4o-mini-tts","object":"model","created":250,"owned_by":"system"},
      {"id":"o4-mini","object":"model","created":100,"owned_by":"system"},
      {"id":"whisper-1","object":"model","created":50,"owned_by":"system"}
    ]}
    """#.utf8)

    // MARK: - Decoding

    @Test("Only chat models are offered, newest first")
    func filtersAndSortsChatModels() async throws {
        StubCatalogURLProtocol.handler = { _ in .success(statusCode: 200, body: Self.payload) }
        defer { StubCatalogURLProtocol.handler = nil }

        let options = try await Self.makeClient().listModels(apiKey: "sk-test")

        // Embedding, TTS, Whisper, and the dated snapshot are gone.
        #expect(options.map(\.id) == ["gpt-6-astra", "gpt-5.4-mini", "o4-mini"])
        let noneBuiltIn = options.allSatisfy { !$0.isBuiltIn }
        #expect(noneBuiltIn)
    }

    @Test("Display names are derived, since the endpoint returns none")
    func derivesDisplayNames() async throws {
        StubCatalogURLProtocol.handler = { _ in .success(statusCode: 200, body: Self.payload) }
        defer { StubCatalogURLProtocol.handler = nil }

        let options = try await Self.makeClient().listModels(apiKey: "sk-test")
        #expect(options.map(\.displayName) == ["GPT-6 Astra", "GPT-5.4 Mini", "o4-mini"])
    }

    @Test(
        "Specialized and legacy models are filtered out",
        arguments: [
            "gpt-realtime", "gpt-image-2", "gpt-4o-transcribe", "gpt-4o-search-preview",
            "omni-moderation-latest", "gpt-3.5-turbo", "gpt-5.3-codex", "dall-e-3",
            "gpt-4-0613", "babbage-002", "computer-use-preview"
        ]
    )
    func rejectsNonChatModels(identifier: String) {
        #expect(!OpenAIModelCatalogClient.isChatModel(identifier))
    }

    @Test(
        "General chat models pass the filter",
        arguments: ["gpt-6-astra", "gpt-5.6-terra", "gpt-5.4-nano", "gpt-4.1", "o3", "o4-mini"]
    )
    func acceptsChatModels(identifier: String) {
        #expect(OpenAIModelCatalogClient.isChatModel(identifier))
    }

    // MARK: - Request Shape

    @Test("The key rides in a bearer header, never the URL")
    func sendsBearerHeader() async throws {
        let captured = CapturedRequest()
        StubCatalogURLProtocol.handler = { request in
            captured.set(request)
            return .success(statusCode: 200, body: Data(#"{"data":[]}"#.utf8))
        }
        defer { StubCatalogURLProtocol.handler = nil }

        _ = try await Self.makeClient().listModels(apiKey: "sk-SECRET")

        let request = try #require(captured.value)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer sk-SECRET")
        #expect(request.url?.path == "/v1/models")
        let url = try #require(request.url?.absoluteString)
        #expect(!url.contains("sk-SECRET"))
    }

    // MARK: - Errors

    @Test("A 401 on the listing maps to invalid credentials")
    func mapsUnauthorized() async {
        StubCatalogURLProtocol.handler = { _ in .success(statusCode: 401, body: Data()) }
        defer { StubCatalogURLProtocol.handler = nil }

        await #expect(throws: AICloudError.invalidCredentials(provider: .openai)) {
            _ = try await Self.makeClient().listModels(apiKey: "sk-bad")
        }
    }

    @Test("Malformed JSON surfaces as a decoding failure, not a crash")
    func mapsMalformedBodyToDecodingFailure() async {
        StubCatalogURLProtocol.handler = { _ in .success(statusCode: 200, body: Data("{not json".utf8)) }
        defer { StubCatalogURLProtocol.handler = nil }

        await #expect(throws: AICloudError.self) {
            _ = try await Self.makeClient().listModels(apiKey: "sk-test")
        }
    }
}
