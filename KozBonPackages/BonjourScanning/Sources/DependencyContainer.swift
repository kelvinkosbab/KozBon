//
//  DependencyContainer.swift
//  BonjourScanning
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourModels

// MARK: - DependencyContainer

/// Central container for managing application dependencies.
///
/// Provides protocol-based access to the scanner and publish manager.
/// The production `init()` creates fresh instances. Tests and previews
/// use the custom `init(bonjourServiceScanner:bonjourPublishManager:)` with mock implementations.
public final class DependencyContainer: Sendable {

    // MARK: - Services

    /// The service scanner used for discovering Bonjour services on the network.
    public let bonjourServiceScanner: any BonjourServiceScannerProtocol

    /// The publish manager used for broadcasting Bonjour services.
    public let bonjourPublishManager: any BonjourPublishManagerProtocol

    // MARK: - Initialization

    /// Creates a dependency container with production services.
    @MainActor
    public init() {
        self.bonjourServiceScanner = BonjourServiceScanner()
        self.bonjourPublishManager = BonjourPublishManager()
    }

    /// Creates a dependency container with custom services (useful for testing or previews).
    public init(
        bonjourServiceScanner: any BonjourServiceScannerProtocol,
        bonjourPublishManager: any BonjourPublishManagerProtocol
    ) {
        self.bonjourServiceScanner = bonjourServiceScanner
        self.bonjourPublishManager = bonjourPublishManager
    }
}

// MARK: - Mock Factory

extension DependencyContainer {

    /// Creates a dependency container with mock services for testing.
    @MainActor
    public static func mock(
        scanner: MockBonjourServiceScanner = MockBonjourServiceScanner(),
        publishManager: MockBonjourPublishManager = MockBonjourPublishManager()
    ) -> DependencyContainer {
        return DependencyContainer(
            bonjourServiceScanner: scanner,
            bonjourPublishManager: publishManager
        )
    }
}

// MARK: - Environment Key

private struct DependencyContainerKey: @preconcurrency EnvironmentKey {
    @MainActor static let defaultValue = DependencyContainer()
}

public extension EnvironmentValues {
    /// The application's dependency container, accessible via `@Environment(\.dependencies)`.
    var dependencies: DependencyContainer {
        get { self[DependencyContainerKey.self] }
        set { self[DependencyContainerKey.self] = newValue }
    }
}

// MARK: - View Extension

public extension View {
    /// Inject a custom dependency container into the view hierarchy.
    func dependencies(_ container: DependencyContainer) -> some View {
        self.environment(\.dependencies, container)
    }
}
