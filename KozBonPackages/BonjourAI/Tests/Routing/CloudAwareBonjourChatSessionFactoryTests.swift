//
//  CloudAwareBonjourChatSessionFactoryTests.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import SwiftData
import Testing
import BonjourAI
import BonjourScanning
import BonjourStorage
import BonjourAICore
import BonjourAIApple
import BonjourAIAnthropic

// MARK: - StubAppleChatFactory

/// In-memory stand-in for the inner Apple factory. Lets routing
/// tests assert against the routing decision without pulling in
/// `FoundationModels` (which isn't available in test contexts).
@MainActor
final class StubAppleChatFactory: BonjourChatSessionFactoryProtocol, Sendable {

    /// What to return from `makeForCurrentEnvironment`. Tests
    /// flip this between an `InMemoryAppleChatSession` and `nil`
    /// to drive both branches of the routing rule.
    var sessionToReturn: (any BonjourChatSessionProtocol)?

    /// Recorded count of `prewarmIfEnabled` calls — used to
    /// verify the cloud-aware factory delegates correctly when
    /// the active session is the Apple one.
    private(set) var prewarmInvocations = 0

    init(sessionToReturn: (any BonjourChatSessionProtocol)? = nil) {
        self.sessionToReturn = sessionToReturn
    }

    func makeForCurrentEnvironment(
        publishManager: any BonjourPublishManagerProtocol
    ) -> (any BonjourChatSessionProtocol)? {
        sessionToReturn
    }

    func prewarmIfEnabled(
        session: (any BonjourChatSessionProtocol)?,
        aiAnalysisEnabled: Bool
    ) async {
        prewarmInvocations += 1
    }
}

// MARK: - StubAppleChatSession

/// Minimal `BonjourChatSessionProtocol` conformance — does
/// nothing real, just exists so the routing factory can return
/// "an Apple session" without depending on FoundationModels.
@MainActor
@Observable
final class StubAppleChatSession: BonjourChatSessionProtocol {
    var messages: [BonjourChatMessage] = []
    var isGenerating: Bool = false
    var error: String?
    var responseLength: BonjourServicePromptBuilder.ResponseLength = .standard
    let intentBroker = BonjourChatIntentBroker()
    func appendUserMessage(_ text: String) {}
    func send(_ text: String, context: BonjourChatPromptBuilder.ChatContext) async {}
    func appendLocalRejection(userMessage: String, refusalText: String) {}
    func reset() {}
    func restore(messages: [BonjourChatMessage]) {}
}

// MARK: - CloudAwareBonjourChatSessionFactoryTests

@Suite("CloudAwareBonjourChatSessionFactory")
@MainActor
struct CloudAwareBonjourChatSessionFactoryTests {

    // MARK: - Helpers

