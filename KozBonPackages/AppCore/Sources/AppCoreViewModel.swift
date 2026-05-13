//
//  AppCoreViewModel.swift
//  AppCore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourUI
import BonjourScanning
import BonjourAI
import BonjourAICloud
import BonjourStorage

// MARK: - AppCoreViewModel

/// Owns every app-session-lived dependency the root scene reads —
/// DI container, preferences, AI sessions, the shared services
/// view model. Single instance per app session, held by
/// `AppCoreScene` via `@State`.
@MainActor
@Observable
public final class AppCoreViewModel {

    // MARK: - Long-Lived Dependencies

    public let dependencies: DependencyContainer
    public let preferencesStore: PreferencesStore

    /// AI explainer for long-press Insights. Routed by the
    /// cloud-aware factory; mutable so ``refreshAIBackend()`` can
    /// swap it when the user changes backend in Settings.
    public private(set) var explainer: (any BonjourServiceExplainerProtocol)?

    /// App-wide chat session, same routing + mutability as
    /// ``explainer``. Owned here so it survives tab switches and
    /// can be prewarmed at launch.
    public private(set) var chatSession: (any BonjourChatSessionProtocol)?

    /// Shared between the Discover and Chat tabs because the
    /// underlying `BonjourServiceScanner` only exposes one
    /// `weak var delegate` — two view models would race for the
    /// slot and one tab would silently see zero services.
    public let servicesViewModel: BonjourServicesViewModel

    // MARK: - Injected Factories

    private let chatSessionFactory: any BonjourChatSessionFactoryProtocol
    private let explainerFactory: any BonjourServiceExplainerFactoryProtocol
    private let credentialsStore: (any AICloudCredentialsStore & Sendable)?

    // MARK: - Initialization

    /// - Parameter preferencesStore: Must be the **same instance**
    ///   the factories consult — otherwise Settings writes and
    ///   factory reads split into two SwiftData containers and
    ///   the runtime backend swap stops working. `nil` for tests
    ///   that want a throwaway store; production callers pass the
    ///   shared instance from `AppCoreScene`.
    public init(
        dependencies: DependencyContainer,
        explainerFactory: any BonjourServiceExplainerFactoryProtocol,
        chatSessionFactory: any BonjourChatSessionFactoryProtocol,
        credentialsStore: (any AICloudCredentialsStore & Sendable)? = nil,
        preferencesStore: PreferencesStore? = nil
    ) {
        self.dependencies = dependencies
        self.chatSessionFactory = chatSessionFactory
        self.explainerFactory = explainerFactory
        self.credentialsStore = credentialsStore
        self.preferencesStore = preferencesStore ?? PreferencesStore()
        self.servicesViewModel = BonjourServicesViewModel(dependencies: dependencies)
        self.explainer = explainerFactory.makeForCurrentEnvironment()
        self.chatSession = chatSessionFactory.makeForCurrentEnvironment(
            publishManager: dependencies.bonjourPublishManager
        )
    }

    // MARK: - Tab Visibility

    /// Whether the Chat tab renders in the root tab bar — true
    /// when AI is enabled AND at least one backend is reachable
    /// (Apple Intelligence available, Anthropic key configured,
    /// or the user explicitly selected Anthropic so the in-tab
    /// sign-in prompt can surface).
    public var shouldShowChatTab: Bool {
        guard preferencesStore.aiAnalysisEnabled else { return false }
        if AppleIntelligenceSupport.isDeviceSupported { return true }
        if credentialsStore?.hasAPIKey(for: .anthropic) == true { return true }
        return preferencesStore.aiBackend == .anthropic
    }

    // MARK: - Lifecycle

    /// Eagerly prewarm the chat session at app launch so the
    /// first user prompt streams without paying construction
    /// cost. No-op when the session is `nil` or AI is disabled.
    public func prewarmChatSession() async {
        await chatSessionFactory.prewarmIfEnabled(
            session: chatSession,
            aiAnalysisEnabled: preferencesStore.aiAnalysisEnabled
        )
    }

    /// Recreates the chat session and explainer from current
    /// preferences. Called when the backend / model preference
    /// changes or when credentials are added / removed. Drops
    /// any in-flight conversation — history is meaningless
    /// across providers.
    public func refreshAIBackend() {
        explainer = explainerFactory.makeForCurrentEnvironment()
        chatSession = chatSessionFactory.makeForCurrentEnvironment(
            publishManager: dependencies.bonjourPublishManager
        )
    }
}
