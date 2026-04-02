# Bug Patterns in Concurrent Swift

This document outlines ten critical concurrency failure modes that LLMs frequently produce, along with recommended fixes:

1. **Actor reentrancy**: "check-then-act across `await`" where state mutations between the check and act cause crashes or duplicate work.

2. **Continuation resumed zero times**: A `withCheckedThrowingContinuation` callback never fires, causing indefinite hangs. The solution involves auditing all code paths and adding timeouts where necessary.

3. **Continuation resumed twice**: Multiple callbacks attempt to resume the same continuation, triggering traps or undefined behavior. Guard with flags or use actors to serialize access.

4. **Unstructured tasks in loops**: Fire-and-forget `Task` creations lack cancellation propagation and error collection. Switch to `withTaskGroup` instead.

5. **Swallowed errors in Task closures**: Thrown errors inside `Task { try await ... }` are silently lost. Handle errors explicitly within the closure.

6. **Main actor blocking**: CPU-intensive synchronous work freezes the UI. Offload using `@concurrent` or `Task.detached`.

7. **Unbounded AsyncStream buffering**: High-throughput producers overwhelm memory with default `.unbounded` settings. Apply `.bufferingNewest(n)` limits.

8. **Ignoring CancellationError**: Treating normal cancellation as an error triggers inappropriate retries or alerts. Distinguish cancellation before general error handling.

9. **Unsafe @unchecked Sendable**: Marking classes `@unchecked Sendable` masks real data races in mutable properties. Use value types, actors, or locks instead.