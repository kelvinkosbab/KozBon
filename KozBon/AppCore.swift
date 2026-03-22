//
//  AppCore.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import CoreUI

// MARK: - AppCore

@main
struct AppCore: App {

    // MARK: - Dependencies

    @State private var dependencies = DependencyContainer()

    #if os(visionOS)
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @State private var isImmersiveSpaceOpen = false
    #endif

    var body: some Scene {
        WindowGroup {
            if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
                TabView {
                    Tab {
                        BonjourScanForServicesView()
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
                }
                .tabViewStyle(.sidebarAdaptable)
                .tint(.kozBonBlue)
                .environment(\.dependencies, dependencies)
                #if os(visionOS)
                .ornament(attachmentAnchor: .scene(.trailing)) {
                    VisionOSSideOrnament(
                        isImmersiveSpaceOpen: $isImmersiveSpaceOpen,
                        openImmersiveSpace: openImmersiveSpace,
                        dismissImmersiveSpace: dismissImmersiveSpace
                    )
                }
                #endif
            } else {
                TabView {
                    BonjourScanForServicesView()
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

        #if os(visionOS)
        WindowGroup(id: "networkTopology") {
            NetworkTopologyView()
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 0.8, height: 0.6, depth: 0.8, in: .meters)

        ImmersiveSpace(id: "networkExplorer") {
            ImmersiveNetworkView()
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
        #endif
    }
}

// MARK: - VisionOSSideOrnament

#if os(visionOS)
private struct VisionOSSideOrnament: View {

    @Binding var isImmersiveSpaceOpen: Bool
    let openImmersiveSpace: OpenImmersiveSpaceAction
    let dismissImmersiveSpace: DismissImmersiveSpaceAction

    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 12) {
            Button {
                openWindow(id: "networkTopology")
            } label: {
                Label("3D View", systemImage: "cube")
            }
            .accessibilityHint("Open a volumetric 3D network topology view")

            Button {
                Task {
                    if isImmersiveSpaceOpen {
                        await dismissImmersiveSpace()
                        isImmersiveSpaceOpen = false
                    } else {
                        let result = await openImmersiveSpace(id: "networkExplorer")
                        isImmersiveSpaceOpen = result == .opened
                    }
                }
            } label: {
                Label(
                    isImmersiveSpaceOpen ? "Exit Space" : "Explore",
                    systemImage: isImmersiveSpaceOpen ? "xmark.circle" : "visionpro"
                )
            }
            .accessibilityHint(
                isImmersiveSpaceOpen
                    ? "Exit the immersive network explorer"
                    : "Enter an immersive space to explore nearby services"
            )
        }
        .padding(12)
        .glassBackgroundEffect()
    }
}
#endif

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
