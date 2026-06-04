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

    // MARK: - Tab Selection

    /// Currently-selected top-level tab. Bound to SwiftUI's
    /// `TabView(selection:)` in ``AppCoreScene`` so the scene can
    /// observe navigation to the chat tab and clear the unread
    /// badge the moment the user opens it. Module-internal because
    /// `TopLevelDestination` itself is internal — the binding only
    /// ever crosses between this view model and the scene, both of
    /// which live in `AppCore`.
    var selectedTab: TopLevelDestination = .bonjour

    // MARK: - Chat Badge

    /// `id` of the assistant message the user most recently saw —
    /// either because the chat tab was visible when the message
    /// streamed in, or because the user just opened the chat tab.
    /// `nil` when no assistant message has ever been seen (fresh
    /// session, or after `refreshAIBackend()` wipes the
    /// conversation across a backend swap).
    private var lastSeenAssistantMessageID: UUID?

    /// True when the chat session has a completed assistant
    /// message the user hasn't scrolled to the bottom of.
    /// Drives the chat tab's red-dot badge.
    ///
    /// "Seen" means the user physically reached the bottom edge
    /// of the message list — the chat surface's
    /// `.onScrollGeometryChange` observer fires the
    /// ``ChatMessagesSeenAction`` env callback (gated on
    /// `!isGenerating`) which updates
    /// ``lastSeenAssistantMessageID``.
    ///
    /// Suppressed while the session is mid-stream
    /// (`isGenerating == true`) so the badge never flashes for
    /// the empty assistant placeholder that gets appended at
    /// the start of a turn — the placeholder's id is unequal
    /// to whatever id was seen on the previous turn, but the
    /// user obviously can't have "missed" content that hasn't
    /// streamed in yet. The post-stream
    /// `onChange(of: isGenerating)` handler in the chat surface
    /// is the moment we reconcile: if the user is still at the
    /// bottom when the turn finishes, the seen-id snaps to the
    /// just-completed message; if not, the placeholder id
    /// becomes the unread target and the badge lights up.
    var hasUnreadAssistantChatMessage: Bool {
        guard let chatSession, !chatSession.isGenerating else {
            return false
        }
        guard let latestAssistantID = chatSession.messages
            .last(where: { $0.role == .assistant })?.id
        else {
            return false
        }
        return latestAssistantID != lastSeenAssistantMessageID
    }

    /// Records the user as having seen the most recent assistant
    /// message. Called by the scene when the chat tab becomes
    /// selected and whenever a new message lands while it's
    /// already visible.
    func markChatMessagesSeen() {
        lastSeenAssistantMessageID = chatSession?.messages
            .last(where: { $0.role == .assistant })?.id
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
