# CLAUDE.md

## Project Overview

KozBon is a multi-platform Apple app for discovering and managing Bonjour (mDNS) network services. Bundle ID: `com.kozinga.KozBon`.

## Working with Claude

Agent execution conventions — plan multi-step edits before executing, fix course-corrections silently (no "I made a mess" / "let me clean that up" filler), prefer one atomic `Edit` over a chain of small ones — are documented in [`.claude/rules/claude-execution-discipline.md`](.claude/rules/claude-execution-discipline.md). The rule loads automatically into every Claude Code session in this repo.

## Build & Run

```bash
# Build for iOS Simulator
xcodebuild -workspace KozBon.xcworkspace -scheme KozBon -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' build

# Build for macOS
xcodebuild -workspace KozBon.xcworkspace -scheme KozBon -destination 'platform=macOS' build

# Build for visionOS Simulator
xcodebuild -workspace KozBon.xcworkspace -scheme KozBon -destination 'platform=visionOS Simulator,name=Apple Vision Pro' build

# Run tests — all tests live in the SPM package
swift test --package-path KozBonPackages
```

The `KozBon` scheme has no test action configured; all tests run through SPM.

## Architecture

- **Swift 6.2** with strict concurrency checking (`SWIFT_STRICT_CONCURRENCY = complete`)
- **SwiftUI** with MVVM pattern, targeting iOS 18.6+, macOS 15.6+, tvOS 18.0+, watchOS 11.0+, visionOS 2.0+
  - View-model conventions are documented in [`.claude/rules/apple-swiftui-mvvm.md`](.claude/rules/apple-swiftui-mvvm.md) — when to use a VM, `@State` vs `@Bindable` ownership, dependency-plumbing rules, splitting large VMs across companion files
- **Modular SPM packages** via `KozBonPackages/` local package in the Xcode workspace
- **Dependency Injection** via `DependencyContainer` (in `BonjourScanning` module) using SwiftUI environment (`@Environment(\.dependencies)`)
- **Core Data** for persistence (`iDiscover.xcdatamodeld`) — all Core Data access is `@MainActor` via `viewContext`
- **Localization** via `BonjourLocalization` module with String Catalog (`.xcstrings`) — 8 languages supported, including right-to-left (Arabic, Hebrew)
- Protocol-based abstractions: `BonjourServiceScannerProtocol`, `BonjourPublishManagerProtocol`

## Project Structure

### Workspace

`KozBon.xcworkspace` contains:
- `KozBon.xcodeproj` — the app target (5 Swift files)
- `KozBonPackages/` — local SPM package (11 modules)

### App Target (KozBon/)

Only the app entry point and wiring:
- `AppCore.swift` — @main entry point, tab configuration, macOS commands
- `TopLevelDestination.swift` — tab definitions
- `BonjourNearbyServices/PreviewDependencies.swift` — preview helpers
- `BonjourNearbyServices/DependencyInjectionExamples.swift` — DI documentation and examples

### SPM Modules (KozBonPackages/)

Each module follows the `{name}/Sources` and `{name}/Tests` layout:

