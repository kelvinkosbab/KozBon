# CLAUDE.md

## Project Overview

KozBon is a multi-platform Apple app for discovering and managing Bonjour (mDNS) network services. Bundle ID: `com.kozinga.KozBon`.

## Build & Run

```bash
# Build for iOS Simulator
xcodebuild -scheme KozBon -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' build

# The project has no test targets currently
```

## Architecture

- **Swift 6** with strict concurrency checking (`SWIFT_STRICT_CONCURRENCY = complete`)
- **SwiftUI** with MVVM pattern, targeting iOS 18.6+, macOS 15.6+, tvOS 18.0+, watchOS 11.0+, visionOS 2.0+
- **Dependency Injection** via `DependencyContainer` using SwiftUI environment (`@Environment(\.dependencies)`)
- **Core Data** for persistence (`iDiscover.xcdatamodeld`) — all Core Data access is `@MainActor` via `viewContext`
- Protocol-based abstractions: `BonjourServiceScannerProtocol`, `BonjourPublishManagerProtocol`

## Key Directories

- `KozBon/AppCore.swift` — App entry point (@main)
- `KozBon/DependencyContainer.swift` — DI container (`Sendable`, default init is `@MainActor`)
- `KozBon/BonjourNearbyServices/` — Scanning UI, view models, scanner implementation
- `KozBon/BonjourSupportedServices/` — Service type library browsing
- `KozBon/Model/` — Core Data stack and data management (all `@MainActor`)
- `KozBon/Utilities/` — Logger, styles, reusable CoreUI components

## Code Conventions

- Use `// MARK: -` section headers to organize code within files
- Service type definitions go in `MyServiceType+Library.swift` — each new type needs a `static private let` definition AND an entry in `tcpServiceTypes` or `udpServiceTypes` array AND a corresponding `NSBonjourServices` entry in `Info.plist`
- Use the zero-parameter `onChange(of:)` closure (iOS 17+), not the deprecated `{ _ in }` form
- In SwiftUI View body code, do not wrap `@State` mutations in `Task { @MainActor in }` — Views already run on the main actor
- Use `[weak self]` in `Task` closures that capture `self` with a delay (e.g., `Task.sleep`), to avoid retaining objects past their lifetime

## Swift 6 Strict Concurrency

### Core Rules

- All `Sendable` violations are compile errors, not warnings
- Prefer `@MainActor` at the **type level** over annotating individual properties or methods
- Never use `@unchecked Sendable` — redesign to avoid it
- Avoid `DispatchQueue.main.async` — use structured concurrency (`Task`, `async`/`await`)
- Avoid global mutable state (`static var`) — use actor-isolated singletons or dependency injection

### Classes

- **View models**: `@MainActor final class` conforming to `ObservableObject`
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

## SwiftLint

- **Config**: `.swiftlint.yml` in project root
- **Integration**: Runs as an Xcode Build Phase (lint only, no auto-correct)
- **Run manually**: `swiftlint lint` from project root
- **Key settings**: line length warns at 140, identifier min length 2, `todo` rule disabled
- **Excluded**: `KozBon/Legacy/`
- **Inline disables**: Use `// swiftlint:disable:next <rule>` for intentional violations (e.g., `force_unwrapping` in Core Data, `force_cast` in `MyDataManagerObject`)
- **File-level disables**: `// swiftlint:disable <rule>` at file top for files with many intentional violations (e.g., `MyServiceType+Library.swift`)

## Important Gotchas

- **No duplicate service types**: Each `(type, transportLayer)` pair must be unique in the library arrays. Duplicates cause redundant scanners and duplicate discovered services.
- **Info.plist NSBonjourServices**: Every service type the app wants to discover must be listed here. Format: `_type._transport` (e.g., `_http._tcp`). No duplicates.
- **service-names-port-numbers.csv**: IANA registry reference file bundled as a resource. Not parsed at runtime — service types are hardcoded in the Swift library.
- The iOS 18+ Tab API has a separate code path from the pre-iOS 18 TabView in `AppCore.swift`.
- `BonjourService.id` uses `serviceIdentifier` (cached from `NetService.hashValue` at init) — stable within a session but not across launches.
