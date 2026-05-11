//
//  LocalNetworkMonitor.swift
//  LocalNetworkMonitor
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Network
import os

// MARK: - LocalNetworkMonitor

/// Production implementation of ``LocalNetworkMonitorProtocol`` backed
/// by Apple's `Network.framework` `NWPathMonitor`.
///
/// "On local network" is defined as a satisfied path that uses Wi-Fi
/// (every Apple platform) or wired Ethernet (Mac). Cellular-only and
/// offline both report as `false` — Bonjour / mDNS doesn't traverse
/// either of those, so consuming UIs can render a distinct, actionable
/// empty state instead of the generic "no results found".
///
/// ## Lifetime
///
/// Typically owned by a long-lived view model. The monitor stays
/// running for the life of that owner; calls to ``stop()`` cancel the
/// underlying `NWPathMonitor` and the class doesn't hold a reference
/// cycle to the system queue, so deallocation is clean even if
/// `stop()` is missed.
///
/// ## Threading
///
/// `NWPathMonitor` delivers path updates on a dispatch queue we
/// provide (a dedicated serial queue). The classification step
/// (`Wi-Fi or Ethernet?`) runs there; results are then hopped to the
/// main actor before mutating state or notifying the delegate. From
/// the consumer's perspective the API is entirely `@MainActor`.
@MainActor
public final class LocalNetworkMonitor: LocalNetworkMonitorProtocol {

    // MARK: - Properties

    public weak var delegate: LocalNetworkMonitorDelegate?

    /// Optimistically `true` until the first `NWPathMonitor` update
    /// arrives. Path updates land near-immediately after ``start()``,
    /// so the optimistic default avoids a one-frame flash of "no local
    /// network" UI while the framework is initializing.
    public private(set) var isOnLocalNetwork: Bool = true

    private let pathMonitor = NWPathMonitor()

    /// Dedicated serial queue for `NWPathMonitor` callbacks. The
    /// monitor delivers path updates on this queue; we hop to the
    /// main actor before mutating state or notifying the delegate.
    private let monitorQueue = DispatchQueue(
        label: "com.kozinga.LocalNetworkMonitor",
        qos: .utility
    )

    private var isStarted: Bool = false

    private let logger = Logger(
        subsystem: "com.kozinga.LocalNetworkMonitor",
        category: "LocalNetworkMonitor"
    )

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
    ///
    /// Internal so test code can drive the classifier directly with
    /// synthetic `NWPath` values, but not exposed publicly because
    /// the rule is part of the package's contract and shouldn't be
    /// negotiable from outside.
    nonisolated static func isLocalNetworkPath(_ path: NWPath) -> Bool {
        guard path.status == .satisfied else { return false }
        return path.usesInterfaceType(.wifi) || path.usesInterfaceType(.wiredEthernet)
    }

    private func handlePathUpdate(isOnLocalNetwork newValue: Bool) {
        guard newValue != self.isOnLocalNetwork else { return }
        self.isOnLocalNetwork = newValue
        logger.info("Connectivity changed: isOnLocalNetwork=\(newValue, privacy: .public)")
        delegate?.localNetworkMonitor(didChangeIsOnLocalNetwork: newValue)
    }
}
