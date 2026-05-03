# CLAUDE.md

## Project Overview

KozBon is a multi-platform Apple app for discovering and managing Bonjour (mDNS) network services. Bundle ID: `com.kozinga.KozBon`.

## Build & Run

```bash
# Build for iOS Simulator
xcodebuild -workspace KozBon.xcworkspace -scheme KozBon -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' build

# Build for macOS
xcodebuild -workspace KozBon.xcworkspace -scheme KozBon -destination 'platform=macOS' build

# Build for visionOS Simulator
xcodebuild -workspace KozBon.xcworkspace -scheme KozBon -destination 'platform=visionOS Simulator,name=Apple Vision Pro' build

# Run app unit tests (via Xcode)
xcodebuild test -workspace KozBon.xcworkspace -scheme KozBon -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2'

# Run SPM package tests (faster, no simulator needed)
swift test --package-path KozBonPackages
```

## Architecture

- **Swift 6.2** with strict concurrency checking (`SWIFT_STRICT_CONCURRENCY = complete`)
- **SwiftUI** with MVVM pattern, targeting iOS 18.6+, macOS 15.6+, tvOS 18.0+, watchOS 11.0+, visionOS 2.0+
  - View-model conventions are documented in [`.claude/rules/mvvm.md`](.claude/rules/mvvm.md) — when to use a VM, `@State` vs `@Bindable` ownership, dependency-plumbing rules, splitting large VMs across companion files
- **Modular SPM packages** via `KozBonPackages/` local package in the Xcode workspace
- **Dependency Injection** via `DependencyContainer` (in `BonjourScanning` module) using SwiftUI environment (`@Environment(\.dependencies)`)
- **Core Data** for persistence (`iDiscover.xcdatamodeld`) — all Core Data access is `@MainActor` via `viewContext`
- **Localization** via `BonjourLocalization` module with String Catalog (`.xcstrings`) — 6 languages supported
- Protocol-based abstractions: `BonjourServiceScannerProtocol`, `BonjourPublishManagerProtocol`

## Project Structure

### Workspace

`KozBon.xcworkspace` contains:
- `KozBon.xcodeproj` — the app target (5 Swift files)
- `KozBonPackages/` — local SPM package with 6 modules

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
| **BonjourLocalization** | Localized strings (6 languages) | `Strings` enum, `Localizable.xcstrings` |
| **BonjourModels** | Domain models and service library | `BonjourServiceType`, `BonjourService`, `BonjourServiceSortType` |
| **BonjourScanning** | Network discovery and publishing | `BonjourServiceScanner`, `MyBonjourPublishManager`, `DependencyContainer`, mocks |
| **BonjourAI** | On-device AI explainer + chat (FoundationModels) | `BonjourServicePromptBuilder`, `BonjourChatPromptBuilder`, `BonjourServiceExplainer`, `BonjourChatSession` |
| **BonjourUI** | SwiftUI views and view models | All views, `BonjourServicesViewModel`, UI components |

### Dependency Graph

```
App → BonjourUI, BonjourScanning, BonjourModels, BonjourLocalization
BonjourUI → BonjourModels, BonjourScanning, BonjourLocalization, BonjourAI, BonjourStorage, CoreUI
BonjourAI → BonjourCore, BonjourModels, BonjourLocalization, BonjourStorage
BonjourScanning → BonjourCore, BonjourModels
BonjourModels → BonjourCore, BonjourStorage, BonjourLocalization
BonjourStorage → BonjourCore
BonjourLocalization → (Foundation only)
BonjourCore → Core (BasicSwiftUtilities)
```

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
- **Languages**: English (base), Spanish, French, German, Japanese, Chinese (Simplified)
- **Access pattern**: `Text(Strings.NavigationTitles.nearbyServices)` or `String(localized: Strings.Errors.portMin)`
- **Format strings**: Use methods like `Strings.Errors.portMin(value)` for runtime interpolation
- **Service descriptions**: Use `serviceType.localizedDetail` (not `.detail`) — looks up translations from the String Catalog
- **Adding new strings**: Add the key to `Strings.swift`, add the entry with all 6 translations to `Localizable.xcstrings`, validate JSON
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
- **Package tests** (`swift test`): 184 tests across 18 suites in `KozBonPackages/` — BonjourCore, BonjourModels, BonjourScanning, BonjourUI
- **App tests** (`xcodebuild test`): 8 tests in `KozBonTests/` — TopLevelDestination
- **Naming**: `<TypeName>Tests.swift` (e.g., `TransportLayerTests.swift`)
- **`@MainActor` tests**: Use `@MainActor` on the suite when testing `@MainActor`-isolated types
- **Cross-module testing**: Use `@testable import <Module>` to access internal types, `import <Module>` for public API tests
- **`CustomServiceTypeTests` in BonjourStorage**: Require Xcode to compile `.xcdatamodeld` — excluded from the SPM test target (`Package.swift` `testExcludes`) and run via `xcodebuild test` only. The other BonjourStorage tests (SwiftData-backed `PreferencesStore` / `UserPreferences`) run fine under `swift test`

## CI / GitHub Actions

| Workflow | Trigger | What it does |
|----------|---------|-------------|
| **iOS CI** (`ios.yml`) | Push + PR to main | Build + test iOS on iPhone 17 Pro simulator |
| **SPM Package Tests** (`spm-tests.yml`) | Push + PR when `KozBonPackages/` changes | `swift build` + `swift test` |
| **SwiftLint** (`swiftlint.yml`) | PR when `.swift` files change | Lint with inline PR annotations |
| **Multi-platform Build** (`multiplatform-build.yml`) | Push + PR to main | macOS + visionOS builds in parallel |

All workflows use `macos-16` runner with concurrency groups and SPM caching.

## Important Gotchas

- **No duplicate service types**: Each `(type, transportLayer)` pair must be unique in the library arrays. Duplicates cause redundant scanners and duplicate discovered services.
- **Info.plist NSBonjourServices**: Every service type the app wants to discover must be listed here. Format: `_type._transport` (e.g., `_http._tcp`). No duplicates.
- **service-names-port-numbers.csv**: IANA registry reference file bundled as a resource. Not parsed at runtime — service types are hardcoded in the Swift library.
- **BonjourService.id** uses `serviceIdentifier` (cached from `NetService.hashValue` at init) — stable within a session but not across launches.
- **Core Data model in package**: `iDiscover.xcdatamodeld` lives in `BonjourStorage/Sources/Resources/` (alongside the SwiftData preferences container) and is loaded via `Bundle.module`. SPM CLI (`swift test`) cannot compile `.xcdatamodeld` — use Xcode for the Core Data tests.
- **`@_exported import Core`**: `BonjourCore/Sources/Exports.swift` re-exports the `Core` package so downstream modules get `Logger`/`Loggable` without explicitly importing `Core`.
- **SF Symbol validation**: All `imageSystemName` values in `BonjourServiceType+UI.swift` are verified valid SF Symbols. When adding new ones, validate with `NSImage(systemSymbolName:accessibilityDescription:)`.
