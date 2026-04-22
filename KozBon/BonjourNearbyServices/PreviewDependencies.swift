//
//  PreviewDependencies.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourCore
import BonjourModels
import BonjourScanning
import BonjourUI

// MARK: - Preview Helpers

extension DependencyContainer {

    /// Creates a dependency container configured for SwiftUI previews.
    @MainActor
    static func preview(
        simulateScanning: Bool = false
    ) -> DependencyContainer {
        let scanner = MockBonjourServiceScanner()
        let publishManager = MockBonjourPublishManager()

        if simulateScanning {
            scanner.isProcessing = true
        }

        return DependencyContainer(
            bonjourServiceScanner: scanner,
            bonjourPublishManager: publishManager
        )
    }
}

// MARK: - Preview Examples

#Preview("Bonjour Scan View - Empty") {
    let deps = DependencyContainer.preview()
    NavigationStack {
        BonjourScanForServicesView(viewModel: BonjourServicesViewModel(dependencies: deps))
    }
}

#Preview("Bonjour Scan View - Scanning") {
    let deps = DependencyContainer.preview(simulateScanning: true)
    NavigationStack {
        BonjourScanForServicesView(viewModel: BonjourServicesViewModel(dependencies: deps))
    }
}
