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

/// Root scene for the KozBon app. Thin presenter; orchestration
/// lives on ``AppCoreViewModel``.
public struct AppCoreScene: Scene {

    @State private var viewModel: AppCoreViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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

                    // macOS Preferences belong in the standard
                    // Settings window (⌘,) the `Settings { }`
                    // scene below provides.
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
                        // `role: .search` on iOS/visionOS places this
                        // tab at the trailing edge with Liquid Glass
                        // separation. macOS overrides any search-role
                        // tab's icon with a magnifying glass, so we
                        // use a regular Tab there to preserve our
                        // backend-specific glyph.
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
                .tint(viewModel.preferencesStore.aiBackend.accentColor)
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
                .onChange(of: viewModel.preferencesStore.aiCloudModel) {
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
                .tint(viewModel.preferencesStore.aiBackend.accentColor)
                .environment(\.dependencies, viewModel.dependencies)
                .environment(\.serviceExplainer, viewModel.explainer)
                .environment(\.chatSession, viewModel.chatSession)
                .environment(\.preferencesStore, viewModel.preferencesStore)
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
                .onChange(of: viewModel.preferencesStore.aiCloudModel) {
                    viewModel.refreshAIBackend()
                }
            }
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
}
