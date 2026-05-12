# KozBon

A multi-platform Apple app for discovering, broadcasting, and understanding Bonjour (mDNS/DNS-SD) network services. Rich service inspection, filter categories, a 110+ service-type library, and AI-powered explanations — on-device by default, with optional Anthropic Claude integration — on iPhone, iPad, Mac, and Apple Vision Pro.

📲 [Download on the App Store](https://apps.apple.com/app/kozbon/id1193790136)

## Quick start

Get KozBon running locally in under a minute:

```bash
git clone https://github.com/kelvinkosbab/KozBon.git
cd KozBon
open KozBon.xcworkspace
```

Then `⌘R` in Xcode against an iOS / macOS / visionOS destination. The first run will scan your local network and surface every Bonjour service in reach.

To run the SPM package tests (no simulator needed, ~1 second):

```bash
swift test --package-path KozBonPackages
```

For full build commands per platform, see [Build](#build) below. For contribution guidelines, see [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Features

### Discover & broadcast

- **Service discovery** — Live scan of your local network with filter categories (Smart Home, Apple Devices, Media & Streaming, Printers & Scanners, Remote Access)
- **Service broadcasting** — Publish custom services with configurable port, domain, and TXT records; edit TXT records on already-published services
- **110+ built-in service types** — Pre-configured library covering HTTP, SSH, AirPlay, HomeKit, IPP, Matter, Thread, and more
- **Custom service types** — Define and persist your own entries with IANA-format identifiers
- **Service details** — Hostnames, IP addresses, transport layer, and TXT metadata for any discovered or published service
- **Context menus everywhere** — Copy service names, hostnames, IP addresses, full type strings, and individual TXT keys/values with a long-press
- **Best-practice footnotes** on the create-service-type, broadcast, and add-TXT-record forms

### Preferences

- **Dedicated Preferences tab** for display options, Insights configuration, and library management
- **Reset to defaults** restores built-in settings and clears custom service types

### AI insights (pluggable backend)

- **Insights** — Long-press any service or library type to stream a Markdown-formatted explanation of what it does, why devices advertise it, and how to interact with it from *your* device
- **Chat (or Explore on macOS/visionOS)** — Conversational assistant grounded in your live network: discovered services with their IP addresses, transport layer, and TXT records; published services; and the type library grouped by category
- **Query-triggered descriptions** — Mention a type by name in chat and the assistant pulls in authoritative descriptions from the catalog inline
- **Scan freshness awareness** — The assistant knows whether results are fresh, stale, or still populating and hedges answers accordingly
- **Prompt safety** — Source-priority hierarchy (TXT > type description > model training), named uncertainty phrasing, TXT-key allowlist, client-side refusal for prompt injection and off-topic queries
- **Pluggable backend** — ADR 0005 introduces a Settings picker between two paths:
  - **Apple Intelligence (default)** — Everything runs through Apple's Foundation Models on-device; no data leaves the device. Available on Apple-Intelligence-eligible hardware with the feature turned on.
  - **Anthropic Claude (opt-in)** — Sign in with your own Anthropic API key (stored in the iOS Keychain; KozBon never sees the key on a server). Requests are sent to Anthropic's API and billed to your Anthropic account. Choose between Opus / Sonnet (default) / Haiku. Available on any device — including older iPhones, non-M-series Macs, and devices where Apple Intelligence is disabled.
- **Configurable** — Single Detail level setting (Basic / Technical) drives both vocabulary and response length, so the two settings can't drift out of sync

### Polish

- **Liquid Glass** on iOS 26+ / macOS 26+ — translucent compose bars, tinted send buttons, and floating capsules, with a material fallback on older systems and visionOS
- **Haptic feedback** — medium tap on send, light tap per sentence while the model streams, selection taps on sort and navigation actions
- **Three-dot typing indicator** that ripples leading-to-trailing like iMessage, anchored to the leading edge of the streaming content
- **Markdown rendering** for streaming responses with code, headings, and lists
- **Pull-to-refresh** scanning on iPhone and iPad
- **Accessibility** — VoiceOver labels and hints on every interactive element, region labels, heading traits, `.accessibilityIdentifier` for UI tests, Reduce Motion support, Dynamic Type throughout
- **Localized** in English, Spanish, French, German, Japanese, Simplified Chinese, Arabic, and Hebrew — with right-to-left layout mirroring for Arabic and Hebrew

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
- **Modular SPM packages** in `KozBonPackages/`. The `KozBon/` Xcode target itself only carries the `@main` shim — every line of business logic lives in a package, so contributors can move fast under `swift test` without touching project settings:
  - **`AppCore`** — the root scene (`AppCoreScene`), its view model (`AppCoreViewModel`), macOS menu commands, and the top-level tab destinations. The Xcode app target's `@main` struct is an 8-line shim that just renders `AppCoreScene()`.
  - **`BonjourCore`** — shared value types, constants, and utilities (`Constants`, `TransportLayer`, `InternetAddress`, `Logger`, `Clipboard`). Re-exports `Core` so downstream modules pick up `Logger` / `Loggable` without an explicit import.
  - **`BonjourStorage`** — all persistence in one module: the SwiftData preferences container (`PreferencesStore`, `UserPreferences`) and the legacy Core Data custom-service-type store (`CustomServiceType`, `MyCoreDataStack`, `MyDataManagerObject`).
  - **`BonjourLocalization`** — localized strings (8 languages including Arabic and Hebrew) backed by a String Catalog (`.xcstrings`). Type-safe `Strings` enum at call sites; no `NSLocalizedString` literals scattered through the views.
  - **`BonjourModels`** — domain models and the 110+-entry service-type library (`BonjourServiceType`, `BonjourService`, `BonjourServiceSortType`); per-type icon / category / detail metadata.
  - **`BonjourScanning`** — Bonjour discovery and publishing (`BonjourServiceScanner`, `MyBonjourPublishManager`) with their protocol abstractions and mocks; `DependencyContainer` for environment-injected DI.
  - **`LocalNetworkMonitor`** — `NWPathMonitor`-backed primitive that tells the Discover tab whether the device is on a Wi-Fi or Ethernet path so it can surface a distinct empty state when scanning literally can't reach anything (cellular-only or offline). `@MainActor` protocol + production class + synchronous mock, driven by `AsyncStream` for structured cancellation.
  - **`BonjourAI`** — on-device AI built on FoundationModels: explainer for service-detail Insights, multi-turn chat session with tool-calling, prompt builders (`BonjourServicePromptBuilder`, `BonjourChatPromptBuilder`), input validator, and the intent broker that bridges tool calls to view-model side effects.
  - **`BonjourAICloud`** — cloud-AI backend per [ADR 0005](docs/adr/0005-pluggable-ai-backend.md). Provider-agnostic scaffolding (`AICloudProvider`, `AICloudCredentialsStore` with Keychain + in-memory implementations, `AICloudError`, `AIBackend` + `AnthropicModel` enums) plus the Anthropic v1 implementation: native `URLSession`-based streaming client with prompt caching, `AnthropicBonjourChatSession` and `AnthropicBonjourServiceExplainer` conforming to the same protocols as the on-device side, and `CloudAware*Factory` routers that pick between on-device and cloud based on `preferencesStore.aiBackend`.
  - **`BonjourUI`** — every SwiftUI view, view model, and the design-system primitives consumed by every screen (semantic `CGFloat` tokens, the `Image.xxx` SF-Symbol façade, `glassOrMaterialBackground` / `glassOrTintedBackground` Liquid-Glass-with-fallback helpers).
  - **`BonjourAppIntents`** — App Intents (`ScanForServicesIntent`, `ListDiscoveredServicesIntent`) for Siri / Shortcuts integration, plus the `BonjourService` / `BonjourServiceType` entity projections.
- **Dependency injection** via `DependencyContainer` + SwiftUI environment; the shared `BonjourServicesViewModel` is owned by `AppCoreViewModel` so the Discover and Chat tabs see the same scanner delegate
- **FoundationModels** (iOS 26 / macOS 26) for on-device AI with graceful fallback on ineligible devices
- **Pluggable cloud AI** ([ADR 0005](docs/adr/0005-pluggable-ai-backend.md)) — provider-agnostic protocol layer (`AICloudCredentialsStore`, `AIBackend`) with an Anthropic Claude v1 implementation. Native `URLSession` + SSE streaming client, no third-party SDK dependency; prompt caching for the static system block. API keys live only in the Keychain (`whenUnlockedThisDeviceOnly`, never iCloud-synced); KozBon never operates them
- **HapticFeedback** provider injected via environment so view models can request haptics without direct UIKit dependencies
- **Swift Testing** for unit coverage of prompt-quality invariants, view-model logic, state machines (sentence haptic tracker, broadcast publish flow), design-token value pins, haptic mocks, scanner delegate flows, and chat-session rejection paths
- **SwiftLint** — project-wide rules plus a custom rule forbidding literal SF Symbol strings in favor of the `Image.xxx` façade
- **CI** — GitHub Actions workflows for Native CI (iOS + macOS build matrix), SPM package tests, multi-platform builds (macOS + visionOS), SwiftLint, a String Catalog validator that pins translation completeness across all 8 locales, a Markdown link checker, and a Release workflow that publishes a GitHub Release whenever a `v*` tag is pushed

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
