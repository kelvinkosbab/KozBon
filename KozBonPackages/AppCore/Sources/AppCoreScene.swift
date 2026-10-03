//
//  AppCoreScene.swift
//  AppCore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import CoreUI
import BonjourUI
import BonjourModels
import BonjourScanning
import BonjourAI
import BonjourAIApple
import BonjourAICore
import BonjourAIAnthropic
import BonjourStorage

// MARK: - AppCoreScene

/// Root scene for the KozBon app. Thin presenter; orchestration
/// lives on ``AppCoreViewModel``.
public struct AppCoreScene: Scene {

    @State private var viewModel: AppCoreViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Cloud provider the scene-level sign-in sheet should mount
    /// for. Driven by the
    /// ``Notification.Name/aiCloudSignInRequested`` notification —
    /// the Insights long-press menu posts when the user picks
    /// the "Sign in to Claude" / "Sign in to GitHub" CTA on a
    /// cloud-backend row that lacks credentials. Hosting the
    /// sheet here (rather than inside each long-press call site)
    /// keeps the sign-in surface reachable from Discover,
    /// Library, the chat tab, and any future Insights surface
    /// without each of them having to plumb its own sheet state.
    @State private var pendingCloudSignInProvider: AICloudProvider?

    /// Production initializer — wires the default
    /// ``DependencyContainer`` and the cloud-aware factories.
    public init() {
        let credentialsStore = MainActor.assumeIsolated { KeychainAICloudCredentialsStore() }
        // ONE shared preferences store: the factories consult it
        // for routing and Settings writes through it. Separate
        // instances would each spin up their own SwiftData
        // container and writes wouldn't propagate.
        let preferencesStore = MainActor.assumeIsolated { PreferencesStore() }
        let chatFactory = CloudAwareBonjourChatSessionFactory(
            credentialsStore: credentialsStore,
            preferencesStore: preferencesStore
        )
        let explainerFactory = CloudAwareBonjourServiceExplainerFactory(
            credentialsStore: credentialsStore,
            preferencesStore: preferencesStore
        )
        self.init(
            dependencies: DependencyContainer(),
            explainerFactory: explainerFactory,
            chatSessionFactory: chatFactory,
            credentialsStore: credentialsStore,
            preferencesStore: preferencesStore
        )
    }

    /// Designated init for tests and previews; production calls
    /// the no-arg form above.
    public init(
        dependencies: DependencyContainer,
        explainerFactory: any BonjourServiceExplainerFactoryProtocol,
        chatSessionFactory: any BonjourChatSessionFactoryProtocol,
        credentialsStore: (any AICloudCredentialsStore & Sendable)? = nil,
        preferencesStore: PreferencesStore? = nil
    ) {
        _viewModel = State(initialValue: AppCoreViewModel(
            dependencies: dependencies,
            explainerFactory: explainerFactory,
            chatSessionFactory: chatSessionFactory,
            credentialsStore: credentialsStore,
            preferencesStore: preferencesStore
        ))
    }

