# Contributing to KozBon

Thanks for your interest in KozBon. This document covers what you need to make a successful contribution.

## Development environment

**Prerequisites:**

- macOS 14+ (Xcode requires it).
- Xcode 27 (release builds require it; see `scripts/release/upload-testflight.sh`). KozBon targets 26 on every platform, so Foundation Models and Liquid Glass need no `#available` checks.
- Git.

**Clone:**

```bash
git clone https://github.com/kelvinkosbab/KozBon.git
cd KozBon
```

**Open the workspace, not the project** — the workspace contains the local SPM package graph that the app target depends on:

```bash
open KozBon.xcworkspace
```

## Running tests

The fastest path is the SPM package tests, which need no simulator and run in seconds:

```bash
swift test --package-path KozBonPackages
```

This runs every package's test target except the Core Data tests in `BonjourStorage`, which need Xcode-compiled `.xcdatamodeld` resources and skip silently under SPM CLI.

For the full suite (including the Core Data tests via Xcode):

```bash
xcodebuild test \
  -workspace KozBon.xcworkspace \
  -scheme KozBon \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## Running the linter

```bash
swiftlint lint
```

Run it from the repo root. CI runs `swiftlint lint --strict` with SwiftLint 0.65.1 (pinned in `.github/workflows/swiftlint.yml`), so warnings fail a PR; install the same version locally to match.

## Building for each platform

```bash
# iOS
xcodebuild -workspace KozBon.xcworkspace -scheme KozBon \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# macOS
xcodebuild -workspace KozBon.xcworkspace -scheme KozBon \
  -destination 'platform=macOS' build

# visionOS
xcodebuild -workspace KozBon.xcworkspace -scheme KozBon \
  -destination 'platform=visionOS Simulator,name=Apple Vision Pro' build
```

CI runs all three on every PR — if a change builds locally on iOS but not macOS or visionOS, expect the PR check to surface it.

## Branch and PR conventions

- **Branch from `main`**; name with a short imperative summary (`fix-chat-runaway`, `add-discover-search`).
- **One logical change per commit.** If a commit message needs "and" twice, it should probably be two commits.
- **Commit message format**: imperative summary in the subject line (max ~70 chars), blank line, then a body paragraph that explains *why* the change exists and what alternatives were considered. The recent commits in `git log --oneline` are good examples.
- **PR title** mirrors the commit subject when the PR is a single commit; otherwise summarizes the series.
- **PR description** restates the user-facing impact and links any related issues. Reviewers shouldn't need to read the diff to know what the change does.

## What reviewers look for

Three things, in order:

1. **Behavior preserved on every supported platform** — if the change touches UI, did you build on iOS / macOS / visionOS? CI catches this but local verification is faster.
2. **Test coverage for the changed surface** — every PR that adds public API or fixes a bug should add or update tests. The audit rules in `.claude/rules/apple-testing-strategy.md` describe what's worth testing.
3. **Conventions in `.claude/rules/`** — the rule files (MVVM, accessibility, Foundation Models, documentation, testing strategy) are the source of truth for code style. Reviewers will reference them.

The rules are also surfaced to Claude Code if you use it; running an audit against the rule files before pushing usually catches anything reviewers would flag.

## Where to file issues

Issues live on GitHub: <https://github.com/kelvinkosbab/KozBon/issues>. Please include:

- The platform and OS version where you reproduced.
- The KozBon version (Settings → About).
- Reproduction steps short enough to fit in three numbered lines, when possible.

## Architectural decisions

For non-obvious technical choices (why a particular dependency-injection shape, why MVVM with `@Observable`, why one shared services view model across tabs), see `docs/adr/`. Each ADR captures the context, the decision, and what was traded away — useful for understanding *why* the codebase looks the way it does.

If you're proposing a change that supersedes an existing ADR, write a new one (`docs/adr/####-title.md`) referencing the original — don't edit the historical record.
