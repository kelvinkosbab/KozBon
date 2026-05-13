// swift-tools-version: 6.2

import PackageDescription

// MARK: - Shared Settings

let sharedSwiftSettings: [SwiftSetting] = [
    .swiftLanguageMode(.v6)
]

// MARK: - Target Helpers

/// Creates a paired source + test target for a module at
/// `{name}/Sources` and `{name}/Tests`. Set `hasResources: true`
/// to ship `Sources/Resources/` via `.process`. The test target
/// auto-inherits every entry in `dependencies`;
/// `additionalTestDependencies` is for modules tests need but
/// the source target doesn't.
func makeTargets(
    name: String,
    dependencies: [Target.Dependency] = [],
    hasResources: Bool = false,
    additionalTestDependencies: [Target.Dependency] = []
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
            dependencies: [.byName(name: name)] + dependencies + additionalTestDependencies,
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
        .library(name: "BonjourAICloud", targets: ["BonjourAICloud"]),
        .library(name: "BonjourStorage", targets: ["BonjourStorage"]),
        .library(name: "BonjourUI", targets: ["BonjourUI"]),
        .library(name: "BonjourAppIntents", targets: ["BonjourAppIntents"]),
        .library(name: "AppCore", targets: ["AppCore"]),
        .library(name: "LocalNetworkMonitor", targets: ["LocalNetworkMonitor"])
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
        dependencies: ["BonjourCore", "BonjourStorage", "BonjourLocalization"]
    )
    + makeTargets(
        name: "LocalNetworkMonitor"
    )
    + makeTargets(
        name: "BonjourScanning",
        dependencies: ["BonjourCore", "BonjourModels", "LocalNetworkMonitor"]
    )
    + makeTargets(
        name: "BonjourAI",
        dependencies: [
            "BonjourCore",
            "BonjourModels",
            "BonjourLocalization",
            "BonjourScanning",
            "BonjourStorage"
        ]
    )
    + makeTargets(
        name: "BonjourAICloud",
        // Depends on `BonjourAI` for the protocol surface the
        // cloud implementations satisfy.
        dependencies: [
            "BonjourCore",
            "BonjourModels",
            "BonjourLocalization",
            "BonjourScanning",
            "BonjourStorage",
            "BonjourAI"
        ]
    )
    + makeTargets(
        name: "BonjourStorage",
        dependencies: ["BonjourCore"],
        // Ships the Core Data `.xcdatamodeld` for custom service
        // types. Tests that touch Core Data guard on
        // `MyCoreDataStack.isBundledModelAvailable` and skip
        // under `swift test` (which can't compile the model);
        // they assert under `xcodebuild test`.
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
            "BonjourAICloud",
            "BonjourStorage",
            .product(name: "CoreUI", package: "Core")
        ],
        // Ships the Claude brand mark in `Media.xcassets`.
        hasResources: true
    )
    + makeTargets(
        name: "BonjourAppIntents",
        dependencies: ["BonjourAI", "BonjourModels", "BonjourScanning"],
        // `BonjourCore` is reached transitively at runtime but
        // the tests construct its types directly.
        additionalTestDependencies: [.byName(name: "BonjourCore")]
    )
    + makeTargets(
        name: "AppCore",
        dependencies: [
            "BonjourCore",
            "BonjourModels",
            "BonjourScanning",
            "BonjourLocalization",
            "BonjourAI",
            "BonjourAICloud",
            "BonjourStorage",
            "BonjourUI",
            .product(name: "CoreUI", package: "Core")
        ]
    )
)
