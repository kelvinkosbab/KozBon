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

/// View model that owns every app-session-lived dependency the root
/// scene needs.
///
/// `AppCore` itself is a thin presenter — its job is the SwiftUI
/// scene tree (tab definitions, environment injection, the
/// platform-conditional Settings / Window scenes). Everything that
/// isn't structural — DI plumbing, factory wiring, async prewarm,
/// the AI-tab visibility decision — lives here, where it's
/// testable in isolation and not entangled with `@main`'s
/// peculiarities (no runtime args, lifetime tied to the process,
/// can't be `@testable`-imported as easily).
///
/// ## Why a view model
///
/// `AppCore` was previously holding five `@State` properties, two
/// stored factories, a multi-step async `.task`, and a
/// derived-Boolean tab-visibility check inlined twice (once for
/// each iOS-version branch). Per
/// `.claude/rules/mvvm.md`, any one of those triggers extraction;
/// all four at once is over-budget. Pushing them onto an
/// `@MainActor @Observable` class gives `AppCore` a single
/// `@State` slot to own (the view model itself), and the
/// previously-untestable orchestration (prewarm, tab gating)
/// becomes a couple of trivial unit tests.
///
/// ## Lifetime
///
/// Single instance per app session, owned by `AppCore` via
/// `@State`. Survives every tab switch and view rebuild. The
/// scanner delegate slot reasoning in
/// ``BonjourServicesViewModel`` is why we hold exactly one
/// services view model here instead of constructing one per tab.
@MainActor
@Observable
public final class AppCoreViewModel {

    // MARK: - Long-Lived Dependencies

    /// The app's dependency container. Surfaces the Bonjour
    /// scanner, publish manager, and local-network monitor to
    /// every screen via `@Environment(\.dependencies)`.
    public let dependencies: DependencyContainer

    /// SwiftData-backed preferences. Read by Settings, Discover
    /// (default sort), Chat (AI on/off, expertise level), and the
    /// AI-tab visibility check below.
    public let preferencesStore: PreferencesStore

    /// AI explainer that powers long-press Insights.
    ///
    /// Routed by the cloud-aware factory — points at the on-device
    /// Apple explainer when the user has selected Apple
    /// Intelligence (or no Anthropic key is configured), and at
    /// the Anthropic explainer when the user is signed into
    /// Claude and has chosen that backend. `nil` only when
    /// neither path is viable.
    ///
    /// Mutable so the backend can be swapped at runtime via
    /// ``refreshAIBackend()`` when the user flips the picker in
    /// Settings.
    public private(set) var explainer: (any BonjourServiceExplainerProtocol)?

    /// App-wide chat session.
    ///
    /// Routed by the cloud-aware factory — same routing rules as
    /// ``explainer``. Mutable so ``refreshAIBackend()`` can swap
    /// the live session when the user changes the backend
    /// preference; the SwiftUI environment value picks up the
    /// new instance and the chat surface re-renders.
    ///
    /// Owning the session at the app level — instead of letting
    /// `BonjourChatView` construct one on first render — also means
    /// the session survives tab switches without being torn down,
    /// and lets us eagerly call ``prewarmChatSession()`` in a
    /// `.task` on the root scene before the user has navigated
    /// anywhere.
    public private(set) var chatSession: (any BonjourChatSessionProtocol)?

    /// The single, app-wide services view model.
    ///
    /// Must be shared between the Discover and Chat tabs because
    /// `BonjourServiceScanner` exposes one `weak var delegate`. If
    /// each tab created its own view model, the tabs would race to
    /// register themselves as the delegate and one tab would silently
    /// show zero discovered services — see
    /// ``BonjourServicesViewModel`` for the full explanation.
    public let servicesViewModel: BonjourServicesViewModel

    // MARK: - Injected Factories

    /// Factory for the AI chat session. Held as a stored property
    /// so the production default can be swapped (e.g., in a test
    /// harness or a developer-mode build). Kept beyond `init`
    /// because ``prewarmChatSession()`` and ``refreshAIBackend()``
    /// call back into it.
    private let chatSessionFactory: any BonjourChatSessionFactoryProtocol

    /// Factory for the AI service explainer. Same lifetime
    /// reasoning as ``chatSessionFactory`` — held so
    /// ``refreshAIBackend()`` can re-invoke when the user changes
    /// preferences.
    private let explainerFactory: any BonjourServiceExplainerFactoryProtocol

    /// Whether the device fundamentally supports any AI path
    /// (Apple Intelligence available OR a configured Anthropic
    /// key — read fresh inside ``shouldShowChatTab``).
    private let credentialsStore: (any AICloudCredentialsStore & Sendable)?

    // MARK: - Initialization