    private func makeStore() throws -> PreferencesStore {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserPreferences.self, configurations: config)
        return PreferencesStore(container: container)
    }

    // MARK: - Apple-Preferred Routing

    @Test("`.appleIntelligence` preference returns the Apple session when available")
    func appleRoutesToAppleSession() throws {
        let preferencesStore = try makeStore()
        preferencesStore.aiBackend = .appleIntelligence

        let appleSession = StubAppleChatSession()
        let appleFactory = StubAppleChatFactory(sessionToReturn: appleSession)
        let credentialsStore = InMemoryAICloudCredentialsStore(seed: [.anthropic: "sk-ant-test"])
        let factory = CloudAwareBonjourChatSessionFactory(
            appleFactory: appleFactory,
            credentialsStore: credentialsStore,
            preferencesStore: preferencesStore,
            client: MockAnthropicClient()
        )

        let session = factory.makeForCurrentEnvironment(publishManager: MockBonjourPublishManager())
        #expect(session === appleSession)
    }

    @Test("`.appleIntelligence` falls back to Anthropic when Apple isn't available but a key is configured")
    func appleFallsBackToAnthropicWhenIneligibleButSignedIn() throws {
        let preferencesStore = try makeStore()
        preferencesStore.aiBackend = .appleIntelligence

        let appleFactory = StubAppleChatFactory(sessionToReturn: nil)
        let credentialsStore = InMemoryAICloudCredentialsStore(seed: [.anthropic: "sk-ant-test"])
        let factory = CloudAwareBonjourChatSessionFactory(
            appleFactory: appleFactory,
            credentialsStore: credentialsStore,
            preferencesStore: preferencesStore,
            client: MockAnthropicClient()
        )

        let session = factory.makeForCurrentEnvironment(publishManager: MockBonjourPublishManager())
        #expect(session is AnthropicBonjourChatSession)
    }

    // MARK: - Anthropic-Preferred Routing

    @Test("`.anthropic` preference returns the Anthropic session when a key is configured")
    func anthropicRoutesToAnthropicSession() throws {
        let preferencesStore = try makeStore()
        preferencesStore.aiBackend = .anthropic

        let appleSession = StubAppleChatSession()
        let appleFactory = StubAppleChatFactory(sessionToReturn: appleSession)
        let credentialsStore = InMemoryAICloudCredentialsStore(seed: [.anthropic: "sk-ant-test"])
        let factory = CloudAwareBonjourChatSessionFactory(
            appleFactory: appleFactory,
            credentialsStore: credentialsStore,
            preferencesStore: preferencesStore,
            client: MockAnthropicClient()
        )

        let session = factory.makeForCurrentEnvironment(publishManager: MockBonjourPublishManager())
        #expect(session is AnthropicBonjourChatSession)
        #expect(!(session === appleSession))
    }

    @Test("`.anthropic` falls back to the Apple session when no key is configured")
    func anthropicFallsBackToAppleWhenNotSignedIn() throws {
        let preferencesStore = try makeStore()
        preferencesStore.aiBackend = .anthropic

        let appleSession = StubAppleChatSession()
        let appleFactory = StubAppleChatFactory(sessionToReturn: appleSession)
        let credentialsStore = InMemoryAICloudCredentialsStore()
        let factory = CloudAwareBonjourChatSessionFactory(
            appleFactory: appleFactory,
            credentialsStore: credentialsStore,
            preferencesStore: preferencesStore,
            client: MockAnthropicClient()
        )

        let session = factory.makeForCurrentEnvironment(publishManager: MockBonjourPublishManager())
        #expect(session === appleSession)
    }

    @Test("Neither backend available returns nil")
    func bothUnavailableReturnsNil() throws {
        let preferencesStore = try makeStore()
        preferencesStore.aiBackend = .anthropic

        let appleFactory = StubAppleChatFactory(sessionToReturn: nil)
        let credentialsStore = InMemoryAICloudCredentialsStore()
        let factory = CloudAwareBonjourChatSessionFactory(
            appleFactory: appleFactory,
            credentialsStore: credentialsStore,
            preferencesStore: preferencesStore,
            client: MockAnthropicClient()
        )

        let session = factory.makeForCurrentEnvironment(publishManager: MockBonjourPublishManager())
        #expect(session == nil)
    }

    // MARK: - Model Selection Plumbing

    @Test("Anthropic session inherits the selected Claude model from preferences")
    func selectedModelFromPreferencesReachesSession() throws {
        let preferencesStore = try makeStore()
        preferencesStore.aiBackend = .anthropic
        preferencesStore.aiCloudModel = .opus

        let credentialsStore = InMemoryAICloudCredentialsStore(seed: [.anthropic: "sk-ant-test"])
        let factory = CloudAwareBonjourChatSessionFactory(
            appleFactory: StubAppleChatFactory(),
            credentialsStore: credentialsStore,
            preferencesStore: preferencesStore,
            client: MockAnthropicClient()
        )

        let session = factory.makeForCurrentEnvironment(publishManager: MockBonjourPublishManager())
        let anthropic = try #require(session as? AnthropicBonjourChatSession)
        #expect(anthropic.selectedModel == .opus)
    }
}
