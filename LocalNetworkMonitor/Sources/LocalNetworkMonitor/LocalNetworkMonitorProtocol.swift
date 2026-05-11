//
//  LocalNetworkMonitorProtocol.swift
//  LocalNetworkMonitor
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - LocalNetworkMonitorDelegate

/// Delegate that receives updates when the device's local-network
/// reachability changes.
///
/// "Local network" here means an interface that can carry mDNS / DNS-SD
/// traffic to the local link — Wi-Fi on every Apple platform, plus
/// wired Ethernet on Mac. Cellular alone, or no network at all, both
/// report as *not* on a local network because Bonjour discovery is
/// useless from there.
@MainActor
public protocol LocalNetworkMonitorDelegate: AnyObject, Sendable {

    /// Called when the device's local-network reachability changes.
    ///
    /// - Parameter isOnLocalNetwork: `true` when the active path is
    ///   Wi-Fi or wired Ethernet (satisfied), `false` when the device
    ///   is offline or only on cellular.
    func localNetworkMonitor(didChangeIsOnLocalNetwork isOnLocalNetwork: Bool)
}

// MARK: - LocalNetworkMonitorProtocol

/// Protocol for an object that monitors local-network reachability and
/// notifies a delegate when it changes.
///
/// Production implementation: ``LocalNetworkMonitor`` wraps
/// `Network.framework`'s `NWPathMonitor`. Tests and previews use
/// ``MockLocalNetworkMonitor`` which flips the flag synchronously.
///
/// ## Use cases
///
/// Anything that depends on local-link multicast — Bonjour browsing,
/// AirPlay receiver discovery, Chromecast / DLNA scanning, mDNS-based
/// LAN service catalogs — needs to know when the device can actually
/// see the local network. Showing a generic "no devices found" empty
/// state when the user is on cellular is a UX dead end; this
/// abstraction lets you tell them why.
///
/// ## Example
///
/// ```swift
/// @MainActor
/// final class MyViewModel: LocalNetworkMonitorDelegate {
///     private let monitor: any LocalNetworkMonitorProtocol = LocalNetworkMonitor()
///
///     init() {
///         monitor.delegate = self
///         monitor.start()
///     }
///
///     func localNetworkMonitor(didChangeIsOnLocalNetwork isOnLocalNetwork: Bool) {
///         self.isOnLocalNetwork = isOnLocalNetwork
///     }
/// }
/// ```
@MainActor
public protocol LocalNetworkMonitorProtocol: AnyObject, Sendable {

    /// Delegate that receives connectivity-change callbacks.
    var delegate: LocalNetworkMonitorDelegate? { get set }

    /// Whether the device currently has a satisfied Wi-Fi or Ethernet
    /// path. Optimistically defaults to `true` so the UI doesn't flash
    /// a "no local network" state during the brief window before the
    /// first `NWPathMonitor` update arrives after ``start()``.
    var isOnLocalNetwork: Bool { get }

    /// Begin monitoring. Idempotent — calling twice is a no-op on the
    /// second call. Production implementations start the underlying
    /// `NWPathMonitor`; mocks may just flip an internal flag.
    func start()

    /// Stop monitoring and release any underlying system resources.
    /// Idempotent.
    func stop()
}
