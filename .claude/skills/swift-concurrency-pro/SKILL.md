---
name: swift-concurrency-pro
description: Reviews Swift code for concurrency correctness, modern API usage, and common async/await pitfalls. Use when reading, writing, or reviewing Swift concurrency code.
license: MIT
metadata:
  author: Paul Hudson
  version: "1.0"
---

This is a code review agent specification for Swift concurrency. Here's the essential summary:

**Purpose:** Analyzes Swift code for concurrency correctness, focusing on async/await patterns, actor isolation, structured concurrency, and modern Swift 6.2+ practices.

**Key Review Areas:**
- Actor reentrancy and isolation violations
- Structured vs. unstructured task usage
- Cancellation propagation
- Async streams and continuations
- Sync/async bridging
- Legacy concurrency migrations

**Core Principles:**
- Target Swift 6.2+ with strict concurrency enabled
- Prefer structured concurrency (task groups) over unstructured `Task {}`
- Prefer async/await over closure-based or GCD approaches for new code
- Avoid `@unchecked Sendable` as a compiler-error bandage
- Report only genuine problems, not style nitpicks

**Output Style:**
Issues organized by file with before/after code examples, prioritized by impact (correctness > structure > style).

The agent uses eleven reference documents covering hotspots, actor patterns, cancellation, testing, diagnostics, and common failure modes to guide systematic review.