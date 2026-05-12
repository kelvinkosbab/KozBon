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
///
/// ## Test target dependencies
///
/// The test target automatically gets:
/// 1. The source target itself (`.byName(name: name)`) so test code
///    can `@testable import` it.
/// 2. Every entry in the source target's `dependencies`. Tests almost
///    always need to construct values from the same types the source
///    uses — re-declaring those deps on the test target was pure
///    boilerplate that drifted whenever the source list changed.
///
/// `additionalTestDependencies` is reserved for genuine test-only
/// dependencies — modules used by tests but NOT by the source target
/// (e.g., `BonjourAppIntents`'s tests need `BonjourCore` types even
/// though the App Intents source target itself doesn't import
/// `BonjourCore`). Don't repeat anything from `dependencies` here.
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
        dependencies: [
            "BonjourCore",
            "BonjourModels",
            // Local-network reachability is a sibling target in this
            // same package. `MockLocalNetworkMonitor` is re-exported
            // via `BonjourScanning/Sources/Exports.swift`, so any
            // module that imports `BonjourScanning` automatically
            // sees the monitor types.
            "LocalNetworkMonitor"
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
        ]
    )
    + makeTargets(
        name: "BonjourAICloud",
        // Provider-agnostic cloud-AI scaffolding (credentials,
        // error surface, model selection) plus the Anthropic
        // implementation. Stays separate from `BonjourAI` so the
        // Apple Foundation Models path doesn't pull in Keychain
        // / URLSession code, and so future providers (OpenAI,
        // Gemini) can land here without restructuring `BonjourAI`.
        //
        // Depends on `BonjourAI` for the protocol surface
        // (`BonjourChatSessionProtocol`,
        // `BonjourServiceExplainerProtocol`) that the cloud
        // implementations satisfy. The factories that pick
        // between Apple and cloud live a layer up (in `BonjourUI`
        // / `AppCore` where `PreferencesStore` is read).
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
            // Settings UI surfaces the cloud-backend picker
            // (`AIBackend`), the sign-in sheet (which writes
            // through `AICloudCredentialsStore`), and the Claude
            // model picker (`AnthropicModel`). The Chat /
            // Insights views consume the `AnthropicBonjour*`
            // session and explainer types via the existing
            // protocols; the factory routing that picks between
            // Apple and cloud also lives in BonjourUI because
            // that's where `PreferencesStore` is read.
            "BonjourAICloud",
            "BonjourStorage",
            .product(name: "CoreUI", package: "Core")
        ]
    )
    + makeTargets(
        name: "BonjourAppIntents",
        // The two `AppIntent`s use `BonjourOneShotScanner` from
        // `BonjourScanning` to drive the in-process scan, the
        // `BonjourService.voiceCategoricalSummary()` helper from
        // `BonjourAI` for the spoken breakdown, and
        // `BonjourService` / `BonjourServiceType` types from
        // `BonjourModels` for the entity projection.
        dependencies: [
            "BonjourAI",
            "BonjourModels",
            "BonjourScanning"
        ],
        // `BonjourCore` is a genuine test-only dep — used in
        // `BonjourAppIntents`'s tests but not by the source target,
        // which reaches its needs through `BonjourAI` / `BonjourModels`.
        additionalTestDependencies: [.byName(name: "BonjourCore")]
    )
    + makeTargets(
        name: "AppCore",
        // The app target's `@main` shim imports only `AppCore`. Every
        // piece of business logic, scene definition, dependency
        // wiring, tab plumbing, and macOS-commands configuration
        // lives here, so this target needs to see every Bonjour
        // module the scene tree touches. `CoreUI` is reached via
        // BonjourUI's transitive re-export (`.product` would be
        // explicit, but every other target consumes it the same way).
        //
        // `BonjourAICloud` is a direct dependency too — `AppCoreScene`
        // wires the cloud-aware factories by default, and
        // `TopLevelDestination` picks the chat-tab icon from
        // `AIBackend.icon`.
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
