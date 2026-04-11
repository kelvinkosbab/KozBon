// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// MARK: - Shared Settings

/// Shared Swift settings applied to all targets.
let sharedSwiftSettings: [SwiftSetting] = [
    .swiftLanguageMode(.v6)
]

// MARK: - Target Helpers

/// Creates a source target and optionally a test target for a module.
///
/// Assumes the directory layout:
/// ```
/// {name}/
///     Sources/
///     Tests/       (if hasTests is true)
/// ```
func makeTargets(
    name: String,
    dependencies: [Target.Dependency] = [],
    hasTests: Bool = false,
    resources: [Resource]? = nil,
    testDependencies: [Target.Dependency] = [],
    testResources: [Resource]? = nil
) -> [Target] {
    var targets: [Target] = [
        .target(
            name: name,
            dependencies: dependencies,
            path: "\(name)/Sources",
            resources: resources,
            swiftSettings: sharedSwiftSettings
        )
    ]
    if hasTests {
        targets.append(
            .testTarget(
                name: "\(name)Tests",
                dependencies: [.byName(name: name)] + testDependencies,
                path: "\(name)/Tests",
                resources: testResources,
                swiftSettings: sharedSwiftSettings
            )
        )
    }
    return targets
}

// MARK: - Package

let package = Package(
    name: "KozBonPackages",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .tvOS(.v18),
        .watchOS(.v11),
        .visionOS(.v2)
    ],
    products: [
        .library(name: "BonjourCore", targets: ["BonjourCore"]),
        .library(name: "BonjourData", targets: ["BonjourData"]),
        .library(name: "BonjourModels", targets: ["BonjourModels"]),
        .library(name: "BonjourScanning", targets: ["BonjourScanning"]),
        .library(name: "BonjourLocalization", targets: ["BonjourLocalization"]),
        .library(name: "BonjourAI", targets: ["BonjourAI"]),
        .library(name: "BonjourStorage", targets: ["BonjourStorage"]),
        .library(name: "BonjourUI", targets: ["BonjourUI"])
    ],
    dependencies: [
        .package(url: "https://github.com/kelvinkosbab/Core.git", branch: "main"),
        .package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", from: "0.63.2")
    ],
    targets: makeTargets(
            name: "BonjourCore",
            dependencies: [.product(name: "Core", package: "Core")],
            hasTests: true
        )
        + makeTargets(
            name: "BonjourData",
            dependencies: ["BonjourCore"],
            // Note: BonjourData tests require Xcode to compile .xcdatamodeld → .momd.
            // Run via: xcodebuild test -workspace KozBon.xcworkspace -scheme KozBonPackages
            hasTests: false,
            resources: [.process("Resources")]
        )
        + makeTargets(
            name: "BonjourLocalization",
            resources: [.process("Resources")]
        )
        + makeTargets(
            name: "BonjourModels",
            dependencies: ["BonjourCore", "BonjourData", "BonjourLocalization"],
            hasTests: true,
            testDependencies: [.byName(name: "BonjourCore")]
        )
        + makeTargets(
            name: "BonjourScanning",
            dependencies: ["BonjourCore", "BonjourModels"],
            hasTests: true,
            testDependencies: [
                .byName(name: "BonjourCore"),
                .byName(name: "BonjourModels")
            ]
        )
        + makeTargets(
            name: "BonjourAI",
            dependencies: ["BonjourCore", "BonjourModels", "BonjourLocalization", "BonjourStorage"],
            hasTests: true,
            testDependencies: [
                .byName(name: "BonjourCore"),
                .byName(name: "BonjourModels")
            ]
        )
        + makeTargets(
            name: "BonjourStorage",
            hasTests: true
        )
        + makeTargets(
            name: "BonjourUI",
            dependencies: [
                "BonjourCore",
                "BonjourModels",
                "BonjourScanning",
                "BonjourData",
                "BonjourLocalization",
                "BonjourAI",
                "BonjourStorage",
                .product(name: "CoreUI", package: "Core")
            ],
            hasTests: true,
            testDependencies: [
                .byName(name: "BonjourCore"),
                .byName(name: "BonjourModels"),
                .byName(name: "BonjourScanning")
            ]
        )
)