| Module | Purpose | Key Types |
|--------|---------|-----------|
| **BonjourCore** | Value types, constants, utilities | `Constants`, `TransportLayer`, `InternetAddress`, `Logger`, `Clipboard` |
| **BonjourStorage** | Persistence — SwiftData preferences + Core Data custom-service-type store | `PreferencesStore`, `UserPreferences`, `CustomServiceType`, `MyCoreDataStack`, `MyDataManagerObject` |
| **BonjourLocalization** | Localized strings (8 languages, including RTL: ar, he) | `Strings` enum, `Localizable.xcstrings` |
| **BonjourModels** | Domain models and service library | `BonjourServiceType`, `BonjourService`, `BonjourServiceSortType` |
| **BonjourScanning** | Network discovery and publishing | `BonjourServiceScanner`, `MyBonjourPublishManager`, `DependencyContainer`, mocks |
| **BonjourAICore** | Provider-agnostic AI scaffolding — protocols, value types, prompt builders, safety, mocks, simulator stubs, UI primitives, credentials-store protocol + Keychain/InMemory impls | `BonjourChatSessionProtocol`, `BonjourServiceExplainerProtocol`, `BonjourChatPromptBuilder`, `BonjourServicePromptBuilder`, `AIBackend`, `AICloudProvider`, `AICloudCredentialsStore`, `AICloudError`, `KeychainAICloudCredentialsStore`, `InMemoryAICloudCredentialsStore`, `MockBonjourChatSession`, `MockBonjourServiceExplainer`, `ServiceExplanationSheet`, `MarkdownContentView`, `TypingIndicator` |
| **BonjourAIApple** | Apple Foundation Models implementations of the BonjourAICore protocols | `BonjourChatSession`, `BonjourChatSessionFactory`, `BonjourServiceExplainer`, `BonjourServiceExplainerFactory`, `AppleIntelligenceSupport`, `AIContextMenuItems`, prepare-tool wrappers |
| **BonjourAIAnthropic** | Anthropic Claude implementations of the BonjourAICore protocols + the typed `PreferencesStore.aiCloudModel` bridge | `AnthropicModel`, `AnthropicClient`, `AnthropicConfiguration`, `AnthropicBonjourChatSession`, `AnthropicBonjourServiceExplainer`, `MockAnthropicClient` |
| **BonjourAIGitHub** | GitHub Models (OpenAI GPT-4o via `models.inference.ai.azure.com`) implementations of the BonjourAICore protocols. Hardcoded model — no picker. | `GitHubConfiguration`, `GitHubModelsClient`, `GitHubMessageRequest`, `GitHubBonjourChatSession`, `GitHubBonjourServiceExplainer`, `MockGitHubModelsClient` |
| **BonjourAI** | Umbrella module — cloud-aware routing factories + `@_exported import BonjourAICore` so legacy `import BonjourAI` consumers stay working | `CloudAwareBonjourChatSessionFactory`, `CloudAwareBonjourServiceExplainerFactory` |
| **BonjourUI** | SwiftUI views and view models | All views, `BonjourServicesViewModel`, UI components |

### Dependency Graph

```
App → BonjourUI, BonjourScanning, BonjourModels, BonjourLocalization
BonjourUI → BonjourModels, BonjourScanning, BonjourLocalization, BonjourAI, BonjourAIApple, BonjourAIAnthropic, BonjourAIGitHub, BonjourStorage, CoreUI
BonjourAI → BonjourAICore, BonjourAIApple, BonjourAIAnthropic, BonjourAIGitHub, BonjourCore, BonjourModels, BonjourLocalization, BonjourScanning, BonjourStorage
BonjourAIApple → BonjourAICore, BonjourCore, BonjourModels, BonjourLocalization, BonjourScanning, BonjourStorage
BonjourAIAnthropic → BonjourAICore, BonjourCore, BonjourModels, BonjourLocalization, BonjourScanning, BonjourStorage
BonjourAIGitHub → BonjourAICore, BonjourCore, BonjourModels, BonjourLocalization, BonjourScanning, BonjourStorage
BonjourAICore → BonjourCore, BonjourModels, BonjourLocalization, BonjourScanning, BonjourStorage
BonjourScanning → BonjourCore, BonjourModels, LocalNetworkMonitor
BonjourModels → BonjourCore, BonjourStorage, BonjourLocalization
BonjourStorage → BonjourCore
BonjourLocalization → (Foundation only)
BonjourCore → Core (BasicSwiftUtilities)
```

### AI Backend Routing

ADR 0005 introduces a pluggable AI backend. The Settings → AI Backend section
exposes a picker between three options:

