//
//  CloudAwareBonjourServiceExplainerFactoryTests.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import SwiftData
import Testing
import BonjourAI
import BonjourModels
import BonjourStorage
import BonjourAICore
import BonjourAIApple
import BonjourAIAnthropic

// MARK: - StubAppleExplainerFactory

// `@MainActor`-isolated types are implicitly `Sendable`; the
// explicit conformance trips SwiftLint's `redundant_sendable`
// rule. The doc-comment below stays attached to the class so
// it surfaces in Xcode's quick-look.

/// In-memory stand-in for the inner Apple explainer factory.
/// Lets routing tests assert against the routing decision
/// without pulling in `FoundationModels` (which isn't available
/// in test contexts).
@MainActor
final class StubAppleExplainerFactory: BonjourServiceExplainerFactoryProtocol {

    /// What to return from `makeForCurrentEnvironment`. Tests
    /// flip this between a `StubAppleExplainer` and `nil` to
    /// drive both branches of the routing rule.
    var explainerToReturn: (any BonjourServiceExplainerProtocol)?

    init(explainerToReturn: (any BonjourServiceExplainerProtocol)? = nil) {
        self.explainerToReturn = explainerToReturn
    }

    func makeForCurrentEnvironment() -> (any BonjourServiceExplainerProtocol)? {
        explainerToReturn
    }
}

// MARK: - StubAppleExplainer

/// Minimal `BonjourServiceExplainerProtocol` conformance — does
/// nothing real, just exists so the routing factory can return
/// "an Apple explainer" without depending on FoundationModels.
@MainActor
@Observable
final class StubAppleExplainer: BonjourServiceExplainerProtocol {
    var explanation: String = ""
    var isGenerating: Bool = false
    var error: String?
    var isAvailable: Bool { true }
    var expertiseLevel: BonjourServicePromptBuilder.ExpertiseLevel = .basic
    var responseLength: BonjourServicePromptBuilder.ResponseLength = .standard
    func explain(service: BonjourService, isPublished: Bool) async {}
    func explain(serviceType: BonjourServiceType) async {}
}

// MARK: - CloudAwareBonjourServiceExplainerFactoryTests

// Type name shortened from
// `CloudAwareBonjourServiceExplainerFactoryTests` (45 chars,
// over the 40-char `type_name` cap) to a tighter form. The
// `@Suite` label retains the full qualified name so test
// reports stay unambiguous.

/// Routing-decision coverage for the explainer factory. Mirrors
/// the chat factory's test surface — same four-quadrant table of
/// `aiBackend × credentials-present`, plus a model-selection
/// plumbing test. Parity with the chat factory's coverage
/// catches the case where someone fixes one factory and forgets
/// to fix the matching code path in the other.
@Suite("CloudAwareBonjourServiceExplainerFactory")
@MainActor
struct CloudAwareExplainerFactoryTests {

    // MARK: - Helpers

