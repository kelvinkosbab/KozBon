//
//  CoreTabBar.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 6/12/24.
//  Copyright © 2024 Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - TabBar

struct TabBar: View {
    var body: some View {
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
    }
}
