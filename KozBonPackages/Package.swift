// swift-tools-version: 6.2

import PackageDescription

// MARK: - Shared Settings

let sharedSwiftSettings: [SwiftSetting] = [
    .swiftLanguageMode(.v6)
]

// MARK: - Target Helpers

/// Creates a paired source + test target for a module at
/// `{name}/Sources` and `{name}/Tests`. Set `hasResources: true`
/// to ship `Sources/Resources/` via `.process`. Set
/// `hasTests: false` to skip emitting a test target — for
/// modules that have no tests yet (provider-specific shims that
/// are exercised entirely through their parent's integration
/// tests). The test target auto-inherits every entry in
/// `dependencies`; `additionalTestDependencies` is for modules
/// tests need but the source target doesn't.
func makeTargets(
    name: String,
    dependencies: [Target.Dependency] = [],
    hasResources: Bool = false,
    hasTests: Bool = true,
    additionalTestDependencies: [Target.Dependency] = []
) -> [Target] {
    var targets: [Target] = [
        .target(
            name: name,
            dependencies: dependencies,
            path: "\(name)/Sources",
            resources: hasResources ? [.process("Resources")] : nil,
            swiftSettings: sharedSwiftSettings
        )
    ]
    if hasTests {
        targets.append(
            .testTarget(
                name: "\(name)Tests",
                dependencies: [.byName(name: name)] + dependencies + additionalTestDependencies,
                path: "\(name)/Tests",
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
        .library(name: "BonjourAICore", targets: ["BonjourAICore"]),
        .library(name: "BonjourAIApple", targets: ["BonjourAIApple"]),
        .library(name: "BonjourAIAnthropic", targets: ["BonjourAIAnthropic"]),
        .library(name: "BonjourAIGitHub", targets: ["BonjourAIGitHub"]),
        .library(name: "BonjourAI", targets: ["BonjourAI"]),
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
        name: "BonjourAICore",
        dependencies: [
            "BonjourCore",
            "BonjourModels",
            "BonjourLocalization",
            "BonjourScanning",
            "BonjourStorage"
        ]
    )
    + makeTargets(
        name: "BonjourAIApple",
        dependencies: [
            "BonjourAICore",
            "BonjourCore",
            "BonjourModels",
            "BonjourLocalization",
            "BonjourScanning",
            "BonjourStorage"
        ]
    )
    + makeTargets(
        name: "BonjourAIAnthropic",
        dependencies: [
            "BonjourAICore",
            "BonjourCore",
            "BonjourModels",
            "BonjourLocalization",
            "BonjourScanning",
            "BonjourStorage"
        ],
        // Ships the official Anthropic brand mark in
        // `Media.xcassets/Claude.imageset/` plus the
        // `Image.anthropicClaude` accessor that wraps it —
        // colocated so the SwiftPM-generated `Bundle.module`
        // resolves correctly without exposing a separate
        // public bundle handle.
        hasResources: true
    )
    + makeTargets(
        name: "BonjourAIGitHub",
        dependencies: [
            "BonjourAICore",
            "BonjourCore",
            "BonjourModels",
            "BonjourLocalization",
            "BonjourScanning",
            "BonjourStorage"
        ],
        // Ships GitHub's Octocat
        // (`Media.xcassets/GitHub.imageset/`) plus the
        // `Image.github` accessor — same colocation pattern as
        // BonjourAIAnthropic.
        hasResources: true
    )
    + makeTargets(
        name: "BonjourAI",
        // Umbrella: re-exports `BonjourAICore` and hosts the
        // cloud-aware routing factories that sit above the
        // Apple-, Anthropic-, and GitHub-Models-specific modules.
        dependencies: [
            "BonjourAICore",
            "BonjourAIApple",
            "BonjourAIAnthropic",
            "BonjourAIGitHub",
            "BonjourCore",
            "BonjourModels",
            "BonjourLocalization",
            "BonjourScanning",
            "BonjourStorage"
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
            "BonjourAIApple",
            "BonjourAIAnthropic",
            "BonjourAIGitHub",
            "BonjourStorage",
            .product(name: "CoreUI", package: "Core")
        ]
        // Brand marks moved to the per-provider modules
        // (`BonjourAIAnthropic` ships Claude;
        // `BonjourAIGitHub` ships the Octocat). BonjourUI no
        // longer ships any resources of its own.
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
            "BonjourAIApple",
            "BonjourAIAnthropic",
            "BonjourAIGitHub",
            "BonjourStorage",
            "BonjourUI",
            .product(name: "CoreUI", package: "Core")
        ]
    )
)