    public var body: some Scene {
        WindowGroup {
            // `@Bindable` lets us hand a binding into
            // `TabView(selection:)` without making
            // `selectedTab` itself a `@State` here — keeping
            // the source-of-truth on the view model means
            // tests and previews can drive the selection
            // without going through SwiftUI.
            @Bindable var bindable = viewModel

            // Deployment targets (iOS 18.6 / macOS 15.6 / visionOS 26.0)
            // are all already past the iOS 18 / macOS 15 / visionOS 2
            // thresholds the new TabView API needs, so no `#available`
            // gate is required. Xcode 27's SwiftUI tightened the
            // `TupleContent<repeat each Content>` conformance to require
            // iOS 26 specifically — and an `if/else` here was producing
            // exactly that tuple shape, breaking the build under the
            // iOS 26 SDK even though both branches type-checked under
            // older Xcode toolchains.
            TabView(selection: $bindable.selectedTab) {
                Tab(value: TopLevelDestination.bonjour) {
                    BonjourScanForServicesView(viewModel: viewModel.servicesViewModel)
                } label: {
                    Label {
                        Text(verbatim: TopLevelDestination.bonjour.titleString)
                    } icon: {
                        TopLevelDestination.bonjour.icon
                    }
                }

                Tab(value: TopLevelDestination.bonjourServiceTypes) {
                    SupportedServicesView()
                } label: {
                    Label {
                        Text(verbatim: TopLevelDestination.bonjourServiceTypes.titleString)
                    } icon: {
                        TopLevelDestination.bonjourServiceTypes.icon
                    }
                }

                // macOS Preferences belong in the standard
                // Settings window (⌘,) the `Settings { }`
                // scene below provides.
                #if !os(macOS)
                Tab(value: TopLevelDestination.settings) {
                    SettingsView()
                } label: {
                    Label {
                        Text(verbatim: TopLevelDestination.settings.titleString)
                    } icon: {
                        TopLevelDestination.settings.icon
                    }
                }
                #endif

                if viewModel.shouldShowChatTab {
                    Tab(value: TopLevelDestination.chat, role: chatTabRole) {
                        BonjourChatView(viewModel: viewModel.servicesViewModel)
                    } label: {
                        ChatTabLabel(
                            backend: viewModel.preferencesStore.aiBackend
                        )
                    }
                }
            }
            #if os(macOS)
            .tabViewStyle(.automatic)
            .frame(minWidth: 800, minHeight: 500)
            #else
            // `.automatic` (not `.sidebarAdaptable`) on
            // iPad gives the floating top capsule without
            // the user-toggleable left sidebar — the
            // sidebar mode was confusing in regular size
            // class and we'd rather ship the cleaner top-
            // tab UX. iPhone keeps its bottom tabs (the
            // automatic style for compact size class) and
            // visionOS keeps its ornament tabs.
            .tabViewStyle(.automatic)
            #endif
            // Global tint stays KozBon blue so non-chat tabs
            // don't inherit the backend's accent color. Chat
            // applies the backend tint locally.
            .tint(Color.kozBonBlue)
            .environment(\.dependencies, viewModel.dependencies)
            .environment(\.serviceExplainer, viewModel.explainer)
            .environment(\.chatSession, viewModel.chatSession)
            .environment(\.preferencesStore, viewModel.preferencesStore)
            // Animate the tab-bar tint + chat-tab icon swap
            // when the backend changes mid-session.
            .animation(
                reduceMotion ? nil : .default,
                value: viewModel.preferencesStore.aiBackend
            )
            .task {
                await viewModel.prewarmChatSession()
            }
            .onChange(of: viewModel.preferencesStore.aiBackend) {
                viewModel.refreshAIBackend()
            }
            .onChange(of: viewModel.preferencesStore.aiCloudModelIdentifier) {
                viewModel.refreshAIBackend()
            }
            // Sign-in / sign-out to Claude posts this
            // notification; re-run the factories so the
            // active session reflects the new credentials.
            .onReceive(
                NotificationCenter.default.publisher(
                    for: .aiCloudCredentialsChanged
                )
            ) { _ in
                viewModel.refreshAIBackend()
            }
            .modifier(CloudSignInSheetPresentation(
                pendingProvider: $pendingCloudSignInProvider,
                credentialsStore: viewModel.credentialsStore
            ))
        }
        #if os(macOS)
        .defaultSize(width: 1100, height: 700)
        .windowResizability(.contentSize)
        .commands {
            AppCommands()
        }
        #endif

        #if os(macOS)
        WindowGroup("Service Type", for: BonjourServiceType.self) { $serviceType in
            if let serviceType {
                NavigationStack {
                    SupportedServiceDetailView(serviceType: serviceType)
                }
                .frame(minWidth: 400, minHeight: 300)
            }
        }
        .defaultSize(width: 500, height: 400)

        Settings {
            SettingsView()
        }
        #endif

    }

    // MARK: - Chat Tab Role

    /// Role that gives the chat tab its separated, trailing
    /// position in the tab bar.
    ///
    /// iOS 26 granted that Liquid Glass treatment to `.search`
    /// tabs, so the chat tab claimed the role for the *look* even
    /// though it hosts a conversation, not a search field. iOS 27
    /// split the two concerns: `.prominent` now owns the visual
    /// treatment, and a `.search` tab only "may receive the
    /// prominent visual treatment by default" — which it stops
    /// doing for a tab that never implements search. That's why
    /// the chat tab quietly rejoined the row on iOS 27.
    ///
    /// Two gates, and both are load-bearing:
    ///
    /// - `#if compiler(>=6.4)` — `.prominent` exists only in the
    ///   iOS 27 SDK. App Store archives are still cut with Xcode
    ///   26.5 (Swift 6.3.2), where merely *naming* the symbol
    ///   fails to compile; Xcode 27 is Swift 6.4.
    /// - `if #available` — the deployment target is iOS 26, so
    ///   even an Xcode-27 build has to fall back at runtime.
    ///
    /// macOS deliberately takes no role: it renders a search-role
    /// tab as a search field and swaps the label's icon for a
    /// magnifying glass, which would throw away the backend
    /// glyph. Whether `.prominent` sidesteps that on macOS 27 is
    /// untested, so this leaves a working surface alone.
    ///
    /// Computed here rather than inline in the `TabView` builder
    /// because an `if #available` *inside* that builder is what
    /// produced the `TupleContent<repeat each Content>`
    /// variadic-generics build failure under the iOS 26 SDK.
    private var chatTabRole: TabRole? {
        #if os(macOS)
        return nil
        #else
        #if compiler(>=6.4)
        if #available(iOS 27, visionOS 27, *) {
            return .prominent
        }
        #endif
        return .search
        #endif
    }
}

// MARK: - ChatTabLabel

/// Label for the AI chat tab. In a regular horizontal size
/// class (macOS, iPad full screen, visionOS) the title swaps to
/// the active backend's brand name — "Apple Intelligence",
/// "Claude", "GitHub" — so the wide top tab capsule isn't a
/// lone glyph the user has to decode. Compact size class
/// (iPhone, iPad Slide Over) keeps the generic "Chat" / "Explore"
/// title since the icon+text pair already reads cleanly in the
/// bottom tab bar.
private struct ChatTabLabel: View {

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let backend: AIBackend

    var body: some View {
        Label {
            Text(titleText)
        } icon: {
            TopLevelDestination.chat.icon(activeBackend: backend)
        }
    }

    private var titleText: String {
        #if os(macOS) || os(visionOS)
        // macOS / visionOS have no horizontal size class and the
        // window is always "wide" by definition.
        return String(localized: backend.displayName)
        #else
        if horizontalSizeClass == .regular {
            return String(localized: backend.displayName)
        }
        return TopLevelDestination.chat.titleString
        #endif
    }
}
