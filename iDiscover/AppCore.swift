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
            TabBar()
                .toastableContainer(toastApi: toastApi)
                .tint(.kozBonBlue)
        }
    }
}
