//
//  AppCore.swift
//  KozBon
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

// MARK: - AppCore

@main
struct AppCore: App {

    // MARK: - Injected Factories

    /// Factory for the on-device AI explainer. Held as a stored
    /// property so the production default can be swapped (e.g.,
    /// in a test harness or a developer-mode build) without
    /// touching the rest of `AppCore`. The protocol is the real
    /// dependency edge — `AppCore` never reaches into a static
    /// namespace.
    private let explainerFactory: any BonjourServiceExplainerFactoryProtocol

    /// Factory for the on-device AI chat session. Same rationale
    /// as ``explainerFactory``. The factory's
    /// ``BonjourChatSessionFactoryProtocol/prewarmIfEnabled(session:aiAnalysisEnabled:)``
    /// is also called from this app's root `.task` modifier.
    private let chatSessionFactory: any BonjourChatSessionFactoryProtocol

    // MARK: - Dependencies

    @State private var dependencies: DependencyContainer
    @State private var preferencesStore = PreferencesStore()
    @State private var explainer: (any BonjourServiceExplainerProtocol)?

    /// App-wide chat session, created once at launch so the chat
    /// tab's first activation doesn't pay the cost of constructing
    /// the `BonjourChatSession` (and lazily, on first ``prewarm()``,
    /// the underlying `LanguageModelSession` with its compiled
    /// system instructions).
    ///
    /// Owning the session at the app level — instead of letting
    /// `BonjourChatView` construct one on first render — also means
    /// the session survives tab switches without being torn down,
    /// and lets us eagerly call ``BonjourChatSessionProtocol/prewarm()``
    /// in a `.task` on the root scene before the user has navigated
    /// anywhere. Combined with the deferred prewarm inside the
    /// chat view's `.onAppear`, this is the difference between
    /// "first tap on a suggestion takes a beat to start streaming"
    /// and "first tap streams immediately."
    @State private var chatSession: (any BonjourChatSessionProtocol)?

    /// The single, app-wide services view model.
    ///
    /// Must be shared between the Discover and Chat tabs because
    /// `BonjourServiceScanner` exposes one `weak var delegate`. If each tab
    /// created its own view model, the tabs would race to register themselves
    /// as the delegate and one tab would silently show zero discovered
    /// services — see ``BonjourServicesViewModel`` for the full explanation.
    @State private var servicesViewModel: BonjourServicesViewModel

    /// Production initializer — uses the default ``DependencyContainer``,
    /// the default ``BonjourServiceExplainerFactory``, and the default
    /// ``BonjourChatSessionFactory``. The designated init below
    /// accepts each as an injectable parameter; this convenience
    /// just calls through with production defaults.
    ///
    /// `App` types instantiated by `@main` can't accept arguments
    /// from the runtime, so the practical "injection" here happens
    /// at compile time: a developer who needs different behavior
    /// (a stub factory in a SwiftUI Preview, an alternate
    /// dependency container in a test harness) calls the
    /// designated init explicitly from their entry point.
    init() {
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
    init(
        dependencies: DependencyContainer,
        explainerFactory: any BonjourServiceExplainerFactoryProtocol,
        chatSessionFactory: any BonjourChatSessionFactoryProtocol
    ) {
        self.explainerFactory = explainerFactory
        self.chatSessionFactory = chatSessionFactory
        _dependencies = State(initialValue: dependencies)
        _servicesViewModel = State(
            initialValue: BonjourServicesViewModel(dependencies: dependencies)
        )
        _explainer = State(initialValue: explainerFactory.makeForCurrentEnvironment())
        _chatSession = State(
            initialValue: chatSessionFactory.makeForCurrentEnvironment(
                publishManager: dependencies.bonjourPublishManager
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
                TabView {
                    Tab {
                        BonjourScanForServicesView(viewModel: servicesViewModel)
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

                    if AppleIntelligenceSupport.isDeviceSupported,
                       preferencesStore.aiAnalysisEnabled {
                        // On iOS/visionOS, `role: .search` places this tab at the trailing
                        // edge with the Liquid Glass separation treatment. On macOS the
                        // system overrides the custom icon with a magnifying glass for
                        // any search-role tab, so we use a regular tab there to keep
                        // the Apple Intelligence icon intact.
                        #if os(macOS)
                        Tab {
                            BonjourChatView(viewModel: servicesViewModel)
                        } label: {
                            Label {
                                Text(verbatim: TopLevelDestination.chat.titleString)
                            } icon: {
                                TopLevelDestination.chat.icon
                            }
                        }
                        #else
                        Tab(role: .search) {
                            BonjourChatView(viewModel: servicesViewModel)
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
                .environment(\.dependencies, dependencies)
                .environment(\.serviceExplainer, explainer)
                .environment(\.chatSession, chatSession)
                .environment(\.preferencesStore, preferencesStore)
                .task {
                    await chatSessionFactory.prewarmIfEnabled(
                        session: chatSession,
                        aiAnalysisEnabled: preferencesStore.aiAnalysisEnabled
                    )
                }
            } else {
                TabView {
                    BonjourScanForServicesView(viewModel: servicesViewModel)
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

                    if AppleIntelligenceSupport.isDeviceSupported,
                       preferencesStore.aiAnalysisEnabled {
                        BonjourChatView(viewModel: servicesViewModel)
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
                .environment(\.dependencies, dependencies)
                .environment(\.serviceExplainer, explainer)
                .environment(\.chatSession, chatSession)
                .environment(\.preferencesStore, preferencesStore)
                .task {
                    await chatSessionFactory.prewarmIfEnabled(
                        session: chatSession,
                        aiAnalysisEnabled: preferencesStore.aiAnalysisEnabled
                    )
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
