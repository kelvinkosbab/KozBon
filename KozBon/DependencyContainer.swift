//
//  DependencyContainer.swift
//  KozBon
//
//  Created by Dependency Injection Implementation
//  Copyright © 2024 Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - DependencyContainer

/// Central container for managing application dependencies
final class DependencyContainer: Sendable {

    // MARK: - Services

    let bonjourServiceScanner: any BonjourServiceScannerProtocol
    let bonjourPublishManager: any BonjourPublishManagerProtocol

    // MARK: - Initialization

    /// Creates a dependency container with real production services
    @MainActor
    init() {
        self.bonjourServiceScanner = BonjourServiceScanner.shared
        self.bonjourPublishManager = MyBonjourPublishManager.shared
    }

    /// Creates a dependency container with custom services (useful for testing or previews)
    init(
        bonjourServiceScanner: any BonjourServiceScannerProtocol,
        bonjourPublishManager: any BonjourPublishManagerProtocol
    ) {
        self.bonjourServiceScanner = bonjourServiceScanner
        self.bonjourPublishManager = bonjourPublishManager
    }
}

// MARK: - Environment Key

private struct DependencyContainerKey: @preconcurrency EnvironmentKey {
    @MainActor static let defaultValue = DependencyContainer()
}

extension EnvironmentValues {
    var dependencies: DependencyContainer {
        get { self[DependencyContainerKey.self] }
        set { self[DependencyContainerKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Inject a custom dependency container into the view hierarchy
    func dependencies(_ container: DependencyContainer) -> some View {
        self.environment(\.dependencies, container)
    }
}
