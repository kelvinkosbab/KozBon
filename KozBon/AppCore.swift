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
import BonjourLocalization
import BonjourAI
import BonjourStorage

#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - AppCore

@main
struct AppCore: App {

    // MARK: - Dependencies

    @State private var dependencies: DependencyContainer
    @State private var preferencesStore = PreferencesStore()
    @State private var explainer: (any BonjourServiceExplainerProtocol)? = Self.makeExplainer()

    /// The single, app-wide services view model.
    ///
    /// Must be shared between the Discover and Chat tabs because
    /// `BonjourServiceScanner` exposes one `weak var delegate`. If each tab
    /// created its own view model, the tabs would race to register themselves
    /// as the delegate and one tab would silently show zero discovered
    /// services — see ``BonjourServicesViewModel`` for the full explanation.
    @State private var servicesViewModel: BonjourServicesViewModel

    init() {
        let dependencies = DependencyContainer()
        _dependencies = State(initialValue: dependencies)
        _servicesViewModel = State(initialValue: BonjourServicesViewModel(dependencies: dependencies))
    }

    /// Creates an AI explainer if the on-device model is available.
    ///
    /// In the iOS Simulator, returns a mock that streams lorem ipsum responses
    /// so the UI can be tested end-to-end without a real AI device.
    private static func makeExplainer() -> (any BonjourServiceExplainerProtocol)? {
        #if targetEnvironment(simulator)
        return SimulatorBonjourServiceExplainer()
        #elseif canImport(FoundationModels)
        if #available(iOS 26, macOS 26, visionOS 26, *) {
            return BonjourServiceExplainer()
        }
        return nil
        #else
        return nil
        #endif
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
                .environment(\.preferencesStore, preferencesStore)
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
                .environment(\.preferencesStore, preferencesStore)
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

// MARK: - AppCommands

#if os(macOS)
private struct AppCommands: Commands {

    @FocusedBinding(\.isBroadcastServicePresented) private var isBroadcastServicePresented
    @FocusedBinding(\.isCreateServiceTypePresented) private var isCreateServiceTypePresented
    @FocusedValue(\.refreshScan) private var refreshScan

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button(String(localized: Strings.Buttons.broadcastService)) {
                isBroadcastServicePresented = true
            }
            .disabled(isBroadcastServicePresented == nil)
            .keyboardShortcut("n", modifiers: [.command, .shift])

            Button(String(localized: Strings.Buttons.createCustomServiceType)) {
                isCreateServiceTypePresented = true
            }
            .disabled(isCreateServiceTypePresented == nil)
            .keyboardShortcut("t", modifiers: [.command, .shift])

            Divider()

            Button(String(localized: Strings.Buttons.refresh)) {
                refreshScan?()
            }
            .disabled(refreshScan == nil)
            .keyboardShortcut("r", modifiers: .command)
        }

        // Replace the system Help menu (which only ever offered "Search"
        // by default) with curated links the user can reach for when
        // KozBon shows them something they don't recognize. Items are
        // grouped: app-level resources (source, vendor narrative, the
        // human-readable IANA registry, Apple's port reference) above
        // the divider; protocol specs below. The links open in the
        // user's default browser via `Link`, which renders as a regular
        // menu item on macOS.
        //
        // The URLs are hardcoded constants known to be valid — the
        // force-unwraps can't fail at runtime, and `Link`'s API requires
        // a non-optional `URL`. The disables are scoped to this block.
        // swiftlint:disable force_unwrapping
        CommandGroup(replacing: .help) {
            Link(
                String(localized: Strings.Help.kozbonOnGitHub),
                destination: URL(string: "https://github.com/kelvinkosbab/KozBon")!
            )

            Divider()

            Link(
                String(localized: Strings.Help.aboutBonjour),
                destination: URL(string: "https://developer.apple.com/bonjour/")!
            )
            Link(
                String(localized: Strings.Help.ianaServiceRegistry),
                destination: URL(string: "https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml")!
            )
            Link(
                String(localized: Strings.Help.applePortsReference),
                destination: URL(string: "https://support.apple.com/HT202944")!
            )

            Divider()

            Link(
                String(localized: Strings.Help.mdnsSpecification),
                destination: URL(string: "https://datatracker.ietf.org/doc/html/rfc6762")!
            )
            Link(
                String(localized: Strings.Help.dnssdSpecification),
                destination: URL(string: "https://datatracker.ietf.org/doc/html/rfc6763")!
            )
        }
        // swiftlint:enable force_unwrapping
    }
}
#endif
