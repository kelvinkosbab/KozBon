//
//  AppCoreViewModel.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourUI
import BonjourScanning
import BonjourAI
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

    /// On-device AI explainer that powers long-press Insights.
    /// `nil` on devices without Apple Intelligence — views gate on
    /// the optional and hide the affordance.
    public let explainer: (any BonjourServiceExplainerProtocol)?

    /// App-wide chat session, created once at launch so the chat
    /// tab's first activation doesn't pay the cost of constructing
    /// the `BonjourChatSession` (and lazily, on first
    /// ``prewarmChatSession()``, the underlying
    /// `LanguageModelSession` with its compiled system instructions).
    ///
    /// Owning the session at the app level — instead of letting
    /// `BonjourChatView` construct one on first render — also means
    /// the session survives tab switches without being torn down,
    /// and lets us eagerly call ``prewarmChatSession()`` in a
    /// `.task` on the root scene before the user has navigated
    /// anywhere.
    public let chatSession: (any BonjourChatSessionProtocol)?

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

    /// Factory for the on-device AI chat session. Held as a stored
    /// property so the production default can be swapped (e.g., in
    /// a test harness or a developer-mode build). Kept beyond
    /// `init` because ``prewarmChatSession()`` calls back into it
    /// at scene-task time.
    private let chatSessionFactory: any BonjourChatSessionFactoryProtocol

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
    public init(
        dependencies: DependencyContainer,
        explainerFactory: any BonjourServiceExplainerFactoryProtocol,
        chatSessionFactory: any BonjourChatSessionFactoryProtocol
    ) {
        self.dependencies = dependencies
        self.chatSessionFactory = chatSessionFactory
        self.preferencesStore = PreferencesStore()
        self.servicesViewModel = BonjourServicesViewModel(dependencies: dependencies)
        self.explainer = explainerFactory.makeForCurrentEnvironment()
        self.chatSession = chatSessionFactory.makeForCurrentEnvironment(
            publishManager: dependencies.bonjourPublishManager
        )
    }

    // MARK: - Tab Visibility

    /// Whether the Chat tab should render in the root tab bar.
    ///
    /// Two gates compose:
    /// 1. ``AppleIntelligenceSupport/isDeviceSupported`` — Apple
    ///    Intelligence is technically available on this device.
    ///    Hides the tab on older iPhones, non-M-series Macs, and
    ///    any platform where Foundation Models isn't shipped.
    /// 2. `preferencesStore.aiAnalysisEnabled` — the user has the
    ///    AI feature turned on in Settings. Lets capable-device
    ///    users opt out without uninstalling.
    ///
    /// Both clauses are stable reads at body-evaluation time:
    /// `isDeviceSupported` doesn't change at runtime, and
    /// `aiAnalysisEnabled` is `@Observable`, so SwiftUI rebuilds
    /// the tab strip when the user toggles the preference.
    public var shouldShowChatTab: Bool {
        AppleIntelligenceSupport.isDeviceSupported
            && preferencesStore.aiAnalysisEnabled
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
}
