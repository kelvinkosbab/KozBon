//
//  IntentScanTests.swift
//  BonjourAppIntents
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourScanning
import LocalNetworkMonitor
@testable import BonjourAppIntents

// MARK: - IntentScanTests

@Suite("IntentScan")
@MainActor
struct IntentScanTests {

    @Test("Reports the network monitor's state alongside the scan")
    func reportsOffNetwork() async {
        let monitor = MockLocalNetworkMonitor(initialIsOnLocalNetwork: false)
        let result = await IntentScan.run(
            scanner: MockBonjourServiceScanner(),
            networkMonitor: monitor,
            timeout: .zero
        )
        #expect(result.services.isEmpty)
        #expect(!result.isOnLocalNetwork)
    }

    @Test("Starts the network monitor for the scan and stops it after")
    func startsAndStopsMonitor() async {
        let monitor = MockLocalNetworkMonitor()
        let scanner = MockBonjourServiceScanner()
        _ = await IntentScan.run(scanner: scanner, networkMonitor: monitor, timeout: .zero)
        #expect(monitor.startCallCount == 1)
        #expect(monitor.stopCallCount == 1)
        #expect(scanner.startScanCallCount == 1)
        #expect(scanner.stopScanCallCount == 1)
    }
}
