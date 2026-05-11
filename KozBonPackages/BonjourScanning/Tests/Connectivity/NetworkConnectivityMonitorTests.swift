//
//  NetworkConnectivityMonitorTests.swift
//  BonjourScanning
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourScanning

// Lifecycle tests for the production `NetworkConnectivityMonitor`.
//
// We don't drive `NWPathMonitor` synthetically — that machinery
// belongs to Apple and is already battle-tested. The value here is
// confirming our shim is idempotent on start/stop and exposes the
// expected optimistic default, which is what consumers rely on.

@Suite("NetworkConnectivityMonitor")
@MainActor
struct NetworkConnectivityMonitorTests {

    @Test("Initial `isOnLocalNetwork` is optimistically `true`")
    func initialStateIsOptimisticTrue() {
        let monitor = NetworkConnectivityMonitor()
        #expect(monitor.isOnLocalNetwork)
    }

    @Test("`start()` then `stop()` runs cleanly without throwing")
    func startStopLifecycle() {
        let monitor = NetworkConnectivityMonitor()
        monitor.start()
        monitor.stop()
        // No assertion beyond "didn't crash" — the monitor must
        // survive a synchronous start/stop pair without leaking the
        // dispatch queue or the path monitor.
    }

    @Test("`start()` is idempotent — calling it twice is harmless")
    func startIsIdempotent() {
        let monitor = NetworkConnectivityMonitor()
        monitor.start()
        monitor.start()
        monitor.stop()
    }

    @Test("`stop()` is idempotent — calling it on an un-started monitor is harmless")
    func stopIsIdempotentEvenWithoutStart() {
        let monitor = NetworkConnectivityMonitor()
        monitor.stop()
        monitor.stop()
    }

    @Test("Starting again after `stop()` re-arms the monitor cleanly")
    func canStartAfterStop() {
        let monitor = NetworkConnectivityMonitor()
        monitor.start()
        monitor.stop()
        monitor.start()
        monitor.stop()
    }
}
