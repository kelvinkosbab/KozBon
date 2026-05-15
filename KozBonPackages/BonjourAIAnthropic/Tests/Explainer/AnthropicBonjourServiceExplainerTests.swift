//
//  AnthropicBonjourServiceExplainerTests.swift
//  BonjourAIAnthropic
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourAI
import BonjourCore
import BonjourModels
import BonjourAICore
@testable import BonjourAIAnthropic

// MARK: - AnthropicBonjourServiceExplainerTests

@Suite("AnthropicBonjourServiceExplainer")
@MainActor
struct AnthropicBonjourServiceExplainerTests {

    // MARK: - Helpers

    private func makeExplainer(
        client: MockAnthropicClient,
        seededKey: String? = "sk-ant-test-key-1234"
    ) -> AnthropicBonjourServiceExplainer {
        let store = InMemoryAICloudCredentialsStore(
            seed: seededKey.map { [.anthropic: $0] } ?? [:]
        )
        return AnthropicBonjourServiceExplainer(
            client: client,
            credentialsStore: store
        )
    }

    private func makeService() -> BonjourService {
        let serviceType = BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp)
        let netService = NetService(domain: "local.", type: serviceType.fullType, name: "Test Device", port: 80)
        return BonjourService(service: netService, serviceType: serviceType)
    }

    private func makeServiceType() -> BonjourServiceType {
        BonjourServiceType(name: "AirPlay", type: "airplay", transportLayer: .tcp)
    }

    // MARK: - Availability

    @Test("`isAvailable` is true when a key is configured")
    func availabilityFollowsCredentials() {
        let clientWithKey = MockAnthropicClient()
        let explainerWithKey = makeExplainer(client: clientWithKey, seededKey: "sk-ant-x")
        #expect(explainerWithKey.isAvailable)

        let clientWithoutKey = MockAnthropicClient()
        let explainerWithoutKey = makeExplainer(client: clientWithoutKey, seededKey: nil)
        #expect(!explainerWithoutKey.isAvailable)
    }

    // MARK: - Streaming

    @Test("Service explanation accumulates streamed chunks")
    func serviceExplanationStreams() async throws {
        let client = MockAnthropicClient(chunks: ["This ", "is ", "an HTTP server."])
        let explainer = makeExplainer(client: client)

        await explainer.explain(service: makeService(), isPublished: false)

        #expect(explainer.explanation == "This is an HTTP server.")
        #expect(!explainer.isGenerating)
        #expect(explainer.error == nil)
    }

    @Test("Service-type explanation accumulates streamed chunks")
    func serviceTypeExplanationStreams() async throws {
        let client = MockAnthropicClient(chunks: ["AirPlay ", "streams audio and video."])
        let explainer = makeExplainer(client: client)

        await explainer.explain(serviceType: makeServiceType())

        #expect(explainer.explanation == "AirPlay streams audio and video.")
        #expect(!explainer.isGenerating)
        #expect(explainer.error == nil)
    }

    @Test("New explanation request clears the previous explanation text")
    func newRequestClearsPriorExplanation() async throws {
        let client = MockAnthropicClient(chunks: ["First."])
        let explainer = makeExplainer(client: client)

        await explainer.explain(serviceType: makeServiceType())
        #expect(explainer.explanation == "First.")

        // Same mock yields the same chunks every call — `chunks`
        // is `let`. The second call should reset to start fresh,
        // not append onto the first result.
        await explainer.explain(serviceType: makeServiceType())
        #expect(explainer.explanation == "First.")
    }

    // MARK: - Request Shape

    @Test("Request carries a single cached system block")
    func sendsCachedSystemBlock() async throws {
        let client = MockAnthropicClient(chunks: ["ok"])
        let explainer = makeExplainer(client: client)

        await explainer.explain(serviceType: makeServiceType())

        let request = try #require(client.recordedRequests.first?.request)
        #expect(request.system.count == 1)
        #expect(request.system[0].cacheControl == .ephemeral)
    }

    @Test("Selected model identifier reaches the request")
    func sendsSelectedModel() async throws {
        let client = MockAnthropicClient(chunks: ["ok"])
        let explainer = makeExplainer(client: client)
        explainer.selectedModel = .haiku

        await explainer.explain(serviceType: makeServiceType())

        let request = try #require(client.recordedRequests.first?.request)
        #expect(request.model == AnthropicModel.haiku.rawValue)
    }

    @Test("Each explanation is a one-shot request with exactly one user message")
    func oneShotRequest() async throws {
        let client = MockAnthropicClient(chunks: ["ok"])
        let explainer = makeExplainer(client: client)

        await explainer.explain(serviceType: makeServiceType())

        let request = try #require(client.recordedRequests.first?.request)
        #expect(request.messages.count == 1)
        #expect(request.messages[0].role == .user)
    }

    // MARK: - Missing Credentials

    @Test("Missing key surfaces an error and skips the request")
    func missingKeyShortCircuits() async {
        let client = MockAnthropicClient(chunks: ["should-not-be-sent"])
        let explainer = makeExplainer(client: client, seededKey: nil)

        await explainer.explain(serviceType: makeServiceType())

        #expect(explainer.error != nil)
        #expect(explainer.explanation.isEmpty)
        #expect(client.recordedRequests.isEmpty)
    }

    // MARK: - Stream Errors

    @Test("Stream errors surface on `error` and keep partial content")
    func streamErrorRetainsPartialContent() async throws {
        let client = MockAnthropicClient(
            chunks: ["partial-text-"],
            error: AICloudError.serverError(provider: .anthropic, message: "overloaded")
        )
        let explainer = makeExplainer(client: client)

        await explainer.explain(serviceType: makeServiceType())

        #expect(explainer.error != nil)
        // Partial text accumulated before the error throws —
        // matches the on-device explainer's contract.
        #expect(explainer.explanation == "partial-text-")
    }
}
