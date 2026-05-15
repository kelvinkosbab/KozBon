//
//  GitHubBonjourServiceExplainerTests.swift
//  BonjourAIGitHub
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourAI
import BonjourCore
import BonjourModels
import BonjourAICore
@testable import BonjourAIGitHub

// MARK: - GitHubBonjourServiceExplainerTests

@Suite("GitHubBonjourServiceExplainer")
@MainActor
struct GitHubBonjourServiceExplainerTests {

    // MARK: - Helpers

    private func makeExplainer(
        client: MockGitHubModelsClient,
        seededKey: String? = "ghp_test_token_1234"
    ) -> GitHubBonjourServiceExplainer {
        let store = InMemoryAICloudCredentialsStore(
            seed: seededKey.map { [.github: $0] } ?? [:]
        )
        return GitHubBonjourServiceExplainer(
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

    @Test("`isAvailable` is true when a PAT is configured")
    func availabilityFollowsCredentials() {
        let clientWithKey = MockGitHubModelsClient()
        let explainerWithKey = makeExplainer(client: clientWithKey, seededKey: "ghp_x")
        #expect(explainerWithKey.isAvailable)

        let clientWithoutKey = MockGitHubModelsClient()
        let explainerWithoutKey = makeExplainer(client: clientWithoutKey, seededKey: nil)
        #expect(!explainerWithoutKey.isAvailable)
    }

    // MARK: - Streaming

    @Test("Service explanation accumulates streamed chunks")
    func serviceExplanationStreams() async throws {
        let client = MockGitHubModelsClient(chunks: ["This ", "is ", "an HTTP server."])
        let explainer = makeExplainer(client: client)

        await explainer.explain(service: makeService(), isPublished: false)

        #expect(explainer.explanation == "This is an HTTP server.")
        #expect(!explainer.isGenerating)
        #expect(explainer.error == nil)
    }

    @Test("Service-type explanation accumulates streamed chunks")
    func serviceTypeExplanationStreams() async throws {
        let client = MockGitHubModelsClient(chunks: ["AirPlay ", "streams audio and video."])
        let explainer = makeExplainer(client: client)

        await explainer.explain(serviceType: makeServiceType())

        #expect(explainer.explanation == "AirPlay streams audio and video.")
        #expect(!explainer.isGenerating)
        #expect(explainer.error == nil)
    }

    @Test("New explanation request clears the previous explanation text")
    func newRequestClearsPriorExplanation() async throws {
        let client = MockGitHubModelsClient(chunks: ["First."])
        let explainer = makeExplainer(client: client)

        await explainer.explain(serviceType: makeServiceType())
        #expect(explainer.explanation == "First.")

        await explainer.explain(serviceType: makeServiceType())
        #expect(explainer.explanation == "First.")
    }

    // MARK: - Request Shape

    @Test("Request carries a leading `role: system` message followed by the user prompt")
    func sendsSystemAndUserMessages() async throws {
        let client = MockGitHubModelsClient(chunks: ["ok"])
        let explainer = makeExplainer(client: client)

        await explainer.explain(serviceType: makeServiceType())

        let request = try #require(client.recordedRequests.first?.request)
        #expect(request.messages.count == 2)
        #expect(request.messages[0].role == .system)
        #expect(request.messages[1].role == .user)
    }

    @Test("Hardcoded `gpt-4o` model identifier reaches the request")
    func sendsHardcodedModel() async throws {
        let client = MockGitHubModelsClient(chunks: ["ok"])
        let explainer = makeExplainer(client: client)

        await explainer.explain(serviceType: makeServiceType())

        let request = try #require(client.recordedRequests.first?.request)
        #expect(request.model == "gpt-4o")
    }

    // MARK: - Missing Credentials

    @Test("Missing PAT surfaces an error and skips the request")
    func missingKeyShortCircuits() async {
        let client = MockGitHubModelsClient(chunks: ["should-not-be-sent"])
        let explainer = makeExplainer(client: client, seededKey: nil)

        await explainer.explain(serviceType: makeServiceType())

        #expect(explainer.error != nil)
        #expect(explainer.explanation.isEmpty)
        #expect(client.recordedRequests.isEmpty)
    }

    // MARK: - Stream Errors

    @Test("Stream errors surface on `error` and keep partial content")
    func streamErrorRetainsPartialContent() async throws {
        let client = MockGitHubModelsClient(
            chunks: ["partial-text-"],
            error: AICloudError.serverError(provider: .github, message: "overloaded")
        )
        let explainer = makeExplainer(client: client)

        await explainer.explain(serviceType: makeServiceType())

        #expect(explainer.error != nil)
        #expect(explainer.explanation == "partial-text-")
    }
}
