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

    @StateObject var viewModel: ViewModel

    init(selectedDestination: Binding<TopLevelDestination>) {
        self._viewModel = StateObject(wrappedValue: ViewModel(selectedDestination: selectedDestination))
    }
    
    // TODO: Do this 
//    private var selectedDestinationHandler: Binding<TopLevelDestination> { Binding(
//        get: { viewModel.selectedDestination },
//        set: { newValue in
//            if newValue == viewModel.selectedDestination {
//                // TODO: Handle tapped twice to pop to root
//                //viewModel.tappedTwice = true
//            }
//            viewModel.selectedDestination = newValue
//        }
//    )}

    var body: some View {
        TabView {
            NavigationView {
                BonjourScanForServicesView()
            }
            .tabItem {
                Label {
                    Text(verbatim: TopLevelDestination.bonjour.titleString)
                } icon: {
                    TopLevelDestination.bonjour.icon
                }
            }
            
            NavigationView {
                BluetoothScanForDevicesView()
            }
            .tabItem {
                Label {
                    Text(verbatim: TopLevelDestination.bluetooth.titleString)
                } icon: {
                    TopLevelDestination.bluetooth.icon
                }
            }
            
            NavigationView {
                Text("Placeholder app information")
            }
            .tabItem {
                Label {
                    Text(verbatim: TopLevelDestination.appInformation.titleString)
                } icon: {
                    TopLevelDestination.appInformation.icon
                }
            }
        }
    }

    // MARK: - ViewModel

    class ViewModel: ObservableObject {

        @MainActor @Binding var selectedDestination: TopLevelDestination

        init(selectedDestination: Binding<TopLevelDestination>) {
            self._selectedDestination = selectedDestination
        }
    }
}
