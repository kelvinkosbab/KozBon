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

    /// Creates a dependency container configured for SwiftUI previews
    @MainActor
    static func preview(
        withMockData: Bool = true,
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
    NavigationStack {
        BonjourScanForServicesView(
            scanner: MockBonjourServiceScanner()
        )
    }
}

#Preview("Bonjour Scan View - Scanning") {
    NavigationStack {
        BonjourScanForServicesView(
            scanner: {
                let scanner = MockBonjourServiceScanner()
                scanner.isProcessing = true
                return scanner
            }()
        )
    }
}
