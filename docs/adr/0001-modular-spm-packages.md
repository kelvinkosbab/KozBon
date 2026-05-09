# ADR 0001: Modular SPM packages instead of a monolithic app target

## Status

Accepted, 2026-04-01

## Context

Early KozBon was a single iOS app target with all the source under `KozBon/`. As the surface grew — Bonjour scanner, publish manager, custom-service-type Core Data store, on-device AI explainer + chat, App Intents, design system primitives — the target accumulated implicit cross-cutting dependencies. Compile times grew roughly linearly with the source tree, every change rebuilt every file, and the lack of a module boundary meant nothing prevented "the chat tab reaching into the scanner's internal state."

Constraints:

- The app must build for iOS, iPadOS, macOS, and visionOS from a single codebase.
- Some surfaces (AI features) are gated by `#available(iOS 26, *)` and `canImport(FoundationModels)`. Spreading the gate across the codebase made it hard to audit the AI dependency boundary.
- The app target imports Apple's UI frameworks; pure logic (scanner, prompt builders, models) doesn't need them. Mixing them inflates the test target.

## Decision

Split the codebase into seven local Swift Package Manager modules under `KozBonPackages/`:

| Module | Owns |
|---|---|
| `BonjourCore` | Foundational utilities and shared types — networking primitives (`InternetAddress`, `TransportLayer`), system integration (`HapticFeedback`, `Iconography`), foundation extensions (`Logger`, `String+Util`), `Constants`. |
| `BonjourLocalization` | The `Strings` type-safe enum and the `Localizable.xcstrings` resource bundle. |
| `BonjourModels` | Domain models — `BonjourService`, `BonjourServiceType`, the 110+-entry built-in service-type library, sort/category/scope enums. |
| `BonjourStorage` | Persistence — SwiftData `PreferencesStore` and the legacy Core Data custom-service-type store. |
| `BonjourScanning` | Bonjour discovery and publishing — `BonjourServiceScanner`, `MyBonjourPublishManager`, `DependencyContainer` and mocks. |
| `BonjourAI` | On-device AI — Foundation Models–backed explainer + chat session, prompt builders, intent broker, Siri service-name renderer. Gated behind `canImport(FoundationModels)`. |
| `BonjourUI` | All SwiftUI views, view models, and the design-system primitives. |
| `BonjourAppIntents` | App Intents (Siri / Shortcuts) entity + intents. |

The app target (`KozBon/`) depends on the seven module products and contains only the `@main` entry point, tab structure, environment plumbing, and macOS commands.

## Consequences

**Positive:**

- Compilation parallelism. The SPM package graph builds modules in parallel; an edit to `BonjourUI` rebuilds only `BonjourUI` and the app target, not BonjourCore or BonjourAI.
- Explicit module boundaries. `BonjourScanning` can't accidentally `import SwiftUI`; `BonjourCore` can't reach into `BonjourAI`. Cross-package coupling is visible in `Package.swift` rather than hidden in transitive imports.
- Test surface scoped per module. `swift test --package-path KozBonPackages` runs all 800+ unit tests in seconds without a simulator.
- The `#if canImport(FoundationModels)` gate is contained to `BonjourAI`; consumers depend on protocols (`BonjourChatSessionProtocol`) so the gate doesn't leak.
- Each module ships its own tests by convention (see `Package.swift` — `hasTests` parameter was removed, every package has tests).

**Negative:**

- Slightly more ceremony to add a new public API — needs `public` on the type and any required surface.
- The Xcode project (`KozBon.xcodeproj`) holds the app target separately from the SPM packages, so adding a new app-target file requires editing `project.pbxproj` directly. Most new code goes into a package and avoids this.
- Cross-module refactors touch more files (e.g., a model rename ripples through every package that depends on `BonjourModels`).

## Alternatives considered

- **Frameworks within the app project.** Considered briefly; rejected because Xcode framework targets carry packaging metadata KozBon doesn't need, and they don't get the `swift test --package-path` ergonomic of running tests without a simulator.
- **Single SPM package with multiple targets.** Functionally equivalent to the current setup but flatter. Rejected because the 7 modules have meaningful semantic boundaries that benefit from separate `import` statements at every consumer; flattening would erode the boundary.
- **Stay monolithic and rely on conventions / SwiftLint to enforce boundaries.** Rejected because conventions get violated under deadline pressure and SwiftLint can't see import-level coupling.
