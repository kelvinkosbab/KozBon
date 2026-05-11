//
//  Exports.swift
//  BonjourScanning
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

// Re-export LocalNetworkMonitor so that modules importing
// BonjourScanning (chiefly BonjourUI and its tests) also see
// `LocalNetworkMonitorProtocol`, `LocalNetworkMonitor`,
// `MockLocalNetworkMonitor`, and `LocalNetworkMonitorDelegate`
// without needing an extra `import LocalNetworkMonitor` next to
// every `import BonjourScanning`. Mirrors the `@_exported import
// Core` pattern that `BonjourCore` uses for `Logger` / `Loggable`.
@_exported import LocalNetworkMonitor
