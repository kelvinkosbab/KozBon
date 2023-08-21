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
    
    @ObservedObject var dataSource = DataSource()
    
    var body: some Scene {
        WindowGroup {
            switch self.runMode {
            case .mainApplication, .uiUnitTests:
                GeometryReader { geometry in
                    if geometry.size.width < self.dataSource.sidebarCutoffWidth {
                        TabBar(selectedItem: self.$dataSource.selectedItem)
                            .toastableContainer(toastApi: self.toastApi)
                    } else {
                        SidebarNavigationView(selectedItem: self.$dataSource.selectedItem)
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
    
    // MARK: - DataSource
    
    class DataSource : ObservableObject {
        
        @Published var selectedItem: (any BarItem)?
        
        let sidebarCutoffWidth: CGFloat = 500
    }
}
