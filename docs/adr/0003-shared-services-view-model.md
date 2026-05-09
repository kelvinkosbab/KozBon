# ADR 0003: One shared `BonjourServicesViewModel` across Discover and Chat tabs

## Status

Accepted, 2026-04-20

## Context

The Discover tab and the Chat tab both need a live view of currently-discovered Bonjour services. Discover renders them in a list; Chat injects them into the on-device AI's context block so the model can answer "what's on my network?".

Two natural shapes exist for sharing this state:

1. **One view model, shared across tabs.** Both tabs hold a reference to the same `BonjourServicesViewModel` instance, instantiated once at the app root.
2. **One view model per tab.** Each tab constructs its own VM and the underlying scanner pushes updates to whichever VM is the current scanner delegate.

The Apple Bonjour API constrains the choice: `NetServiceBrowser` (and KozBon's wrapper, `BonjourServiceScanner`) exposes one `weak var delegate` slot. Whoever assigns themselves last wins; the previous delegate stops getting updates silently.

If each tab created its own VM, opening the Chat tab would steal the delegate slot from Discover, and Discover would silently stop receiving service add/remove callbacks until the user switched back. The bug would manifest as "Discover has stale data after using Chat" with no error messages — the worst kind of regression.

## Decision

Construct a single `BonjourServicesViewModel` at `AppCore` (the `@main App` type) and pass it to both `BonjourScanForServicesView` (Discover) and `BonjourChatView` (Chat) as a `@Bindable` parameter. The MVVM rule documents this exception: per-view ownership is the default; shared ownership is reserved for cases like this where two instances would cause incorrect behavior.

```swift
@main
struct AppCore: App {
    @State private var servicesViewModel: BonjourServicesViewModel

    init() {
        let dependencies = DependencyContainer()
        _servicesViewModel = State(initialValue: BonjourServicesViewModel(dependencies: dependencies))
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                Tab { BonjourScanForServicesView(viewModel: servicesViewModel) }
                Tab { BonjourChatView(viewModel: servicesViewModel) }
            }
        }
    }
}
```

The view model owns the scanner delegate registration; both tabs consume the same observable state.

## Consequences

**Positive:**

- The scanner delegate slot has exactly one owner, deterministically. No race; no silent stale state.
- Discovered-service updates land in both tabs simultaneously. The chat assistant always sees the same data Discover renders.
- Memory footprint stays bounded — one VM, one scanner instance, one set of mocks for tests.
- Tests can construct one `BonjourServicesViewModel(dependencies: .mock())` and exercise both tabs' bindings against it.

**Negative:**

- The view-model lifetime is the app's lifetime. Even when neither tab is on screen, the scanner keeps an active subscription; the cost is negligible (Bonjour scanning is cheap) but it's a deliberate trade.
- New tabs that need service state (a hypothetical "broadcast queue" tab, for example) must take the same VM, which expands the surface area passed around. The MVVM rule's "Common Pitfalls" section calls this out — when in doubt, ask "would two instances cause incorrect behavior?"
- New contributors don't see the constraint until they trip on it. Mitigated by the doc comment on `BonjourServicesViewModel` explaining the delegate-slot rationale and the reference in `.claude/rules/mvvm.md`.

## Alternatives considered

- **Per-tab view models with a shared scanner singleton that fans out.** The scanner would broadcast to a list of observers instead of a single delegate. Rejected because it duplicates the SwiftUI environment / view-model layer's job (multiple consumers of one observable). Adding our own observer list would complicate testing without solving anything that view-model sharing doesn't.
- **Inject the scanner directly into each view, no view model.** Works for trivial views, but Discover has filtering, sorting, and selection state that wants to live somewhere. Pushing it into the view bodies recreates the anti-patterns ADR 0002 was solving for.
- **Two view models, with one of them subscribing to the other.** Considered briefly; rejected because the upstream (scanner-owning) VM would still be the single delegate. The downstream VM observing the upstream is just shared ownership with extra steps.
