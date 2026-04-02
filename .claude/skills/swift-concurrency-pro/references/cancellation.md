# Swift Concurrency Cancellation Summary

Cancellation in Swift works cooperatively—simply setting a cancelled flag has no effect unless the code explicitly checks it.

## Propagation Behavior

Cancellation flows hierarchically through structured concurrency: "Cancelling a parent task cancels all its children." Task groups and SwiftUI's `.task()` modifier handle automatic cancellation, but unstructured tasks like `Task {}` require manual cancellation.

## Detection Methods

Two primary approaches exist for checking cancellation status:

1. **`try Task.checkCancellation()`** — "throws `CancellationError` if cancelled. Preferred in throwing contexts."
2. **`Task.isCancelled`** — Returns a boolean, useful when cleanup is needed before exiting.

A critical caveat: CPU-bound loops without `await` points won't detect cancellation unless you add explicit checks, since "Functions that call other async functions get implicit cancellation checks at each `await` suspension point – but only if the called function itself checks."

## Integration with Legacy APIs

The `withTaskCancellationHandler` construct bridges modern Swift cancellation to older systems with their own cancellation mechanisms. The `onCancel` closure executes immediately upon cancellation request and can run on any thread.

## Common Mistakes

Avoid catching and silencing `CancellationError` as though it's a regular error. Additionally, forgetting to cancel stored task handles creates resource leaks, requiring cancellation both before launching new tasks and during object teardown.