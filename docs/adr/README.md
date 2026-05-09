# Architecture Decision Records

This directory captures the *why* behind non-obvious technical choices in KozBon. Each ADR follows the standard template (Status, Context, Decision, Consequences, Alternatives Considered) and stays immutable once accepted — if a decision changes, write a new ADR that supersedes the old one and link forward.

The convention follows [`.claude/rules/project-documentation.md`](../../.claude/rules/project-documentation.md). New decisions should land here when made, not "later" — recall is poor a year out.

## Index

| # | Title | Status |
|---|-------|--------|
| [0001](0001-modular-spm-packages.md) | Modular SPM packages instead of a monolithic app target | Accepted |
| [0002](0002-mvvm-with-observable.md) | SwiftUI MVVM with `@Observable` view models | Accepted |
| [0003](0003-shared-services-view-model.md) | One shared `BonjourServicesViewModel` across Discover and Chat tabs | Accepted |
| [0004](0004-on-device-only-ai.md) | On-device only AI via Apple Foundation Models | Accepted |

## Conventions

- **Numbered sequentially**, never reused. ADR 0007 is forever ADR 0007.
- **Immutable once accepted.** A new decision that supersedes an existing one gets its own ADR (`0023`) referencing the original (`Supersedes ADR 0007`); the original keeps its `Accepted` history but its Status flips to `Superseded by ADR 0023`.
- **Status values:** `Proposed`, `Accepted`, `Deprecated`, `Superseded by ADR ####`.
- **Length:** one page is the sweet spot. Decisions that need ten pages of context belong in a separate Article that the ADR links to.
