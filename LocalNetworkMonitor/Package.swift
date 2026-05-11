// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// MARK: - Package

/// A small, focused Swift package that detects whether the device is
/// currently on a network interface that can carry local-link traffic
/// like Bonjour / mDNS / DNS-SD. Wraps `Network.framework`'s
/// `NWPathMonitor` behind a `@MainActor` delegate API and ships a
/// synchronous mock for tests.
///
/// Extracted out of the KozBon app where it powers the Discover tab's
/// "Not connected to Wi-Fi" empty state. The API has no dependency on
/// KozBon — any app that needs to know "can I do mDNS right now" can
/// adopt it.
let package = Package(
    name: "LocalNetworkMonitor",
    // Minimums chosen to match the oldest OS that supports the full
    // API surface used: `NWPathMonitor`, structured concurrency
    // (`@MainActor`, `Task`), and the unified `os.Logger` API with
    // privacy interpolation. KozBon itself targets higher minimums
    // for unrelated reasons (FoundationModels, Liquid Glass) — this
    // package stays liberal so other consumers can adopt it freely.
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
        .tvOS(.v14),
        .watchOS(.v7),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "LocalNetworkMonitor", targets: ["LocalNetworkMonitor"])
    ],
    targets: [
        .target(
            name: "LocalNetworkMonitor",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "LocalNetworkMonitorTests",
            dependencies: ["LocalNetworkMonitor"],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
