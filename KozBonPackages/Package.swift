// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// MARK: - Shared Settings

/// Shared Swift settings applied to all targets.
let sharedSwiftSettings: [SwiftSetting] = [
    .swiftLanguageMode(.v6)
]

// MARK: - Target Helpers

/// Creates a source target and a test target for a module.
///
/// Every package in `KozBonPackages/` ships tests — there's no
/// `hasTests` flag because the absence of a test surface for a
/// given module is a problem to fix, not a configuration to
/// support. Adding a new package starts with creating its
/// `Tests/` folder alongside `Sources/`.
///
/// Assumes the directory layout:
/// ```
/// {name}/
///     Sources/
///         Resources/   (if hasResources is true)
///     Tests/
/// ```
///
/// Resources are picked up automatically via `.process("Resources")`
/// when `hasResources` is true — callers don't pass an explicit
/// `[Resource]` array. Any package that needs to ship resources uses
/// a `Sources/Resources/` subfolder, keeping both the manifest and
/// the on-disk layout uniform. No package currently needs *test*
/// resources; if one ever does, add a `hasTestResources: Bool` flag
/// and a matching `Tests/Resources/` directory.
func makeTargets(
    name: String,
    dependencies: [Target.Dependency] = [],
    hasResources: Bool = false,
    testDependencies: [Target.Dependency] = []
) -> [Target] {
    [
        .target(
            name: name,
            dependencies: dependencies,
            path: "\(name)/Sources",
            resources: hasResources ? [.process("Resources")] : nil,
            swiftSettings: sharedSwiftSettings
        ),
        .testTarget(
            name: "\(name)Tests",
            dependencies: [.byName(name: name)] + testDependencies,
            path: "\(name)/Tests",
            swiftSettings: sharedSwiftSettings
        )
    ]
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
        dependencies: [.product(name: "Core", package: "Core")]
    )
    + makeTargets(
        name: "BonjourLocalization",
        hasResources: true
    )
    + makeTargets(
        name: "BonjourModels",
        dependencies: ["BonjourCore", "BonjourStorage", "BonjourLocalization"],
        testDependencies: [.byName(name: "BonjourCore")]
    )
    + makeTargets(
        name: "BonjourScanning",
        dependencies: ["BonjourCore", "BonjourModels"],
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
        // user-defined service types. SwiftData tests run fine under
        // both runtimes. The Core Data tests need `.xcdatamodeld`
        // compiled to `.momd` — only Xcode does that — so under
        // `swift test` from the SPM CLI, `MyCoreDataStack` can't load
        // the model. Each Core Data test guards on
        // `MyCoreDataStack.isBundledModelAvailable` and skips silently
        // when the model isn't reachable, so the SPM test target
        // builds without `testExcludes` and runs the same source file
        // under both `swift test` (where it skips) and
        // `xcodebuild test` (where it asserts).
        hasResources: true
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
        testDependencies: [
            .byName(name: "BonjourCore"),
            .byName(name: "BonjourModels"),
            .byName(name: "BonjourScanning")
        ]
    )
)
