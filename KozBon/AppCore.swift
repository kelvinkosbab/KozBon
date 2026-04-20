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

    @State private var dependencies = DependencyContainer()
    @State private var preferencesStore = PreferencesStore()
    @State private var explainer: (any BonjourServiceExplainerProtocol)? = Self.makeExplainer()

    /// Creates an AI explainer if the on-device model is available.
    private static func makeExplainer() -> (any BonjourServiceExplainerProtocol)? {
        #if canImport(FoundationModels)
        if #available(iOS 26, macOS 26, visionOS 26, *) {
            return BonjourServiceExplainer()
        }
        #endif
        return nil
    }

    var body: some Scene {
        WindowGroup {
            if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
                TabView {
                    Tab {
                        BonjourScanForServicesView(dependencies: dependencies)
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

                    Tab {
                        SettingsView()
                    } label: {
                        Label {
                            Text(verbatim: TopLevelDestination.settings.titleString)
                        } icon: {
                            TopLevelDestination.settings.icon
                        }
                    }

                    if AppleIntelligenceSupport.isDeviceSupported,
                       preferencesStore.aiAnalysisEnabled {
                        Tab(role: .search) {
                            BonjourChatView(dependencies: dependencies)
                        } label: {
                            Label {
                                Text(verbatim: TopLevelDestination.chat.titleString)
                            } icon: {
                                TopLevelDestination.chat.icon
                            }
                        }
                    }
                }
                #if os(macOS)
                .tabViewStyle(.automatic)
                #else
                .tabViewStyle(.sidebarAdaptable)
                #endif
                .tint(.kozBonBlue)
                .environment(\.dependencies, dependencies)
                .environment(\.serviceExplainer, explainer)
                .environment(\.preferencesStore, preferencesStore)
            } else {
                TabView {
                    BonjourScanForServicesView(dependencies: dependencies)
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
                        BonjourChatView(dependencies: dependencies)
                            .tabItem {
                                Label {
                                    Text(verbatim: TopLevelDestination.chat.titleString)
                                } icon: {
                                    TopLevelDestination.chat.icon
                                }
                            }
                    }

                    SettingsView()
                        .tabItem {
                            Label {
                                Text(verbatim: TopLevelDestination.settings.titleString)
                            } icon: {
                                TopLevelDestination.settings.icon
                            }
                        }
                }
                .tint(.kozBonBlue)
                .environment(\.dependencies, dependencies)
                .environment(\.serviceExplainer, explainer)
                .environment(\.preferencesStore, preferencesStore)
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
    }
}
#endif
