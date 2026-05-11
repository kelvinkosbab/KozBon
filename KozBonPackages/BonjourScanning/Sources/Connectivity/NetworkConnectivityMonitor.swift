//
//  NetworkConnectivityMonitor.swift
//  BonjourScanning
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Network
import BonjourCore

// MARK: - NetworkConnectivityMonitor

/// Production implementation of ``NetworkConnectivityMonitorProtocol``
/// backed by Apple's `Network.framework` `NWPathMonitor`.
///
/// "On local network" is defined as a satisfied path that uses Wi-Fi
/// (every Apple platform) or wired Ethernet (Mac). Cellular-only and
/// offline both report as `false` — Bonjour / mDNS doesn't traverse
/// either, so the discovery UI guides the user to fix it instead of
/// showing the generic "no services found" empty state.
///
/// Lifetime: typically owned by a long-lived view model (Discover tab's
/// ``BonjourServicesViewModel``). The monitor stays running for the
/// life of that view model; calls to ``stop()`` cancel the underlying
/// `NWPathMonitor` and the class doesn't hold a reference cycle to
/// the system queue, so deallocation is clean even if `stop()` is
/// missed.
@MainActor
public final class NetworkConnectivityMonitor: NetworkConnectivityMonitorProtocol {

    // MARK: - Properties

    public weak var delegate: NetworkConnectivityMonitorDelegate?

    /// Optimistically `true` until the first `NWPathMonitor` update
    /// arrives. Path updates land near-immediately after ``start()``,
    /// so the optimistic default avoids a one-frame flash of "no
    /// Wi-Fi" UI while the framework is initializing.
    public private(set) var isOnLocalNetwork: Bool = true

    private let pathMonitor = NWPathMonitor()

    /// Dedicated serial queue for `NWPathMonitor` callbacks. The
    /// monitor delivers path updates on this queue; we hop to the
    /// main actor before mutating state or notifying the delegate.
    private let monitorQueue = DispatchQueue(
        label: "com.kozinga.KozBon.networkConnectivityMonitor",
        qos: .utility
    )

    private var isStarted: Bool = false

    private let logger: Loggable = Logger(category: "NetworkConnectivityMonitor")

    // MARK: - Initialization

    public init() {}

    deinit {
        // Best-effort cleanup if a caller forgot to stop us. `cancel()`
        // is documented as safe to call from any thread.
        pathMonitor.cancel()
    }

    // MARK: - Lifecycle

    public func start() {
        guard !isStarted else { return }
        isStarted = true

        pathMonitor.pathUpdateHandler = { [weak self] path in
            // NWPathMonitor invokes this on `monitorQueue` (a non-main
            // actor context). Decide the new value here, where we can
            // touch the immutable `NWPath` directly, then hop to the
            // main actor for any state / delegate work.
            let newValue = Self.isLocalNetworkPath(path)
            Task { @MainActor [weak self] in
                self?.handlePathUpdate(isOnLocalNetwork: newValue)
            }
        }
        pathMonitor.start(queue: monitorQueue)
        logger.info("Started — initial optimistic state: isOnLocalNetwork=true")
    }

    public func stop() {
        guard isStarted else { return }
        isStarted = false
        pathMonitor.cancel()
        logger.info("Stopped")
    }

    // MARK: - Path Classification

    /// "On local network" means a satisfied path on an interface that
    /// can carry mDNS / DNS-SD to the local link — Wi-Fi everywhere,
    /// plus wired Ethernet on Mac. Cellular alone is explicitly
    /// excluded: the carrier strips mDNS traffic, so even an
    /// otherwise-online iPhone won't discover anything from there.
    ///
    /// `nonisolated` because it's called from `pathUpdateHandler`,
    /// which runs on the dedicated `monitorQueue` (a non-main-actor
    /// context). The function is pure — it only reads immutable
    /// properties of the passed-in `NWPath` — so no isolation is
    /// needed.
    nonisolated private static func isLocalNetworkPath(_ path: NWPath) -> Bool {
        guard path.status == .satisfied else { return false }
        return path.usesInterfaceType(.wifi) || path.usesInterfaceType(.wiredEthernet)
    }

    private func handlePathUpdate(isOnLocalNetwork newValue: Bool) {
        guard newValue != self.isOnLocalNetwork else { return }
        self.isOnLocalNetwork = newValue
        logger.info("Connectivity changed: isOnLocalNetwork=\(newValue)")
        delegate?.networkConnectivityDidChange(isOnLocalNetwork: newValue)
    }
}

// MARK: - BonjourServiceScanner + Protocol Conformance pattern

// (no separate file needed; `final class … : NetworkConnectivityMonitorProtocol`
// already declared above mirrors the BonjourPublishManager pattern.)
