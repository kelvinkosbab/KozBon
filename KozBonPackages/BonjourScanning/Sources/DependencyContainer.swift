//
//  DependencyContainer.swift
//  BonjourScanning
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourModels
import LocalNetworkMonitor

// MARK: - DependencyContainer

/// Central container for managing application dependencies.
///
/// Provides protocol-based access to the scanner, publish manager, and
/// network-connectivity monitor. The production `init()` creates fresh
/// instances. Tests and previews use the custom
/// `init(bonjourServiceScanner:bonjourPublishManager:localNetworkMonitor:)`
/// with mock implementations.
public final class DependencyContainer: Sendable {

    // MARK: - Services

    /// The service scanner used for discovering Bonjour services on the network.
    public let bonjourServiceScanner: any BonjourServiceScannerProtocol

    /// The publish manager used for broadcasting Bonjour services.
    public let bonjourPublishManager: any BonjourPublishManagerProtocol

    /// Monitor for the device's local-network reachability. The
    /// Discover tab uses this to differentiate "scanning found
    /// nothing" from "you're not on Wi-Fi so scanning can't find
    /// anything" — two empty states the user benefits from
    /// distinguishing.
    ///
    /// Backed by the standalone `LocalNetworkMonitor` package
    /// (`../LocalNetworkMonitor`), so the same primitive can be
    /// reused by any other app that needs local-link reachability.
    public let localNetworkMonitor: any LocalNetworkMonitorProtocol

    // MARK: - Initialization

    /// Creates a dependency container with production services.
    @MainActor
    public init() {
        self.bonjourServiceScanner = BonjourServiceScanner()
        self.bonjourPublishManager = BonjourPublishManager()
        self.localNetworkMonitor = LocalNetworkMonitor()
    }

    /// Creates a dependency container with custom services (useful for testing or previews).
    public init(
        bonjourServiceScanner: any BonjourServiceScannerProtocol,
        bonjourPublishManager: any BonjourPublishManagerProtocol,
        localNetworkMonitor: any LocalNetworkMonitorProtocol
    ) {
        self.bonjourServiceScanner = bonjourServiceScanner
        self.bonjourPublishManager = bonjourPublishManager
        self.localNetworkMonitor = localNetworkMonitor
    }
}

// MARK: - Mock Factory

extension DependencyContainer {

    /// Creates a dependency container with mock services for testing.
    @MainActor
    public static func mock(
        scanner: MockBonjourServiceScanner = MockBonjourServiceScanner(),
        publishManager: MockBonjourPublishManager = MockBonjourPublishManager(),
        localNetwork: MockLocalNetworkMonitor = MockLocalNetworkMonitor()
    ) -> DependencyContainer {
        return DependencyContainer(
            bonjourServiceScanner: scanner,
            bonjourPublishManager: publishManager,
            localNetworkMonitor: localNetwork
        )
    }

    /// Creates a dependency container configured for SwiftUI
    /// previews. Composes ``MockBonjourServiceScanner`` and
    /// ``MockBonjourPublishManager`` and exposes one extra knob —
    /// `simulateScanning` — that flips the scanner's
    /// `isProcessing` flag so a preview can render the
    /// "scanning…" state without going through any async setup.
    ///
    /// Lives in `BonjourScanning` rather than the app target so
    /// every package that wants to ship a `#Preview` block can
    /// reach for the same factory without re-defining its own
    /// mock plumbing.
    @MainActor
    public static func preview(
        simulateScanning: Bool = false,
        simulateOnLocalNetwork: Bool = true
    ) -> DependencyContainer {
        let scanner = MockBonjourServiceScanner()
        let publishManager = MockBonjourPublishManager()
        let localNetwork = MockLocalNetworkMonitor(
            initialIsOnLocalNetwork: simulateOnLocalNetwork
        )

        if simulateScanning {
            scanner.isProcessing = true
        }

        return DependencyContainer(
            bonjourServiceScanner: scanner,
            bonjourPublishManager: publishManager,
            localNetworkMonitor: localNetwork
        )
    }
}

// MARK: - Environment Values

public extension EnvironmentValues {
    /// The application's dependency container, accessible via `@Environment(\.dependencies)`.
    ///
    /// The default uses `MainActor.assumeIsolated` because the
    /// production `DependencyContainer.init()` is main-actor-isolated
    /// (it constructs the live `BonjourServiceScanner` and
    /// `BonjourPublishManager`) and `@Entry`'s macro generates the
    /// default-value site in a nonisolated context. SwiftUI always
    /// evaluates environment values on the main actor in practice,
    /// so the runtime check never trips.
    @Entry var dependencies: DependencyContainer = MainActor.assumeIsolated { DependencyContainer() }
}

// MARK: - View Extension

public extension View {
    /// Inject a custom dependency container into the view hierarchy.
    func dependencies(_ container: DependencyContainer) -> some View {
        self.environment(\.dependencies, container)
    }
}
