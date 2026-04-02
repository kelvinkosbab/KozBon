# Swift 6.2 Concurrency Features

Swift 6.2 introduces several concurrency enhancements designed to improve safety and reduce friction when writing concurrent code.

**Main Actor Isolation by Default**

Modules can now opt into making declarations `@MainActor` by default. As the document explains, "a large amount of code can stay effectively single-threaded until the project deliberately chooses otherwise." This proves particularly valuable for UI-heavy applications.

**Global-Actor Isolated Conformances**

Types can now satisfy protocol requirements while maintaining actor isolation, allowing "a `@MainActor` type can satisfy a protocol while keeping the conformance actor-bound."

**Nonisolated Async Functions**

Plain async methods now remain on the caller's actor by default rather than automatically executing elsewhere, eliminating certain data-race diagnostics.

**The `@concurrent` Attribute**

For work that genuinely needs background execution, `@concurrent` provides explicit opt-in for "CPU-heavy work such as parsing, image processing, compression, or large transforms."

**Task Improvements**

Several task-related enhancements include `Task.immediate` for synchronous startup, isolated deinitializers for cleanup code, priority escalation APIs, and task naming for debugging purposes.

These changes collectively support Swift's broader goal of achieving data-race safety while remaining approachable for developers.