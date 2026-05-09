# ADR 0002: SwiftUI MVVM with `@Observable` view models

## Status

Accepted, 2026-04-15

## Context

KozBon had multiple views with significant logic — scanning, broadcasting, chat, service-type creation. As the views grew, several anti-patterns appeared:

- View bodies with 5+ pieces of `@State` that interacted with each other.
- Validation pipelines (`private func validateForm()`) inside `View` structs.
- Multi-step async work (validate → submit → handle response → animate) embedded in button actions.
- View extension files sharing mutable state via `internal`-by-default declarations because `private` doesn't span files.

Logic in views was untestable in isolation and the implicit data flow made onboarding harder than necessary.

Constraints:

- The app uses Swift 6.2 with strict concurrency; view models must be `Sendable`-compatible.
- The platforms range from iOS 18 (`@Observable` macro is available) to visionOS 2 — same baseline.
- Some shared state must cross sibling tabs (the Bonjour scanner has a single delegate slot).

## Decision

Adopt SwiftUI MVVM with `@Observable` view models, codified in [`.claude/rules/mvvm.md`](../../.claude/rules/mvvm.md). Key rules:

- Every view model is `@MainActor @Observable final class`.
- Views own their view models via `@State` for per-view lifecycle, or take them as `@Bindable` parameters for shared lifecycle.
- View models capture **long-lived dependencies** at init (the publish manager, the services view model) and take **short-lived environment values** as method parameters (`reduceMotion`, `preferencesStore`).
- View models stay free of `@Environment` reads — those are SwiftUI types tied to view body evaluation; pulling them into a class breaks testability.
- Multi-init "create / edit / prefilled" surfaces collapse into static factory methods on the view model (`.empty()`, `.editing(_:)`, `.prefilled(...)`).
- View models split across companion files via Swift extensions (`FeatureViewModel+Send.swift`, `FeatureViewModel+Scroll.swift`) when they exceed `~300` lines.

The `BonjourChatViewModel` extraction was the canonical first example. Form view models followed (`BroadcastBonjourServiceViewModel`, `CreateOrUpdateBonjourServiceTypeViewModel`, `CreateTxtRecordViewModel`).

## Consequences

**Positive:**

- View bodies became thin presenters. The chat view dropped from a 600-line struct with 12 `@State` properties to a presenter that binds the body to a view model.
- Logic became testable. Each view model has a unit test suite that runs in milliseconds without simulating a SwiftUI host.
- Factory methods made multi-mode surfaces explicit. Previously the broadcast view had three inits with subtle differences (one took a binding, one took prefilled values, one took an existing service); now the view inits route to the same VM through `.empty()`/`.editing(_:)`/`.prefilled(...)` and the differences are visible in the factory names.
- `@MainActor @Observable final class` plays well with Swift 6.2 strict concurrency — properties are observable, the class itself is `Sendable` by virtue of MainActor isolation.

**Negative:**

- More files. Each view that gains a view model gets one more file (and often a `+Send`/`+Scroll`/`+Intents` companion).
- The `@Bindable` shared-instance pattern is subtle. Engineers reaching for it must understand *why* (BonjourServiceScanner has a single delegate slot) — easy to over-apply if the rationale isn't visible.
- The split between long-lived deps (init params) and short-lived deps (method params) is a discipline rule, not enforced by the compiler. Reviews catch violations.

## Alternatives considered

- **Keep logic in views, lean on smaller views.** Rejected: view bodies still aren't testable in isolation, and SwiftUI's preview workflow doesn't compensate for that.
- **`ObservableObject` / `@Published`.** Predates `@Observable` and has more boilerplate (`@Published` per property, manual `objectWillChange.send()`). Rejected as legacy.
- **The Composable Architecture (TCA) or similar redux-style framework.** Heavyweight for an app this size and adds a third-party dependency to the runtime. Rejected because the SwiftUI-native pattern is sufficient.
- **No view models — use protocols and value types.** Considered for the form sheets specifically. Rejected because forms have meaningful internal state (input fields, error messages, validation outcomes) that wants a stable object identity for SwiftUI's `@State` to track.
