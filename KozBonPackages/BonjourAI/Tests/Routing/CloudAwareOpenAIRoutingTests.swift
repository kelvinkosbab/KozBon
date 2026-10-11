//
//  CloudAwareOpenAIRoutingTests.swift
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
import BonjourAIOpenAI

// MARK: - CloudAwareOpenAIRoutingTests

/// Pins the `.openai` branches of both cloud-aware factories. The
/// switches are compiler-enumerated, but which session type each
/// branch builds, and which model slot it reads, are not.
@Suite("CloudAwareFactories · OpenAI")
@MainActor
struct CloudAwareOpenAIRoutingTests {

    // MARK: - Helpers

    private func makeStore() throws -> PreferencesStore {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserPreferences.self, configurations: config)
        return PreferencesStore(container: container)
    }

    private func makeChatFactory(
        preferencesStore: PreferencesStore,
        seed: [AICloudProvider: String],
        appleSession: (any BonjourChatSessionProtocol)? = nil,
        storefront: String? = nil
    ) -> CloudAwareBonjourChatSessionFactory {
        CloudAwareBonjourChatSessionFactory(
            appleFactory: StubAppleChatFactory(sessionToReturn: appleSession),
            credentialsStore: InMemoryAICloudCredentialsStore(seed: seed),
            preferencesStore: preferencesStore,
            openAIClient: MockOpenAIClient(),
            isBackendOffered: { AIBackendAvailability.isOffered($0, inStorefront: storefront) }
        )
    }

    // MARK: - Chat

    @Test("`.openai` with a key returns an OpenAI session carrying the OpenAI model slot")
    func openAIRoutesToOpenAISession() throws {
        let preferencesStore = try makeStore()
        preferencesStore.aiBackend = .openai
        preferencesStore.setAICloudModelIdentifier("gpt-5.4-nano", for: .openai)
        // A Claude choice must not leak into the OpenAI session.
        preferencesStore.setAICloudModelIdentifier("claude-opus-4-1", for: .anthropic)

        let factory = makeChatFactory(
            preferencesStore: preferencesStore,
            seed: [.openai: "sk-proj-test"],
            appleSession: StubAppleChatSession()
        )

        let session = factory.makeForCurrentEnvironment(publishManager: MockBonjourPublishManager())
        let openAI = try #require(session as? OpenAIBonjourChatSession)
        #expect(openAI.selectedModel == "gpt-5.4-nano")
    }

    @Test("`.openai` without a key falls back to the Apple session")
    func openAIFallsBackToAppleWhenNotSignedIn() throws {
        let preferencesStore = try makeStore()
        preferencesStore.aiBackend = .openai
        let appleSession = StubAppleChatSession()

        let factory = makeChatFactory(
            preferencesStore: preferencesStore,
            seed: [:],
            appleSession: appleSession
        )

        let session = factory.makeForCurrentEnvironment(publishManager: MockBonjourPublishManager())
        #expect(session === appleSession)
    }

    @Test("On ineligible hardware with only an OpenAI key, Apple Intelligence falls back to OpenAI")
    func appleFallsBackToOpenAIWhenOnlyOpenAIKeyIsStored() throws {
        let preferencesStore = try makeStore()
        preferencesStore.aiBackend = .appleIntelligence

        let factory = makeChatFactory(preferencesStore: preferencesStore, seed: [.openai: "sk-proj-test"])

        let session = factory.makeForCurrentEnvironment(publishManager: MockBonjourPublishManager())
        #expect(session is OpenAIBonjourChatSession)
    }

    // MARK: - China Mainland Storefront

    @Test("On the China storefront, a selected OpenAI backend with a key routes to Apple")
    func chinaStorefrontNeverRoutesSelectedOpenAI() throws {
        let preferencesStore = try makeStore()
        preferencesStore.aiBackend = .openai
        let appleSession = StubAppleChatSession()

        let factory = makeChatFactory(
            preferencesStore: preferencesStore,
            seed: [.openai: "sk-proj-test"],
            appleSession: appleSession,
            storefront: AIBackendAvailability.chinaMainlandStorefront
        )

        let session = factory.makeForCurrentEnvironment(publishManager: MockBonjourPublishManager())
        #expect(session === appleSession)
    }

    @Test("On the China storefront, ineligible hardware doesn't fall back to OpenAI")
    func chinaStorefrontSkipsOpenAIFallback() throws {
        let preferencesStore = try makeStore()
        preferencesStore.aiBackend = .appleIntelligence

        let factory = makeChatFactory(
            preferencesStore: preferencesStore,
            seed: [.openai: "sk-proj-test"],
            storefront: AIBackendAvailability.chinaMainlandStorefront
        )

        #expect(factory.makeForCurrentEnvironment(publishManager: MockBonjourPublishManager()) == nil)
    }

    @Test("On the China storefront, the explainer doesn't route to OpenAI")
    func chinaStorefrontExplainerSkipsOpenAI() throws {
        let preferencesStore = try makeStore()
        preferencesStore.aiBackend = .openai

        let factory = CloudAwareBonjourServiceExplainerFactory(
            appleFactory: StubAppleExplainerFactory(explainerToReturn: nil),
            credentialsStore: InMemoryAICloudCredentialsStore(seed: [.openai: "sk-proj-test"]),
            preferencesStore: preferencesStore,
            openAIClient: MockOpenAIClient(),
            isBackendOffered: {
                AIBackendAvailability.isOffered($0, inStorefront: AIBackendAvailability.chinaMainlandStorefront)
            }
        )

        #expect(factory.makeForCurrentEnvironment() == nil)
    }

    // MARK: - Explainer

    @Test("`.openai` with a key returns an OpenAI explainer carrying the OpenAI model slot")
    func openAIRoutesToOpenAIExplainer() throws {
        let preferencesStore = try makeStore()
        preferencesStore.aiBackend = .openai
        preferencesStore.setAICloudModelIdentifier("gpt-6-astra", for: .openai)

        let factory = CloudAwareBonjourServiceExplainerFactory(
            appleFactory: StubAppleExplainerFactory(explainerToReturn: StubAppleExplainer()),
            credentialsStore: InMemoryAICloudCredentialsStore(seed: [.openai: "sk-proj-test"]),
            preferencesStore: preferencesStore,
            openAIClient: MockOpenAIClient()
        )

        let explainer = try #require(factory.makeForCurrentEnvironment() as? OpenAIBonjourServiceExplainer)
        #expect(explainer.selectedModel == "gpt-6-astra")
    }
}
