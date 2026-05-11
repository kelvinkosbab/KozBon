//
//  NetworkConnectivityMonitorProtocol.swift
//  BonjourScanning
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - NetworkConnectivityMonitorDelegate

/// Delegate that receives updates when the device's local-network reachability changes.
///
/// "Local network" here means an interface that can carry mDNS / DNS-SD
/// traffic to the local link — Wi-Fi on every Apple platform, plus
/// wired Ethernet on Mac. Cellular alone, or no network at all, both
/// report as *not* on a local network because Bonjour discovery is
/// useless from there.
@MainActor
public protocol NetworkConnectivityMonitorDelegate: AnyObject, Sendable {

    /// Called when the device's local-network reachability changes.
    ///
    /// - Parameter isOnLocalNetwork: `true` when the active path is
    ///   Wi-Fi or wired Ethernet (satisfied), `false` when the device
    ///   is offline or only on cellular.
    func networkConnectivityDidChange(isOnLocalNetwork: Bool)
}

// MARK: - NetworkConnectivityMonitorProtocol

/// Protocol for an object that monitors local-network reachability and
/// notifies a delegate when it changes.
///
/// The Discover tab uses this to render a clearer empty state when the
/// user is offline or on cellular-only — Bonjour scanning would surface
/// nothing in that state anyway, so guiding the user to enable Wi-Fi is
/// more useful than the generic "no services" message.
///
/// Production implementation: ``NetworkConnectivityMonitor`` wraps
/// `Network.framework`'s `NWPathMonitor`. Tests and previews use
/// ``MockNetworkConnectivityMonitor`` which flips the flag synchronously.
@MainActor
public protocol NetworkConnectivityMonitorProtocol: AnyObject, Sendable {

    /// Delegate that receives connectivity-change callbacks.
    var delegate: NetworkConnectivityMonitorDelegate? { get set }

    /// Whether the device currently has a satisfied Wi-Fi or Ethernet
    /// path. Optimistically defaults to `true` so the UI doesn't flash
    /// a "no Wi-Fi" state during the brief window before the first
    /// `NWPathMonitor` update arrives.
    var isOnLocalNetwork: Bool { get }

    /// Begin monitoring. Idempotent — calling twice is a no-op on the
    /// second call. Production implementations start the underlying
    /// `NWPathMonitor`; mocks may just flip an internal flag.
    func start()

    /// Stop monitoring and release any underlying system resources.
    /// Idempotent.
    func stop()
}
