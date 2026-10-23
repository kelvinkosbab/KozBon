//
//  BonjourChatViewModelConnectivityTests.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Testing
import SwiftData
import BonjourAI
import BonjourLocalization
import BonjourScanning
import BonjourStorage
import InternetConnectivity
@testable import BonjourUI

// MARK: - BonjourChatViewModelConnectivityTests

/// The chat pauses a cloud session while offline and never pauses
/// the on-device one.
@Suite("BonjourChatViewModel connectivity")
@MainActor
struct BonjourChatViewModelConnectivityTests {

    // MARK: - Helpers

    private func makeViewModel() -> BonjourChatViewModel {
        let services = BonjourServicesViewModel(
            serviceScanner: MockBonjourServiceScanner(),
            publishManager: MockBonjourPublishManager(),
            localNetworkMonitor: MockLocalNetworkMonitor()
        )
        return BonjourChatViewModel(services: services)
    }

    private func makeCloudSession() -> MockBonjourChatSession {
        let session = MockBonjourChatSession()
        session.connectivityRequirement = .internet
        return session
    }

    /// In-memory so it can't leak into other suites' on-disk store.
    private func makePreferencesStore() throws -> PreferencesStore {
        let container = try ModelContainer(
            for: UserPreferences.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return PreferencesStore(container: container)
    }

    // MARK: - isOffline

    @Test("A cloud session is offline only without a connection")
    func cloudSessionOffline() {
        let session = makeCloudSession()
        #expect(BonjourChatViewModel.isOffline(session: session, isConnected: false))
        #expect(!BonjourChatViewModel.isOffline(session: session, isConnected: true))
    }

    @Test("The on-device session is never offline")
    func onDeviceSessionNeverOffline() {
        let session = MockBonjourChatSession()
        #expect(!BonjourChatViewModel.isOffline(session: session, isConnected: false))
    }

    // MARK: - Send Gating

    @Test("Send is disabled offline even with a message typed")
    func sendDisabledOffline() {
        let viewModel = makeViewModel()
        viewModel.inputText = "Hello"
        #expect(viewModel.sendDisabled(session: makeCloudSession(), isOffline: true))
    }

    @Test("The Send hint explains the offline state")
    func sendHintOffline() {
        let viewModel = makeViewModel()
        viewModel.inputText = "Hello"
        let hint = viewModel.sendButtonAccessibilityHint(session: makeCloudSession(), isOffline: true)
        #expect(hint == String(localized: Strings.Connectivity.sendOfflineHint))
    }

    @Test("Sending offline keeps the message and doesn't reach the session")
    func sendOfflineKeepsInput() async throws {
        let viewModel = makeViewModel()
        let session = makeCloudSession()
        viewModel.inputText = "Hello"

        await viewModel.sendMessage(
            viewModel.inputText,
            using: session,
            preferencesStore: try makePreferencesStore(),
            reduceMotion: true,
            isOffline: true
        )

        #expect(viewModel.inputText == "Hello")
        #expect(session.sendCallCount == 0)
        #expect(session.appendUserMessageCallCount == 0)
    }

    @Test("Retrying offline doesn't reach the session")
    func retryOfflineIsNoOp() async throws {
        let viewModel = makeViewModel()
        let session = makeCloudSession()
        session.appendUserMessage("Hello")

        await viewModel.retryLastSend(
            using: session,
            preferencesStore: try makePreferencesStore(),
            reduceMotion: true,
            isOffline: true
        )

        #expect(session.sendCallCount == 0)
    }
}
