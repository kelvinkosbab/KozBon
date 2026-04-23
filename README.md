# KozBon

A multi-platform Apple app for discovering, broadcasting, and understanding Bonjour (mDNS/DNS-SD) network services — with on-device AI explanations and a conversational assistant powered by Apple Intelligence.

## Features

### Discover & broadcast

- **Service discovery** — Live scan of your local network with filter categories (smart home, Apple devices, media & streaming, printers & scanners, remote access)
- **Service broadcasting** — Publish custom services with configurable port, domain, and TXT records
- **110+ built-in service types** — Pre-configured library covering HTTP, SSH, AirPlay, HomeKit, IPP, and more
- **Custom service types** — Define and persist your own entries with IANA-format identifiers
- **Service details** — Hostnames, IP addresses, transport layer, and TXT metadata for any discovered or published service
- **Best-practice footnotes** on the create-service-type, broadcast, and add-TXT-record forms

### On-device AI insights

- **Insights** — Long-press any service or library type to stream a Markdown-formatted explanation of what it does, why devices advertise it, and how to interact with it from *your* device
- **Chat (or Explore)** — Conversational assistant grounded in your live network: discovered services with their IP addresses, transport layer, and TXT records; published services; and the type library grouped by category
- **Query-triggered descriptions** — Mention a type by name in chat and the assistant pulls in authoritative descriptions from the catalog inline
- **Scan freshness awareness** — The assistant knows whether results are fresh, stale, or still populating and hedges answers accordingly
- **Prompt safety** — Source-priority hierarchy (TXT > type description > model training), named uncertainty phrasing, TXT-key allowlist, client-side refusal for prompt injection and off-topic queries
- **On-device only** — Everything runs through Apple's Foundation Models; no data leaves the device
- **Configurable** — Choose expertise level (Basic / Technical) and response length (Brief / Standard / Thorough) in Preferences

### Polish

- **Liquid Glass** on iOS 26+ / macOS 26+ with material fallbacks on older systems and visionOS
- **Haptic feedback** — medium tap on send, light tap per sentence while the model streams, selection taps on sort and navigation actions
- **Three-dot typing indicator** that ripples leading-to-trailing like iMessage, anchored to the leading edge of the streaming content
- **Accessibility** — VoiceOver labels and hints on every interactive element, region labels, heading traits, `.accessibilityIdentifier` for UI tests, Reduce Motion support, Dynamic Type throughout
- **Localized** in English, Spanish, French, German, Japanese, and Simplified Chinese with locale-appropriate typography

## Platform support

| Platform  | Minimum | Platform-specific polish |
|-----------|---------|--------------------------|
| **iOS**      | 18.6 | Pull-to-refresh, context menus, interactive keyboard dismiss, Liquid Glass compose bar |
| **iPadOS**   | 18.6 | Split-view navigation, drag-and-drop, trackpad hover, multi-column layouts |
| **macOS**    | 15.6 | Menu-bar commands, keyboard shortcuts, Settings scene, multi-window service details |
| **visionOS** | 2.0  | Native translucent surfaces, pointer hover, platform-appropriate tab labeling |

## Architecture

- **Swift 6.2** with strict concurrency (`Sendable`, `@MainActor`, structured concurrency, `defer`-guarded state resets)
- **SwiftUI** with MVVM, `@Observable` view models, `NavigationSplitView` for adaptive list-detail layouts
- **9 modular SPM packages** in `KozBonPackages/` — `BonjourCore`, `BonjourData`, `BonjourModels`, `BonjourScanning`, `BonjourUI`, `BonjourLocalization`, `BonjourAI`, `BonjourStorage`, plus the app target
- **Dependency injection** via `DependencyContainer` + SwiftUI environment; shared `BonjourServicesViewModel` at the app root so all tabs see the same scanner delegate
- **Core Data** for persistent custom service types
- **SwiftData** for user preferences
- **FoundationModels** (iOS 26 / macOS 26) for on-device AI with graceful fallback on ineligible devices
- **Design system** in `BonjourUI` — semantic `CGFloat` tokens (`.space16`, `.size16`, `.radius12`, `.stroke1`), `Image.xxx` SF-Symbol façade (no raw `Image(systemName: "…")` at call sites), `glassOrMaterialBackground` and `glassOrTintedBackground` helpers for Liquid-Glass-with-fallback
- **HapticFeedback** provider injected via environment so view models can request haptics without direct UIKit dependencies
- **Swift Testing** — 436 tests across 29 suites covering prompt-quality invariants, view-model logic, state machines (sentence haptic tracker, broadcast publish flow), design-token value pins, haptic mocks, scanner delegate flows, and chat-session rejection paths
- **SwiftLint** — project-wide rules plus a custom rule forbidding literal SF Symbol strings in favor of the `Image.xxx` façade
- **CI** — GitHub Actions workflows for iOS build+test, SPM package tests, SwiftLint, and multi-platform (macOS + visionOS) builds

## Build

```bash
# iOS Simulator
xcodebuild -workspace KozBon.xcworkspace -scheme KozBon \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' build

# macOS
xcodebuild -workspace KozBon.xcworkspace -scheme KozBon \
  -destination 'platform=macOS' build

# visionOS Simulator
xcodebuild -workspace KozBon.xcworkspace -scheme KozBon \
  -destination 'platform=visionOS Simulator,name=Apple Vision Pro' build

# SPM package tests (fastest — no simulator needed)
swift test --package-path KozBonPackages

# Lint
swift package --package-path KozBonPackages \
  --allow-writing-to-package-directory swiftlint
```

## Resources

- [Apple Foundation Models documentation](https://developer.apple.com/documentation/foundationmodels)
- [TCP and UDP ports used by Apple software products](https://support.apple.com/en-gb/HT202944)
- [IANA Service Name and Transport Protocol Port Number Registry](https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml)

## License

Copyright © 2016–present Kozinga. All rights reserved.
