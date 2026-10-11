//
//  AppCoreViewModelTests.swift
//  AppCore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import SwiftData
import Testing
import BonjourAICore
import BonjourStorage
import BonjourAIApple
import BonjourScanning
@testable import AppCore

// MARK: - AppCoreViewModelTests

/// Pins the `TabView` selection contract on ``AppCoreViewModel``.
/// The property is module-internal and only ever crosses between
/// this view model and `AppCoreScene`, so a regression here
/// surfaces as a tab bar that won't change tabs.
@Suite("AppCoreViewModel")
@MainActor
struct AppCoreViewModelTests {

    // MARK: - Helpers

    private func makeViewModel() -> AppCoreViewModel {
        AppCoreViewModel(
            dependencies: .mock(),
            explainerFactory: TestExplainerFactory(),
            chatSessionFactory: TestChatSessionFactory(),
            credentialsStore: nil,
            preferencesStore: nil
        )
    }

    // MARK: - selectedTab

    @Test("`selectedTab` defaults to `.bonjour`")
    func selectedTabDefaultsToBonjour() {
        #expect(makeViewModel().selectedTab == .bonjour)
    }

    @Test("`selectedTab` is mutable for TabView binding")
    func selectedTabIsMutable() {
        let viewModel = makeViewModel()
        viewModel.selectedTab = .chat
        #expect(viewModel.selectedTab == .chat)
    }

    // MARK: - Chat Tab Without Apple Intelligence

    @Test("A stored key for any cloud provider keeps the Chat tab", arguments: [
        AICloudProvider.anthropic, .gemini, .openai
    ])
    func anyProviderKeyKeepsChatTab(provider: AICloudProvider) {
        // The check once named Anthropic only, hiding the tab from
        // Gemini users on hardware without Apple Intelligence.
        let store = InMemoryAICloudCredentialsStore(seed: [provider: "key"])
        #expect(AppCoreViewModel.hasCloudChatPath(selectedBackend: .appleIntelligence, credentialsStore: store))
    }

    @Test("Selecting a cloud backend keeps the Chat tab so its sign-in prompt can show")
    func selectedCloudBackendKeepsChatTab() {
        let store = InMemoryAICloudCredentialsStore()
        #expect(AppCoreViewModel.hasCloudChatPath(selectedBackend: .openai, credentialsStore: store))
    }

    @Test("Only a retired GitHub token, with Apple Intelligence selected, hides the Chat tab")
    func retiredTokenDoesNotKeepChatTab() {
        let store = InMemoryAICloudCredentialsStore(seed: [.github: "ghp_old"])
        #expect(!AppCoreViewModel.hasCloudChatPath(selectedBackend: .appleIntelligence, credentialsStore: store))
    }

    // MARK: - Storefront Availability

    @Test("A key for a backend the storefront withholds doesn't keep the Chat tab")
    func withheldProviderKeyDoesNotKeepChatTab() {
        let store = InMemoryAICloudCredentialsStore(seed: [.openai: "sk-proj-test"])
        #expect(!AppCoreViewModel.hasCloudChatPath(
            selectedBackend: .appleIntelligence,
            credentialsStore: store,
            isOffered: { $0 != .openai }
        ))
    }

    @Test("A withheld backend left selected doesn't keep the Chat tab")
    func withheldSelectedBackendDoesNotKeepChatTab() {
        #expect(!AppCoreViewModel.hasCloudChatPath(
            selectedBackend: .openai,
            credentialsStore: InMemoryAICloudCredentialsStore(),
            isOffered: { $0 != .openai }
        ))
    }

    @Test("A storefront that withholds the selected backend resets it to the default")
    func applyBackendAvailabilityResetsWithheldSelection() throws {
        let preferencesStore = try makeInMemoryPreferencesStore()
        preferencesStore.aiBackend = .openai
        let viewModel = makeViewModel(
            preferencesStore: preferencesStore,
            storefront: AIBackendAvailability.chinaMainlandStorefront
        )

        viewModel.applyBackendAvailability()

        #expect(preferencesStore.aiBackend == .default)
    }

    @Test("A storefront change keeps a backend it still offers")
    func applyBackendAvailabilityKeepsOfferedSelection() throws {
        let preferencesStore = try makeInMemoryPreferencesStore()
        preferencesStore.aiBackend = .gemini
        let viewModel = makeViewModel(
            preferencesStore: preferencesStore,
            storefront: AIBackendAvailability.chinaMainlandStorefront
        )

        viewModel.applyBackendAvailability()

        #expect(preferencesStore.aiBackend == .gemini)
    }

    private func makeInMemoryPreferencesStore() throws -> PreferencesStore {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserPreferences.self, configurations: config)
        return PreferencesStore(container: container)
    }

    private func makeViewModel(preferencesStore: PreferencesStore, storefront: String) -> AppCoreViewModel {
        AppCoreViewModel(
            dependencies: .mock(),
            explainerFactory: TestExplainerFactory(),
            chatSessionFactory: TestChatSessionFactory(),
            preferencesStore: preferencesStore,
            aiBackendAvailability: AIBackendAvailability(storefrontCountryCode: storefront)
        )
    }
}

// MARK: - Test Doubles

/// Returns no session, covering the chat-unavailable branch the
/// production cloud-aware factory produces on devices with no AI
/// configured. `AppCoreViewModel.init` requires a factory even
/// when the tests never reach the chat path.
private struct TestChatSessionFactory: BonjourChatSessionFactoryProtocol {

    func makeForCurrentEnvironment(
        publishManager: any BonjourPublishManagerProtocol
    ) -> (any BonjourChatSessionProtocol)? {
        nil
    }

    func prewarmIfEnabled(
        session: (any BonjourChatSessionProtocol)?,
        aiAnalysisEnabled: Bool
    ) async {
        // No-op — these tests don't exercise prewarm.
    }
}

/// Stub explainer factory, present only because
/// `AppCoreViewModel.init` requires one.
private struct TestExplainerFactory: BonjourServiceExplainerFactoryProtocol {

    func makeForCurrentEnvironment() -> (any BonjourServiceExplainerProtocol)? {
        nil
    }
}