    private func makeStore() throws -> PreferencesStore {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserPreferences.self, configurations: config)
        return PreferencesStore(container: container)
    }

    // MARK: - Apple-Preferred Routing

    @Test("`.appleIntelligence` preference returns the Apple explainer when available")
    func appleRoutesToAppleExplainer() throws {
        let preferencesStore = try makeStore()
        preferencesStore.aiBackend = .appleIntelligence

        let appleExplainer = StubAppleExplainer()
        let appleFactory = StubAppleExplainerFactory(explainerToReturn: appleExplainer)
        let credentialsStore = InMemoryAICloudCredentialsStore(seed: [.anthropic: "sk-ant-test"])
        let factory = CloudAwareBonjourServiceExplainerFactory(
            appleFactory: appleFactory,
            credentialsStore: credentialsStore,
            preferencesStore: preferencesStore,
            client: MockAnthropicClient()
        )

        let explainer = factory.makeForCurrentEnvironment()
        #expect(explainer === appleExplainer)
    }

    @Test("`.appleIntelligence` falls back to Anthropic when Apple isn't available but a key is configured")
    func appleFallsBackToAnthropicWhenIneligibleButSignedIn() throws {
        let preferencesStore = try makeStore()
        preferencesStore.aiBackend = .appleIntelligence

        let appleFactory = StubAppleExplainerFactory(explainerToReturn: nil)
        let credentialsStore = InMemoryAICloudCredentialsStore(seed: [.anthropic: "sk-ant-test"])
        let factory = CloudAwareBonjourServiceExplainerFactory(
            appleFactory: appleFactory,
            credentialsStore: credentialsStore,
            preferencesStore: preferencesStore,
            client: MockAnthropicClient()
        )

        let explainer = factory.makeForCurrentEnvironment()
        #expect(explainer is AnthropicBonjourServiceExplainer)
    }

    // MARK: - Anthropic-Preferred Routing

    @Test("`.anthropic` preference returns the Anthropic explainer when a key is configured")
    func anthropicRoutesToAnthropicExplainer() throws {
        let preferencesStore = try makeStore()
        preferencesStore.aiBackend = .anthropic

        let appleExplainer = StubAppleExplainer()
        let appleFactory = StubAppleExplainerFactory(explainerToReturn: appleExplainer)
        let credentialsStore = InMemoryAICloudCredentialsStore(seed: [.anthropic: "sk-ant-test"])
        let factory = CloudAwareBonjourServiceExplainerFactory(
            appleFactory: appleFactory,
            credentialsStore: credentialsStore,
            preferencesStore: preferencesStore,
            client: MockAnthropicClient()
        )

        let explainer = factory.makeForCurrentEnvironment()
        #expect(explainer is AnthropicBonjourServiceExplainer)
        #expect(!(explainer === appleExplainer))
    }

    @Test("`.anthropic` falls back to the Apple explainer when no key is configured")
    func anthropicFallsBackToAppleWhenNotSignedIn() throws {
        let preferencesStore = try makeStore()
        preferencesStore.aiBackend = .anthropic

        let appleExplainer = StubAppleExplainer()
        let appleFactory = StubAppleExplainerFactory(explainerToReturn: appleExplainer)
        let credentialsStore = InMemoryAICloudCredentialsStore()
        let factory = CloudAwareBonjourServiceExplainerFactory(
            appleFactory: appleFactory,
            credentialsStore: credentialsStore,
            preferencesStore: preferencesStore,
            client: MockAnthropicClient()
        )

        let explainer = factory.makeForCurrentEnvironment()
        #expect(explainer === appleExplainer)
    }

    @Test("Neither backend available returns nil")
    func bothUnavailableReturnsNil() throws {
        let preferencesStore = try makeStore()
        preferencesStore.aiBackend = .anthropic

        let appleFactory = StubAppleExplainerFactory(explainerToReturn: nil)
        let credentialsStore = InMemoryAICloudCredentialsStore()
        let factory = CloudAwareBonjourServiceExplainerFactory(
            appleFactory: appleFactory,
            credentialsStore: credentialsStore,
            preferencesStore: preferencesStore,
            client: MockAnthropicClient()
        )

        let explainer = factory.makeForCurrentEnvironment()
        #expect(explainer == nil)
    }

    // MARK: - Model Selection Plumbing

    @Test("Anthropic explainer inherits the selected Claude model from preferences")
    func selectedModelFromPreferencesReachesExplainer() throws {
        let preferencesStore = try makeStore()
        preferencesStore.aiBackend = .anthropic
        preferencesStore.aiCloudModel = .haiku

        let credentialsStore = InMemoryAICloudCredentialsStore(seed: [.anthropic: "sk-ant-test"])
        let factory = CloudAwareBonjourServiceExplainerFactory(
            appleFactory: StubAppleExplainerFactory(),
            credentialsStore: credentialsStore,
            preferencesStore: preferencesStore,
            client: MockAnthropicClient()
        )

        let explainer = factory.makeForCurrentEnvironment()
        let anthropic = try #require(explainer as? AnthropicBonjourServiceExplainer)
        #expect(anthropic.selectedModel == .haiku)
    }
}
