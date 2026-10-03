//
//  AppCoreViewModelTests.swift
//  AppCore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourAICore
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
