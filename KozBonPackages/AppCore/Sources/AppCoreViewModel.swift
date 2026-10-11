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
import BonjourAIApple
import BonjourAICore
import BonjourAppIntents
import BonjourModels
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

    /// Which backends the App Store storefront allows. Must be the
    /// instance the routing factories consult, so a storefront
    /// change reaches routing and Settings together.
    public let aiBackendAvailability: AIBackendAvailability

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
    /// Exposed (internal) so `AppCoreScene` can pass it to the
    /// scene-level `AICloudSignInSheet` when the Insights
    /// long-press menu requests a sign-in flow.
    let credentialsStore: (any AICloudCredentialsStore & Sendable)?

    // MARK: - Initialization

    /// - Parameter preferencesStore: Must be the **same instance**
    ///   the factories consult — otherwise Settings writes and
    ///   factory reads split into two SwiftData containers and
    ///   the runtime backend swap stops working. `nil` for tests
    ///   that want a throwaway store; production callers pass the
    ///   shared instance from `AppCoreScene`.
    /// - Parameter aiBackendAvailability: Same sharing rule as
    ///   `preferencesStore`, against the factories' `isBackendOffered`.
    ///   `nil` offers every backend.
    public init(
        dependencies: DependencyContainer,
        explainerFactory: any BonjourServiceExplainerFactoryProtocol,
        chatSessionFactory: any BonjourChatSessionFactoryProtocol,
        credentialsStore: (any AICloudCredentialsStore & Sendable)? = nil,
        preferencesStore: PreferencesStore? = nil,
        aiBackendAvailability: AIBackendAvailability? = nil
    ) {
        self.dependencies = dependencies
        self.chatSessionFactory = chatSessionFactory
        self.explainerFactory = explainerFactory
        self.credentialsStore = credentialsStore
        self.preferencesStore = preferencesStore ?? PreferencesStore()
        self.aiBackendAvailability = aiBackendAvailability ?? AIBackendAvailability()
        self.servicesViewModel = BonjourServicesViewModel(dependencies: dependencies)
        self.explainer = explainerFactory.makeForCurrentEnvironment()
        self.chatSession = chatSessionFactory.makeForCurrentEnvironment(
            publishManager: dependencies.bonjourPublishManager
        )
    }

    // MARK: - Tab Visibility

    /// Whether the Chat tab renders in the root tab bar — true
    /// when AI is enabled AND at least one backend is reachable
    /// (Apple Intelligence available, or a cloud backend usable or
    /// selected — see ``hasCloudChatPath(selectedBackend:credentialsStore:)``).
    public var shouldShowChatTab: Bool {
        guard preferencesStore.aiAnalysisEnabled else { return false }
        if AppleIntelligenceSupport.isDeviceSupported { return true }
        return Self.hasCloudChatPath(
            selectedBackend: preferencesStore.aiBackend,
            credentialsStore: credentialsStore,
            isOffered: { aiBackendAvailability.isOffered($0) }
        )
    }

    /// Whether a cloud backend can carry the Chat tab on hardware
    /// without Apple Intelligence: any live provider has a key (the
    /// routing factory falls back to it), or a cloud backend is
    /// selected, so the in-tab sign-in prompt can surface.
    ///
    /// Enumerates `AIBackend.allCases` rather than naming providers,
    /// so a provider added later is covered without an edit here —
    /// and the retired GitHub token, which has no backend, doesn't
    /// count. Backends the storefront withholds don't count either.
    static func hasCloudChatPath(
        selectedBackend: AIBackend,
        credentialsStore: (any AICloudCredentialsStore)?,
        isOffered: (AIBackend) -> Bool = { _ in true }
    ) -> Bool {
        if selectedBackend.isCloud, isOffered(selectedBackend) { return true }
        guard let credentialsStore else { return false }
        return AIBackend.allCases
            .filter(isOffered)
            .compactMap(\.cloudProvider)
            .contains { credentialsStore.hasAPIKey(for: $0) }
    }

    // MARK: - Tab Selection

    /// Currently-selected top-level tab. Bound to SwiftUI's
    /// `TabView(selection:)` in ``AppCoreScene``. Module-internal
    /// because `TopLevelDestination` itself is internal — the
    /// binding only ever crosses between this view model and the
    /// scene, both of which live in `AppCore`.
    var selectedTab: TopLevelDestination = .bonjour

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

    // MARK: - Siri Actions

    /// Gives the Siri actions the app's publish manager and explainer
    /// factory, and keeps the Discover tab in step with broadcasts they
    /// start or stop.
    public func connect(to bridge: AppIntentsBridge) {
        bridge.publishManager = dependencies.bonjourPublishManager
        bridge.makeExplainer = { [weak self] in
            self?.explainerFactory.makeForCurrentEnvironment()
        }
        bridge.didPublish = { [weak self] service in
            self?.servicesViewModel.recordPublishedService(service)
        }
        bridge.didStopAllBroadcasts = { [weak self] in
            self?.servicesViewModel.removeAllPublishedServices()
        }
    }

    /// Shows the service Open in KozBon asked for: switches to Discover
    /// and selects it, now or once the scan finds it.
    public func handleOpenRequest(from bridge: AppIntentsBridge) {
        guard let request = bridge.consumeOpenRequest() else { return }
        selectedTab = .bonjour
        servicesViewModel.selectService(named: request.name, fullType: request.serviceType)
    }

    // MARK: - Storefront

    /// Follows the App Store storefront for the life of the calling
    /// task. Run from the scene's `.task`.
    public func monitorStorefront() async {
        await aiBackendAvailability.monitorStorefront()
    }

    /// Moves a selection the storefront now withholds back to
    /// ``AIBackend/default`` and rebuilds the sessions, so a
    /// fallback path can't reach a withheld backend either. Called
    /// when the storefront changes.
    public func applyBackendAvailability() {
        if !aiBackendAvailability.isOffered(preferencesStore.aiBackend) {
            preferencesStore.aiBackend = .default
        }
        refreshAIBackend()
    }
}
