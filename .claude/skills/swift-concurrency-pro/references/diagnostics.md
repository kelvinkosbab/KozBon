# Diagnostics Content Summary

This diagnostics guide maps Swift strict-concurrency compiler errors to solutions. Key categories include:

**"Sending 'x' risks causing data races"** — suggests checking region-based isolation first, then trying `sending` parameters, making types `Sendable`, or using `nonisolated(nonsending)`.

**"Static property 'x' is not concurrency-safe"** — recommends `@MainActor` annotation as the simplest fix, or ensuring immutability and `Sendable` conformance.

**"Capture of 'x' with non-sendable type in a `@Sendable` closure"** — advises making captured values `Sendable`, restructuring to pass data as parameters, or moving work onto the same actor.

**"Conformance of 'X' to protocol 'Y' crosses into main actor-isolated code"** — requires fixing boundary mismatches by either removing type isolation or using `@MainActor` on the conformance.

**"Expression is 'async' but is not marked with 'await'"** — directs adding `await` or wrapping in `Task {}` when needed.

**"Main actor-isolated conformance cannot be used in nonisolated context"** — suggests moving the use site onto the same actor or removing conformance isolation.

The guide consistently discourages premature use of `@unchecked Sendable` except in narrow cases involving manual synchronization.