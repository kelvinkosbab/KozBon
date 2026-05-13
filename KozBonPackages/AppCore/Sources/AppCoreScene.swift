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
import BonjourAICloud
import BonjourStorage

// MARK: - AppCoreScene

/// Root scene for the KozBon app. Thin presenter — every
/// dependency, factory wiring, async prewarm, and the AI-tab
/// gating decision lives on ``AppCoreViewModel``. This struct's
/// job is the SwiftUI scene tree (tab definitions, environment
/// injection, the platform-conditional Settings / Window scenes).
///
/// Lives in the `AppCore` package; the Xcode app target's `@main`
/// entry point (`KozBonApp`) is a one-line shim that just returns
/// `AppCoreScene()` from its body. That split keeps the
/// executable target free of business logic — everything testable
/// lives in the package and runs under `swift test`.
public struct AppCoreScene: Scene {

    /// The single, app-session-lived view model. Owns every
    /// dependency the scenes read. `@State` because `AppCoreScene`
    /// is the natural owner — see the doc comment on
    /// ``AppCoreViewModel`` for the lifetime rationale.
    @State private var viewModel: AppCoreViewModel

    /// Production initializer — uses the default
    /// ``DependencyContainer`` and the cloud-aware factories from
    /// `BonjourAICloud`. The cloud-aware factories internally
    /// hold the legacy on-device factories from `BonjourAI` and
    /// route between them based on the user's `aiBackend`
    /// preference, so users who never touch the cloud backend
    /// see the same behavior they did before ADR 0005.
    ///
    /// The Xcode app target's `@main` shim calls this no-arg form.
    /// Tests, previews, and developer-mode entry points construct
    /// `AppCoreScene` via the designated init below with stubbed
    /// factories.
    public init() {
        let credentialsStore = MainActor.assumeIsolated { KeychainAICloudCredentialsStore() }
        // ONE shared preferences store. The cloud-aware
        // factories consult it for routing decisions on every
        // `makeForCurrentEnvironment` call; Settings writes to
        // it via the environment value. If we created separate
        // instances (as a previous bug did), each
        // `PreferencesStore()` spun up its own SwiftData
        // container — writes from one didn't propagate to the
        // other in-memory, so Settings would set
        // `aiBackend = .anthropic` and the factory would still
        // see `.appleIntelligence` and route to Apple.
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

    /// Designated init — every dependency is supplied. Tests,
    /// previews, and developer-mode entry points use this form;
    /// the no-arg ``init()`` calls through with production
    /// defaults.
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
            if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
                TabView {
                    Tab {
                        BonjourScanForServicesView(viewModel: viewModel.servicesViewModel)
                    } label: {
                        Label {
                            Text(verbatim: TopLevelDestination.bonjour.titleString)
                        } icon: {
                            TopLevelDestination.bonjour.icon
                        }
                    }

                    Tab {
                        SupportedServicesView()
                    } label: {
                        Label {
                            Text(verbatim: TopLevelDestination.bonjourServiceTypes.titleString)
                        } icon: {
                            TopLevelDestination.bonjourServiceTypes.icon
                        }
                    }

                    // macOS preferences belong in the standard Settings
                    // window (⌘,) — the `Settings { }` scene below already
                    // provides one, so duplicating it as a tab is the kind
                    // of pattern Mac users find confusing. iOS / iPadOS /
                    // visionOS keep the Settings tab because those
                    // platforms have no equivalent Settings scene.
                    #if !os(macOS)
                    Tab {
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
                        // On iOS/visionOS, `role: .search` places this tab at the trailing
                        // edge with the Liquid Glass separation treatment. On macOS the
                        // system overrides the custom icon with a magnifying glass for
                        // any search-role tab, so we use a regular tab there to keep
                        // the Apple Intelligence icon intact.
                        #if os(macOS)
                        Tab {
                            BonjourChatView(viewModel: viewModel.servicesViewModel)
                        } label: {
                            Label {
                                Text(verbatim: TopLevelDestination.chat.titleString)
                            } icon: {
                                TopLevelDestination.chat.icon(activeBackend: viewModel.preferencesStore.aiBackend)
                            }
                        }
                        #else
                        Tab(role: .search) {
                            BonjourChatView(viewModel: viewModel.servicesViewModel)
                        } label: {
                            Label {
                                Text(verbatim: TopLevelDestination.chat.titleString)
                            } icon: {
                                TopLevelDestination.chat.icon(activeBackend: viewModel.preferencesStore.aiBackend)
                            }
                        }
                        #endif
                    }
                }
                #if os(macOS)
                .tabViewStyle(.automatic)
                .frame(minWidth: 800, minHeight: 500)
                #else
                .tabViewStyle(.sidebarAdaptable)
                #endif
                // The global tint follows the user's selected AI
                // backend so the active provider is visible at
                // a glance on the tab bar (chat-tab icon highlight,
                // toolbar buttons, etc.). Falls back to `kozBonBlue`
                // for Apple Intelligence to preserve the previous
                // look for users who don't touch the cloud path.
                .tint(viewModel.preferencesStore.aiBackend.accentColor)
                .environment(\.dependencies, viewModel.dependencies)
                .environment(\.serviceExplainer, viewModel.explainer)
                .environment(\.chatSession, viewModel.chatSession)
                .environment(\.preferencesStore, viewModel.preferencesStore)
                .task {
                    await viewModel.prewarmChatSession()
                }
                // ADR 0005: when the user flips the backend picker
                // in Settings — or picks a different Claude model —
                // recreate the chat session / explainer so the next
                // message routes to the new backend without an app
                // restart. The chat surface loses any in-flight
                // conversation across the swap (see
                // `refreshAIBackend` docs) but the alternative
                // (silently routing some turns to the old backend
                // after a preference change) is more surprising.
                .onChange(of: viewModel.preferencesStore.aiBackend) {
                    viewModel.refreshAIBackend()
                }
                .onChange(of: viewModel.preferencesStore.aiCloudModel) {
                    viewModel.refreshAIBackend()
                }
                // Re-run the cloud-aware factories when the user
                // signs into / out of Claude mid-session.
                // `AICloudCredentialsStore` implementations post
                // this notification on every successful write —
                // both the Settings sign-in sheet and the in-tab
                // sign-in prompt route through the same store, so
                // either path triggers the same backend swap
                // without an app restart.
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: .aiCloudCredentialsChanged
                    )
                ) { _ in
                    viewModel.refreshAIBackend()
                }
            } else {
                TabView {
                    BonjourScanForServicesView(viewModel: viewModel.servicesViewModel)
                        .tabItem {
                            Label {
                                Text(verbatim: TopLevelDestination.bonjour.titleString)
                            } icon: {
                                TopLevelDestination.bonjour.icon
                            }
                        }

                    SupportedServicesView()
                        .tabItem {
                            Label {
                                Text(verbatim: TopLevelDestination.bonjourServiceTypes.titleString)
                            } icon: {
                                TopLevelDestination.bonjourServiceTypes.icon
                            }
                        }

                    if viewModel.shouldShowChatTab {
                        BonjourChatView(viewModel: viewModel.servicesViewModel)
                            .tabItem {
                                Label {
                                    Text(verbatim: TopLevelDestination.chat.titleString)
                                } icon: {
                                    TopLevelDestination.chat.icon(activeBackend: viewModel.preferencesStore.aiBackend)
                                }
                            }
                    }

                    // Settings tab omitted on macOS — see comment in
                    // the modern (`TabView`) branch above for rationale.
                    #if !os(macOS)
                    SettingsView()
                        .tabItem {
                            Label {
                                Text(verbatim: TopLevelDestination.settings.titleString)
                            } icon: {
                                TopLevelDestination.settings.icon
                            }
                        }
                    #endif
                }
                #if os(macOS)
                .frame(minWidth: 800, minHeight: 500)
                #endif
                // The global tint follows the user's selected AI
                // backend so the active provider is visible at
                // a glance on the tab bar (chat-tab icon highlight,
                // toolbar buttons, etc.). Falls back to `kozBonBlue`
                // for Apple Intelligence to preserve the previous
                // look for users who don't touch the cloud path.
                .tint(viewModel.preferencesStore.aiBackend.accentColor)
                .environment(\.dependencies, viewModel.dependencies)
                .environment(\.serviceExplainer, viewModel.explainer)
                .environment(\.chatSession, viewModel.chatSession)
                .environment(\.preferencesStore, viewModel.preferencesStore)
                .task {
                    await viewModel.prewarmChatSession()
                }
                // ADR 0005: when the user flips the backend picker
                // in Settings — or picks a different Claude model —
                // recreate the chat session / explainer so the next
                // message routes to the new backend without an app
                // restart. The chat surface loses any in-flight
                // conversation across the swap (see
                // `refreshAIBackend` docs) but the alternative
                // (silently routing some turns to the old backend
                // after a preference change) is more surprising.
                .onChange(of: viewModel.preferencesStore.aiBackend) {
                    viewModel.refreshAIBackend()
                }
                .onChange(of: viewModel.preferencesStore.aiCloudModel) {
                    viewModel.refreshAIBackend()
                }
            }
        }
        #if os(macOS)
        // `.windowResizability(.contentSize)` lets the window shrink to
        // whatever the content allows — without a min frame on the
        // content, that's effectively zero. Pin a sensible floor so the
        // sidebar + detail layout stays usable.
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
}
