//
//  BonjourServicesViewModelConnectivityTests.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourUI
import BonjourScanning

// Tests for the `BonjourServicesViewModel`'s integration with
// `NetworkConnectivityMonitor`. Lives in its own file (parallel to
// `BonjourServicesViewModelTests.swift`) so neither file overflows the
// 500-line SwiftLint guidance.

@Suite("BonjourServicesViewModel · Network Connectivity")
@MainActor
struct BonjourServicesViewModelConnectivityTests {

    @Test("VM seeds `isOnLocalNetwork` from the monitor's initial value")
    func vmSeedsConnectivityFromMonitor() {
        let scanner = MockBonjourServiceScanner()
        let publishManager = MockBonjourPublishManager()
        let connectivity = MockLocalNetworkMonitor(initialIsOnLocalNetwork: false)
        let viewModel = BonjourServicesViewModel(
            serviceScanner: scanner,
            publishManager: publishManager,
            localNetworkMonitor: connectivity
        )
        #expect(!viewModel.isOnLocalNetwork)
    }

    @Test("VM defaults `isOnLocalNetwork` to `true` when monitor reports `true`")
    func vmDefaultsToOptimisticTrue() {
        let scanner = MockBonjourServiceScanner()
        let publishManager = MockBonjourPublishManager()
        let viewModel = BonjourServicesViewModel(
            serviceScanner: scanner,
            publishManager: publishManager,
            localNetworkMonitor: MockLocalNetworkMonitor()
        )
        #expect(viewModel.isOnLocalNetwork)
    }

    @Test("VM registers itself as the monitor's delegate at init")
    func vmRegistersAsConnectivityDelegate() {
        let scanner = MockBonjourServiceScanner()
        let publishManager = MockBonjourPublishManager()
        let connectivity = MockLocalNetworkMonitor()
        let viewModel = BonjourServicesViewModel(
            serviceScanner: scanner,
            publishManager: publishManager,
            localNetworkMonitor: connectivity
        )
        #expect(connectivity.delegate === viewModel)
    }

    @Test("VM calls `start()` on the monitor at init")
    func vmStartsMonitorAtInit() {
        let scanner = MockBonjourServiceScanner()
        let publishManager = MockBonjourPublishManager()
        let connectivity = MockLocalNetworkMonitor()
        _ = BonjourServicesViewModel(
            serviceScanner: scanner,
            publishManager: publishManager,
            localNetworkMonitor: connectivity
        )
        #expect(connectivity.startCallCount == 1)
    }

    @Test("`isOnLocalNetwork` mirrors connectivity changes reported by the monitor")
    func vmReflectsConnectivityChanges() {
        let scanner = MockBonjourServiceScanner()
        let publishManager = MockBonjourPublishManager()
        let connectivity = MockLocalNetworkMonitor()
        let viewModel = BonjourServicesViewModel(
            serviceScanner: scanner,
            publishManager: publishManager,
            localNetworkMonitor: connectivity
        )

        #expect(viewModel.isOnLocalNetwork)
        connectivity.isOnLocalNetwork = false
        #expect(!viewModel.isOnLocalNetwork)
        connectivity.isOnLocalNetwork = true
        #expect(viewModel.isOnLocalNetwork)
    }
}
