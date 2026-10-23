//
//  MockInternetConnectivityMonitor.swift
//  InternetConnectivity
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Observation

// MARK: - MockInternetConnectivityMonitor

/// Settable ``InternetConnectivityMonitorProtocol`` for tests and
/// previews. Flip ``isConnected`` to simulate dropping or regaining the
/// connection without touching the network stack.
@MainActor
@Observable
public final class MockInternetConnectivityMonitor: InternetConnectivityMonitorProtocol {

    public var isConnected: Bool

    /// The number of times ``start()`` has been called.
    public private(set) var startCallCount = 0

    /// The number of times ``stop()`` has been called.
    public private(set) var stopCallCount = 0

    /// - Parameter isConnected: Initial connectivity. Defaults to
    ///   `true`, matching the production monitor before its first
    ///   path update.
    public init(isConnected: Bool = true) {
        self.isConnected = isConnected
    }

    public func start() {
        startCallCount += 1
    }

    public func stop() {
        stopCallCount += 1
    }
}
