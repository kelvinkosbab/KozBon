//
//  InternetConnectivityMonitorProtocol.swift
//  InternetConnectivity
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Observation

// MARK: - InternetConnectivityMonitorProtocol

/// An object that reports whether the device can currently reach the
/// internet.
///
/// Conformers are `@Observable`, so a SwiftUI view that reads
/// ``isConnected`` through the `internetConnectivity` environment value
/// re-renders when the device goes offline or comes back.
///
/// Production implementation: ``InternetConnectivityMonitor``, backed by
/// `NWPathMonitor`. Tests and previews use
/// ``MockInternetConnectivityMonitor``.
///
/// This answers a different question from `LocalNetworkMonitor`:
/// Bonjour needs the local link (Wi-Fi or Ethernet) and works with no
/// internet at all, while a cloud API needs a route to the internet
/// and works fine over cellular.
@MainActor
public protocol InternetConnectivityMonitorProtocol: AnyObject, Observable, Sendable {

    /// Whether the device has a usable path to the internet. Defaults
    /// to `true` until the first path update so the UI doesn't flash an
    /// offline state at launch.
    var isConnected: Bool { get }

    /// Begins monitoring. Idempotent.
    func start()

    /// Stops monitoring and releases system resources. Idempotent.
    func stop()
}

// MARK: - Requirement Checks

public extension InternetConnectivityMonitorProtocol {

    /// Whether a feature with the given requirement can run right now.
    func canSatisfy(_ requirement: ConnectivityRequirement) -> Bool {
        requirement.isSatisfied(isConnected: isConnected)
    }
}