    /// - Parameters:
    ///   - dependencies: The dependency container that injects the
    ///     scanner, publish manager, and local-network monitor into
    ///     downstream view models.
    ///   - explainerFactory: Factory for the on-device AI explainer.
    ///     Invoked once at init; the resolved value (or `nil` on
    ///     ineligible devices) is stored on ``explainer``.
    ///   - chatSessionFactory: Factory for the on-device AI chat
    ///     session. Invoked once at init for ``chatSession``, and
    ///     again from ``prewarmChatSession()`` for the warmup hook.
    ///   - credentialsStore: Cloud-AI credentials store. Same
    ///     instance that backs the cloud-aware factories; held
    ///     here so the tab-visibility gate can ask "has the user
    ///     signed into Anthropic?" without a second lookup path.
    ///   - preferencesStore: The user-preferences store. Must be
    ///     the same instance the factories consult — otherwise
    ///     Settings writes (which go through this VM's store) and
    ///     factory routing reads (which consult the factory's
    ///     captured store) split into two SwiftData containers
    ///     and the runtime backend swap stops working. Optional
    ///     for tests that want a throwaway store; production
    ///     callers in `AppCoreScene` pass the shared instance.
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

    /// Whether the Chat tab should render in the root tab bar.
    ///
    /// Pre-ADR-0005 the tab gated solely on Apple Intelligence
    /// availability. Now that ADR 0005's pluggable backend ships,
    /// the tab is visible when ANY of these paths is viable:
    ///
    /// 1. Apple Intelligence is technically available on this
    ///    device — covers the original on-device path.
    /// 2. The user has signed into Anthropic and has a key in
    ///    the Keychain — covers users on ineligible hardware who
    ///    want a Chat tab via their own Claude account.
    ///
    /// Plus the user-controlled gate that lets capable users opt
    /// out without uninstalling:
    ///
    /// 3. `preferencesStore.aiAnalysisEnabled` is `true`.
    ///
    /// All three are stable reads at body-evaluation time —
    /// `isDeviceSupported` is a constant per device, `hasAPIKey`
    /// touches the Keychain on every call but is cheap, and the
    /// preference is `@Observable` so SwiftUI rebuilds the tab
    /// strip when the user toggles it.
    public var shouldShowChatTab: Bool {
        guard preferencesStore.aiAnalysisEnabled else { return false }
        if AppleIntelligenceSupport.isDeviceSupported { return true }
        if credentialsStore?.hasAPIKey(for: .anthropic) == true { return true }
        // User explicitly selected the Anthropic backend but
        // hasn't signed in yet. Show the tab anyway so they can
        // see the "Sign in to Claude" prompt and complete
        // configuration without having to discover the Settings
        // route first. Without this clause, an Apple-Intelligence-
        // ineligible device that picked Anthropic would silently
        // lose the chat surface and the user would have no
        // affordance to fix it from the chat tab itself.
        return preferencesStore.aiBackend == .anthropic
    }

    // MARK: - Lifecycle

    /// Eagerly prewarm the chat session at app launch so the first
    /// user prompt streams without paying construction cost.
    ///
    /// Called from `AppCore`'s root `.task`. Composes with
    /// `BonjourChatView`'s own `.onAppear` prewarm — together they
    /// turn "first tap on a suggestion takes a beat to start
    /// streaming" into "first tap streams immediately".
    ///
    /// No-op when ``chatSession`` is `nil` (ineligible device) or
    /// when AI is disabled in preferences — the factory's
    /// `prewarmIfEnabled` handles both gates internally.
    public func prewarmChatSession() async {
        await chatSessionFactory.prewarmIfEnabled(
            session: chatSession,
            aiAnalysisEnabled: preferencesStore.aiAnalysisEnabled
        )
    }

    /// Recreates the chat session and explainer from the current
    /// preferences.
    ///
    /// Called from `AppCoreScene`'s `.onChange(of: aiBackend)` /
    /// `.onChange(of: aiCloudModel)` watchers so flipping the
    /// backend picker in Settings — or signing into / out of
    /// Claude — takes effect without an app restart. The new
    /// session replaces the old `@Observable`-tracked
    /// `chatSession` / `explainer`, which causes the SwiftUI
    /// environment values to update and the chat / Insights
    /// surfaces to bind to the new instance.
    ///
    /// Side effect: the in-flight chat conversation is dropped.
    /// We don't try to migrate `messages` across backends because
    /// the conversation history is meaningless across providers —
    /// Claude has no record of the on-device session's prior
    /// turns, and vice versa. The clearer UX is "switching
    /// providers starts a fresh conversation" rather than a
    /// partially-cross-pollinated state.
    public func refreshAIBackend() {
        explainer = explainerFactory.makeForCurrentEnvironment()
        chatSession = chatSessionFactory.makeForCurrentEnvironment(
            publishManager: dependencies.bonjourPublishManager
        )
    }
}
