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

    private let toastApi = ToastApi()

    var body: some Scene {
        WindowGroup {
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

                NavigationStack {
                    BluetoothScanForDevicesView()
                }
                .tabItem {
                    Label {
                        Text(verbatim: TopLevelDestination.bluetooth.titleString)
                    } icon: {
                        TopLevelDestination.bluetooth.icon
                    }
                }
            }
            .toastableContainer(toastApi: toastApi)
            .tint(.kozBonBlue)
        }
    }
}
