//
//  MockInternetConnectivityMonitorTests.swift
//  InternetConnectivity
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Testing
import InternetConnectivity

// MARK: - MockInternetConnectivityMonitorTests

@Suite("MockInternetConnectivityMonitor")
@MainActor
struct MockInternetConnectivityMonitorTests {

    @Test("Defaults to connected")
    func defaultsToConnected() {
        #expect(MockInternetConnectivityMonitor().isConnected)
    }

    @Test("Connectivity is settable")
    func connectivityIsSettable() {
        let monitor = MockInternetConnectivityMonitor()
        monitor.isConnected = false
        #expect(!monitor.isConnected)
        #expect(!monitor.canSatisfy(.internet))
        #expect(monitor.canSatisfy(.none))
    }

    @Test("Counts lifecycle calls")
    func countsLifecycleCalls() {
        let monitor = MockInternetConnectivityMonitor()
        monitor.start()
        monitor.start()
        monitor.stop()
        #expect(monitor.startCallCount == 2)
        #expect(monitor.stopCallCount == 1)
    }
}
