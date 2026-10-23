//
//  InternetConnectivityMonitorTests.swift
//  InternetConnectivity
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Network
import Testing
@testable import InternetConnectivity

// MARK: - InternetConnectivityMonitorTests

@Suite("InternetConnectivityMonitor")
@MainActor
struct InternetConnectivityMonitorTests {

    @Test("Starts optimistically connected")
    func initialStateIsConnected() {
        #expect(InternetConnectivityMonitor().isConnected)
    }

    @Test("Only a satisfied path counts as connected")
    func classifiesPathStatus() {
        #expect(InternetConnectivityMonitor.isConnected(status: .satisfied))
        #expect(!InternetConnectivityMonitor.isConnected(status: .unsatisfied))
        #expect(!InternetConnectivityMonitor.isConnected(status: .requiresConnection))
    }

    @Test("Start and stop are idempotent and can re-arm")
    func lifecycleIsIdempotent() {
        let monitor = InternetConnectivityMonitor()
        monitor.stop()
        monitor.start()
        monitor.start()
        monitor.stop()
        monitor.stop()
        monitor.start()
        monitor.stop()
    }
}
