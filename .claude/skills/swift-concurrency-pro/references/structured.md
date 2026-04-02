# Structured Concurrency Guide Summary

This document provides best practices for Swift's structured concurrency features:

**`async let` vs Task Groups**: Use `async let` for "a fixed number of independent operations that return different types," while task groups suit "a dynamic number of operations of the same type."

**Avoid Unstructured Tasks in Loops**: The guide emphasizes that using unstructured tasks in loops is problematic because they lack "cancellation propagation" and have "no way to await all results." Task groups are the preferred alternative.

**`withDiscardingTaskGroup`**: For fire-and-forget operations, this variant "avoids accumulating unused results in memory."

**Concurrency Limits**: Task groups "launch all child tasks eagerly," which may be undesirable. The document demonstrates manual concurrency limiting by starting tasks in batches and launching new ones as previous tasks complete.

**Error Handling**: When a child task throws, "the group cancels all remaining children." To preserve partial results, catch errors within each task rather than at the group level.

**Type Inference**: While Swift typically infers task group types for simple values like strings and URLs, complex types like tuples containing Result types require explicit type specification.