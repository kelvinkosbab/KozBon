//
//  AppCore.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 8/20/23.
//  Copyright © 2023 Kozinga. All rights reserved.
//

import SwiftUI
import CoreUI

// MARK: - AppCore

@main
struct AppCore: App {

    // MARK: - Dependencies

    @State private var dependencies = DependencyContainer()

    var body: some Scene {
        WindowGroup {
            if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
                TabView {
                    Tab {
                        NavigationStack {
                            BonjourScanForServicesView()
                        }
                    } label: {
                        Label {
                            Text(verbatim: TopLevelDestination.bonjour.titleString)
                        } icon: {
                            TopLevelDestination.bonjour.icon
                        }
                    }

                    Tab {
                        NavigationStack {
                            SupportedServicesView()
                        }
                    } label: {
                        Label {
                            Text(verbatim: TopLevelDestination.bonjourServiceTypes.titleString)
                        } icon: {
                            TopLevelDestination.bonjourServiceTypes.icon
                        }
                    }
                }
                .tabViewStyle(.sidebarAdaptable)
                .tint(.kozBonBlue)
                .environment(\.dependencies, dependencies)
            } else {
                TabView {
                    NavigationStack {
                        BonjourScanForServicesView()
                    }
                    .tabItem {
                        Label {
                            Text(verbatim: TopLevelDestination.bonjour.titleString)
                        } icon: {
                            TopLevelDestination.bonjour.icon
                        }
                    }

                    NavigationStack {
                        SupportedServicesView()
                    }
                    .tabItem {
                        Label {
                            Text(verbatim: TopLevelDestination.bonjourServiceTypes.titleString)
                        } icon: {
                            TopLevelDestination.bonjourServiceTypes.icon
                        }
                    }
                }
                .tint(.kozBonBlue)
                .environment(\.dependencies, dependencies)
            }
        }
        #if os(macOS)
        .defaultSize(width: 900, height: 650)
        .windowResizability(.contentSize)
        .commands {
            AppCommands()
        }
        #endif
    }
}

// MARK: - AppCommands

#if os(macOS)
private struct AppCommands: Commands {

    @FocusedBinding(\.isBroadcastServicePresented) private var isBroadcastServicePresented
    @FocusedBinding(\.isCreateServiceTypePresented) private var isCreateServiceTypePresented

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("Broadcast Service") {
                isBroadcastServicePresented = true
            }
            .disabled(isBroadcastServicePresented == nil)
            .keyboardShortcut("n", modifiers: [.command, .shift])

            Button("Create Custom Service Type") {
                isCreateServiceTypePresented = true
            }
            .disabled(isCreateServiceTypePresented == nil)
            .keyboardShortcut("t", modifiers: [.command, .shift])
        }
    }
}
#endif
