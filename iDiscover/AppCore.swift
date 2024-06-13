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

    @StateObject var viewModel = ViewModel()

    var body: some Scene {
        WindowGroup {
            GeometryReader { geometry in
                if geometry.size.width < self.viewModel.sidebarCutoffWidth {
                    TabBar(selectedDestination: self.$viewModel.selectedDestination)
                        .toastableContainer(toastApi: viewModel.toastApi)
                } else {
                    Text(verbatim: "TODO: wide view")
//                    SidebarNavigationView(selectedDestination: self.$viewModel.selectedDestination)
//                        .toastableContainer(toastApi: self.toastApi)
                }
            }
            .tint(.kozBonBlue)
        }
    }

    // MARK: - ViewModel

    class ViewModel: ObservableObject {

        @MainActor @Published var selectedDestination: TopLevelDestination = .bonjour

        let sidebarCutoffWidth: CGFloat = 500
        let toastApi = ToastApi()
    }
}
