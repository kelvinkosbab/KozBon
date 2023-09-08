//
//  AppCore.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 8/20/23.
//  Copyright © 2023 Kozinga. All rights reserved.
//

import SwiftUI
import CoreUI
import RunMode

// MARK: - AppCore

@main
struct AppCore : App {
    
    let runMode = RunMode.getActive()
    let toastApi = ToastApi()
    
    @StateObject var viewModel = ViewModel()
    
    var body: some Scene {
        WindowGroup {
            switch self.runMode {
            case .mainApplication, .uiUnitTests:
                GeometryReader { geometry in
                    if geometry.size.width < self.viewModel.sidebarCutoffWidth {
                        TabBar(selectedItem: self.$viewModel.selectedItem)
                            .toastableContainer(toastApi: self.toastApi)
                    } else {
                        SidebarNavigationView(selectedItem: self.$viewModel.selectedItem)
                            .toastableContainer(toastApi: self.toastApi)
                    }
                }
            case .unitTests:
                VStack {
                    Text("Running Unit Tests")
                    ProgressView()
                }
            }
        }
    }
    
    // MARK: - ViewModel
    
    class ViewModel : ObservableObject {
        
        @Published var selectedItem: (any BarItem)?
        
        let sidebarCutoffWidth: CGFloat = 500
    }
}
