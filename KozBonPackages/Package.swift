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
    testResources: [Resource]? = nil,
    testExcludes: [String] = []
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
                exclude: testExcludes,
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
        name: "BonjourLocalization",
        resources: [.process("Resources")]
    )
    + makeTargets(
        name: "BonjourModels",
        dependencies: ["BonjourCore", "BonjourStorage", "BonjourLocalization"],
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
        // BonjourScanning is a real dependency: `BonjourChatSession`
        // imports `BonjourPublishManagerProtocol` from it so the
        // stop-broadcast tool can query the user's active broadcasts.
        // SPM compiled this fine in non-archive builds because the
        // workspace happened to surface the module transitively, but
        // archive builds (with stricter dependency-scan validation)
        // promoted the missing-explicit-dependency warning to an
        // error. Listing it here is the canonical fix.
        dependencies: [
            "BonjourCore",
            "BonjourModels",
            "BonjourLocalization",
            "BonjourScanning",
            "BonjourStorage"
        ],
        hasTests: true,
        testDependencies: [
            .byName(name: "BonjourCore"),
            .byName(name: "BonjourModels")
        ]
    )
    + makeTargets(
        name: "BonjourStorage",
        dependencies: ["BonjourCore"],
        // BonjourStorage owns both the SwiftData preferences container
        // and the legacy Core Data store (`iDiscover.xcdatamodeld`) for
        // user-defined service types. The SwiftData tests run fine
        // under `swift test` *and* `xcodebuild test`. The Core Data
        // tests need `.xcdatamodeld` compiled to `.momd`, which only
        // Xcode does — so `CustomServiceTypeTests.swift` is excluded
        // from the SPM test target and runs via `xcodebuild test`
        // exclusively.
        hasTests: true,
        resources: [.process("Resources")],
        testExcludes: ["CustomServiceTypeTests.swift"]
    )
    + makeTargets(
        name: "BonjourUI",
        dependencies: [
            "BonjourCore",
            "BonjourModels",
            "BonjourScanning",
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
