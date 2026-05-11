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
    /// ``DependencyContainer``, the default
    /// ``BonjourServiceExplainerFactory``, and the default
    /// ``BonjourChatSessionFactory``. The designated init below
    /// accepts each as an injectable parameter; this convenience
    /// just calls through with production defaults.
    ///
    /// The Xcode app target's `@main` shim calls this no-arg form.
    /// Tests, previews, and developer-mode entry points construct
    /// `AppCoreScene` via the designated init below with stubbed
    /// factories.
    public init() {
        self.init(
            dependencies: DependencyContainer(),
            explainerFactory: BonjourServiceExplainerFactory(),
            chatSessionFactory: BonjourChatSessionFactory()
        )
    }

    /// Designated init — every dependency is supplied. Tests,
    /// previews, and developer-mode entry points use this form;
    /// the no-arg ``init()`` calls through with production
    /// defaults.
    public init(
        dependencies: DependencyContainer,
        explainerFactory: any BonjourServiceExplainerFactoryProtocol,
        chatSessionFactory: any BonjourChatSessionFactoryProtocol
    ) {
        _viewModel = State(initialValue: AppCoreViewModel(
            dependencies: dependencies,
            explainerFactory: explainerFactory,
            chatSessionFactory: chatSessionFactory
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
                                TopLevelDestination.chat.icon
                            }
                        }
                        #else
                        Tab(role: .search) {
                            BonjourChatView(viewModel: viewModel.servicesViewModel)
                        } label: {
                            Label {
                                Text(verbatim: TopLevelDestination.chat.titleString)
                            } icon: {
                                TopLevelDestination.chat.icon
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
                .tint(.kozBonBlue)
                .environment(\.dependencies, viewModel.dependencies)
                .environment(\.serviceExplainer, viewModel.explainer)
                .environment(\.chatSession, viewModel.chatSession)
                .environment(\.preferencesStore, viewModel.preferencesStore)
                .task {
                    await viewModel.prewarmChatSession()
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
                                    TopLevelDestination.chat.icon
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
                .tint(.kozBonBlue)
                .environment(\.dependencies, viewModel.dependencies)
                .environment(\.serviceExplainer, viewModel.explainer)
                .environment(\.chatSession, viewModel.chatSession)
                .environment(\.preferencesStore, viewModel.preferencesStore)
                .task {
                    await viewModel.prewarmChatSession()
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