- **Apple Intelligence** (default) — on-device via `BonjourAIApple` and FoundationModels.
- **Anthropic Claude** (opt-in) — cloud via `BonjourAIAnthropic` and the user's own API key.
- **GitHub Models** (opt-in) — cloud via `BonjourAIGitHub` (OpenAI GPT-4o brokered through
  GitHub's inference endpoint). Uses the user's own GitHub Personal Access Token.

`CloudAwareBonjourChatSessionFactory` / `CloudAwareBonjourServiceExplainerFactory`
live in the `BonjourAI` umbrella and sit above the per-provider factories in
`BonjourAIApple` / `BonjourAIAnthropic` / `BonjourAIGitHub`. They read `preferencesStore.aiBackend`
on every `makeForCurrentEnvironment(...)` call and route to the right implementation.
`AppCoreScene` watches `preferencesStore.aiBackend` and `aiCloudModel` via `.onChange`
and calls `AppCoreViewModel.refreshAIBackend()` so flipping the picker takes effect
without an app restart (the in-flight conversation is dropped across the swap).

The Anthropic API key lives in the iOS Keychain (`whenUnlockedThisDeviceOnly`,
never iCloud-synced) via `KeychainAICloudCredentialsStore`. Tests substitute
`InMemoryAICloudCredentialsStore`.

## Code Conventions

- Use `// MARK: -` section headers to organize code within files
- One type per file, feature-based folder organization
- Use the zero-parameter `onChange(of:)` closure (iOS 17+), not the deprecated `{ _ in }` form
- In SwiftUI View body code, do not wrap `@State` mutations in `Task { @MainActor in }` — Views already run on the main actor
- Use `[weak self]` in `Task` closures that capture `self` with a delay (e.g., `Task.sleep`), to avoid retaining objects past their lifetime
- Respect `@Environment(\.accessibilityReduceMotion)` — use `withAnimation(reduceMotion ? nil : .default)` instead of bare `withAnimation`
- Use semantic fonts (`.font(.headline)`) not `.font(.system(.headline))` for Dynamic Type support
- All user-facing strings must use `BonjourLocalization.Strings.*` — never hardcode English strings in views
- Service type definitions go in `MyServiceType+Library.swift` — each new type needs a `static private let` definition AND an entry in `tcpServiceTypes` or `udpServiceTypes` array AND a corresponding `NSBonjourServices` entry in `Info.plist`

## Swift 6.2 Strict Concurrency

### Core Rules

- All `Sendable` violations are compile errors, not warnings
- Prefer `@MainActor` at the **type level** over annotating individual properties or methods
- Never use `@unchecked Sendable` — redesign to avoid it
- Avoid `DispatchQueue.main.async` — use structured concurrency (`Task`, `async`/`await`)
- Avoid global mutable state (`static var`) — use actor-isolated singletons or dependency injection

### Classes

- **View models**: `@MainActor @Observable final class`
- **Service classes** (scanners, publishers): `@MainActor final class` — implicitly `Sendable`
- **Core Data** (`MyCoreDataStack`, `MyDataManager`, `CustomServiceType`): `@MainActor` since all access goes through `viewContext`
- `DependencyContainer`: `final class: Sendable` with `@MainActor init()` for production, nonisolated init for testing

### Protocols

- `@MainActor` protocols (`BonjourServiceScannerProtocol`, `BonjourPublishManagerProtocol`, etc.) inherit `AnyObject, Sendable`
- When `@MainActor` classes conform to ObjC protocols (`NetServiceDelegate`, `NetServiceBrowserDelegate`), use `@preconcurrency` on the conformance — not `nonisolated` methods

### Value Types

- Structs and enums crossing isolation boundaries must conform to `Sendable` explicitly: `BonjourServiceType`, `InternetAddress`, `TransportLayer`, `BonjourServiceBrowserState`

### Patterns to Follow

- `@MainActor` delegate chains: when both sides are `@MainActor`, call delegate methods directly — no `nonisolated` or `Task` hop needed
- `nonisolated let` for properties needed by `nonisolated` protocol requirements (e.g., `Identifiable.id`)
- `nonisolated(unsafe)` only for truly safe statics that can't satisfy the compiler (e.g., `static let sortDescriptors: [NSSortDescriptor]? = nil`)
- `@preconcurrency` on ObjC protocol conformances and `EnvironmentKey` where the protocol predates concurrency

## Localization

- **Module**: `BonjourLocalization` in `KozBonPackages/`
- **Format**: String Catalog (`.xcstrings`) — JSON-based, supports plurals and format strings
- **Languages**: English (base), Spanish, French, German, Japanese, Chinese (Simplified), Arabic, Hebrew
- **RTL support**: Arabic and Hebrew are right-to-left. The app relies on SwiftUI's automatic mirroring — `HStack`, `.leading` / `.trailing` padding and alignment, `Spacer()`, and direction-aware SF Symbols all flip without manual intervention. Apply `.flipsForRightToLeftLayoutDirection(true)` on directional symbols whose meaning depends on direction (e.g. the diagonal `arrow.up.right` on chat suggestion cards). **Never** use absolute `Edge.left` / `.right` padding, `Alignment.left` / `.right`, or `.offset(x:)` without sign-flipping by `@Environment(\.layoutDirection)` — they don't mirror.
- **Access pattern**: `Text(Strings.NavigationTitles.nearbyServices)` or `String(localized: Strings.Errors.portMin)`
- **Format strings**: Use methods like `Strings.Errors.portMin(value)` for runtime interpolation
- **Service descriptions**: Use `serviceType.localizedDetail` (not `.detail`) — looks up translations from the String Catalog
- **Adding new strings**: Add the key to `Strings.swift`, add the entry with all 8 translations (including `ar` and `he`) to `Localizable.xcstrings`, validate JSON. `scripts/validate-localizations.py` enforces locale completeness in CI.
- **Never use `NSLocalizedString`** — all strings go through the `Strings` enum for type safety

## SwiftLint

- **Config**: `.swiftlint.yml` in project root
- **Integration**: Runs as an Xcode Build Phase (lint only, no auto-correct) + GitHub Actions CI on PRs
- **Run manually**: `swiftlint lint` from project root
- **Key settings**: line length warns at 140, identifier min length 2, `todo` rule disabled
- **Excluded**: `KozBon/Legacy/`
- **Inline disables**: Use `// swiftlint:disable:next <rule>` for intentional violations (e.g., `force_unwrapping` in Core Data, `force_cast` in `MyDataManagerObject`)
- **File-level disables**: `// swiftlint:disable <rule>` at file top for files with many intentional violations (e.g., `MyServiceType+Library.swift`)

## Testing

- **Framework**: Swift Testing (`@Test`, `@Suite`, `#expect`)
- **Runner**: `swift test --package-path KozBonPackages` is the only test runner. All tests live in `KozBonPackages/` — 1,079 tests across 87 suites covering BonjourCore, BonjourModels, BonjourScanning, BonjourUI, BonjourAICore, BonjourAIAnthropic, AppCore (including the former app-level `TopLevelDestinationTests`), etc.
- **Naming**: `<TypeName>Tests.swift` (e.g., `TransportLayerTests.swift`)
- **`@MainActor` tests**: Use `@MainActor` on the suite when testing `@MainActor`-isolated types
- **Cross-module testing**: Use `@testable import <Module>` to access internal types, `import <Module>` for public API tests
- **`CustomServiceTypeTests` in BonjourStorage**: Require Xcode to compile `.xcdatamodeld` — excluded from the SPM test target (`Package.swift` `testExcludes`). The other BonjourStorage tests (SwiftData-backed `PreferencesStore` / `UserPreferences`) run fine under `swift test`
- **Flaky-test detection (Xcode 27+)**: Re-run the suite under stress with `swift test --package-path KozBonPackages --maximum-repetitions 5 --repeat-until fail` to surface any test that passes on the first run but fails intermittently. Pairs well with `--filter` to scope to a suspect suite. Available with the Xcode 27 toolchain or `xcrun --toolchain Xcode27 swift test …`.
- **Test failure summary (Xcode 27+)**: The Xcode 27 `swift test` runner prints a consolidated failure summary at the end of the run when one or more test targets fail — no scrolling required to find what broke.

## CI / GitHub Actions

| Workflow | Trigger | What it does |
|----------|---------|-------------|
| **Native CI** (`ios.yml`) | Push + PR to main | Build-only on iOS Simulator (iPhone 17 Pro) and macOS — no `xcodebuild test`; tests run under `spm-tests.yml` |
| **SPM Package Tests** (`spm-tests.yml`) | Push + PR when `KozBonPackages/` changes | `swift build` + `swift test` |
| **SwiftLint** (`swiftlint.yml`) | PR when `.swift` files change | Lint with inline PR annotations |
| **Multi-platform Build** (`multiplatform-build.yml`) | Push + PR to main | macOS + visionOS builds in parallel |

All workflows use `macos-26` runner with concurrency groups and SPM caching.

## Important Gotchas

- **No duplicate service types**: Each `(type, transportLayer)` pair must be unique in the library arrays. Duplicates cause redundant scanners and duplicate discovered services.
- **Info.plist NSBonjourServices**: Every service type the app wants to discover must be listed here. Format: `_type._transport` (e.g., `_http._tcp`). No duplicates.
- **service-names-port-numbers.csv**: IANA registry reference file bundled as a resource. Not parsed at runtime — service types are hardcoded in the Swift library.
- **BonjourService.id** uses `serviceIdentifier` (cached from `NetService.hashValue` at init) — stable within a session but not across launches.
- **Core Data model in package**: `iDiscover.xcdatamodeld` lives in `BonjourStorage/Sources/Resources/` (alongside the SwiftData preferences container) and is loaded via `Bundle.module`. SPM CLI (`swift test`) cannot compile `.xcdatamodeld` — use Xcode for the Core Data tests.
- **`@_exported import Core`**: `BonjourCore/Sources/Exports.swift` re-exports the `Core` package so downstream modules get `Logger`/`Loggable` without explicitly importing `Core`.
- **SF Symbol validation**: All `imageSystemName` values in `BonjourServiceType+UI.swift` are verified valid SF Symbols. When adding new ones, validate with `NSImage(systemSymbolName:accessibilityDescription:)`.
