//
//  IntentScan.swift
//  BonjourAppIntents
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourModels
import BonjourScanning
import LocalNetworkMonitor

// MARK: - IntentScanResult

struct IntentScanResult {
    let services: [BonjourService]

    /// Whether the device had a Wi-Fi or Ethernet path during the scan,
    /// so an empty result can say why.
    let isOnLocalNetwork: Bool
}

// MARK: - IntentScan

/// The one-shot scan both Siri actions run, with a network check
/// alongside it.
@MainActor
enum IntentScan {

    static func run(
        scanner: BonjourServiceScannerProtocol = BonjourServiceScanner(),
        networkMonitor: LocalNetworkMonitorProtocol = LocalNetworkMonitor(),
        timeout: Duration = BonjourOneShotScanner.defaultTimeout
    ) async -> IntentScanResult {
        networkMonitor.start()
        defer { networkMonitor.stop() }
        let services = await BonjourOneShotScanner(scanner: scanner).run(timeout: timeout)
        return IntentScanResult(services: services, isOnLocalNetwork: networkMonitor.isOnLocalNetwork)
    }
}
