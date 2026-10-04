# KozBon

A multi-platform Apple app for discovering, broadcasting, and understanding Bonjour (mDNS/DNS-SD) network services. Rich service inspection, filter categories, a 158-entry service-type library, and AI-powered explanations — on-device by default, with optional Anthropic Claude or Google Gemini integration — on iPhone, iPad, Mac, and Apple Vision Pro.

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
- **158 built-in service types** — Pre-configured library covering HTTP, SSH, AirPlay, HomeKit, IPP, Matter, Thread, and more
- **Custom service types** — Define and persist your own entries with IANA-format identifiers
- **Service details** — Hostnames, IP addresses, transport layer, and TXT metadata for any discovered or published service
- **Context menus everywhere** — Copy service names, hostnames, IP addresses, full type strings, and individual TXT keys/values with a long-press
- **Best-practice footnotes** on the create-service-type, broadcast, and add-TXT-record forms
- **Sectioned Nearby list** — grouped one section per device by default, or one per service type (with a short description of the type) when sorting by service name
- **Siri and Shortcuts** — `Scan for Services` and `List Discovered Services` are exposed as App Intents with spoken phrases localized in all 8 languages, so they work from Siri, the Shortcuts app, and Spotlight

### Settings

- **Dedicated Settings tab** for display options, Insights configuration, and library management
- **Ambient background switch** turns off the per-tab colour wash and restores plain system styling; it also steps aside automatically for Increase Contrast, Reduce Transparency, and Smart Invert
- **Reset to defaults** restores built-in settings and clears custom service types

### AI insights (pluggable backend)

- **Insights** — Long-press any service or library type to stream a Markdown-formatted explanation of what it does, why devices advertise it, and how to interact with it from *your* device
- **Chat (or Explore on macOS/visionOS)** — Conversational assistant grounded in your live network: discovered services with their IP addresses, transport layer, and TXT records; published services; and the type library grouped by category
- **Query-triggered descriptions** — Mention a type by name in chat and the assistant pulls in authoritative descriptions from the catalog inline
- **Scan freshness awareness** — The assistant knows whether results are fresh, stale, or still populating and hedges answers accordingly
- **Prompt safety** — Source-priority hierarchy (TXT > type description > model training), named uncertainty phrasing, TXT-key allowlist, client-side refusal for prompt injection and off-topic queries
- **Pluggable backend** — a Settings picker between four paths ([ADR 0005](docs/adr/0005-pluggable-ai-backend.md), [ADR 0006](docs/adr/0006-google-gemini-backend.md), [ADR 0007](docs/adr/0007-openai-backend.md)):
  - **Apple Intelligence (default)** — Everything runs through Apple's Foundation Models on-device; no data leaves the device. Available on Apple-Intelligence-eligible hardware with the feature turned on.
  - **Anthropic Claude (opt-in)** — Sign in with your own Anthropic API key (stored in the iOS Keychain; KozBon never sees the key on a server). Requests are sent to Anthropic's API and billed to your Anthropic account. Available on any device — including older iPhones, non-M-series Macs, and devices where Apple Intelligence is disabled.
  - **Google Gemini (opt-in)** — Same shape, with your own Google AI Studio key against the Gemini Developer API.
  - **OpenAI GPT (opt-in)** — Same shape, with your own OpenAI API key against the Responses API. Requests opt out of server-side storage. API usage is billed by OpenAI, separately from a ChatGPT subscription.
  - The Claude, Gemini, and GPT model pickers load each provider's current model list using your key, so new models appear without an app update; offline they fall back to a compiled-in list. Each provider remembers its own choice, so switching back and forth preserves both.
- **Configurable** — Single Detail level setting (Basic / Technical) drives both vocabulary and response length, so the two settings can't drift out of sync

### Polish

- **Ambient background** — a slow mesh-gradient colour wash that drifts behind every tab, tinted per tab and carried into the detail pages opened from it; holds still under Reduce Motion or Low Power Mode
- **Liquid Glass** — translucent compose bars, tinted send buttons, and floating capsules, routed through one helper that uses `.glassEffect(in:)` on iOS / macOS and `.glassBackgroundEffect()` on visionOS
- **Haptic feedback** — medium tap on send, light tap per sentence while the model streams, selection taps on sort and navigation actions
- **Three-dot typing indicator** that ripples leading-to-trailing like iMessage, anchored to the leading edge of the streaming content
- **Markdown rendering** for streaming responses with code, headings, and lists
- **Pull-to-refresh** scanning on iPhone and iPad
- **Accessibility** — VoiceOver labels and hints on every interactive element, region labels, heading traits, `.accessibilityIdentifier` for UI tests, Reduce Motion support, Dynamic Type throughout
- **Localized** in English, Spanish, French, German, Japanese, Simplified Chinese, Arabic, and Hebrew — with right-to-left layout mirroring for Arabic and Hebrew

## Platform support

| Platform  | Minimum | Platform-specific polish |
|-----------|---------|--------------------------|
| **iOS**      | 26.0 | Pull-to-refresh, context menus, interactive keyboard dismiss, Liquid Glass compose bar, landscape and wide layouts including the iPhone Duo inner display |
| **iPadOS**   | 26.0 | Split-view navigation, drag-and-drop, trackpad hover, multi-column layouts |
| **macOS**    | 26.0 | Menu-bar commands, keyboard shortcuts, Settings scene, multi-window service details |
| **visionOS** | 26.0 | Native translucent surfaces, pointer hover, platform-appropriate tab labeling |

The minimums were raised to 26 together so no `#available` gating is needed for 26-era APIs — Liquid Glass, Foundation Models, and the Apple Intelligence surfaces are all unconditional.

## Architecture

- **Swift 6.2** with strict concurrency (`Sendable`, `@MainActor`, structured concurrency, `defer`-guarded state resets)
- **SwiftUI** with MVVM, `@Observable` view models, `NavigationSplitView` for adaptive list-detail layouts
- **Modular SPM packages** in `KozBonPackages/` — 15 modules, each a library product. The `KozBon/` Xcode target carries only the `@main` shim and the resources that must live in the main bundle, so contributors can move fast under `swift test` without touching project settings:
  - **`AppCore`** — the root scene (`AppCoreScene`), its view model (`AppCoreViewModel`), macOS menu commands, and the top-level tab destinations. The Xcode app target's `@main` struct is a 30-line shim that just renders `AppCoreScene()`.
  - **`BonjourCore`** — shared value types, constants, and utilities (`Constants`, `TransportLayer`, `InternetAddress`, `Logger`, `Clipboard`, `HapticFeedback`). Re-exports `Core` so downstream modules pick up `Logger` / `Loggable` without an explicit import.
  - **`BonjourStorage`** — all persistence in one module: the SwiftData preferences container (`PreferencesStore`, `UserPreferences`) and the legacy Core Data custom-service-type store (`CustomServiceType`, `MyCoreDataStack`, `MyDataManagerObject`).
  - **`BonjourLocalization`** — localized strings (8 languages including Arabic and Hebrew) backed by a String Catalog (`.xcstrings`). Type-safe `Strings` enum at call sites; no `NSLocalizedString` literals scattered through the views.
  - **`BonjourModels`** — domain models and the 158-entry service-type library (`BonjourServiceType`, `BonjourService`, `BonjourServiceSortType`); per-type icon / category / detail metadata.
  - **`BonjourScanning`** — Bonjour discovery and publishing (`BonjourServiceScanner`, `MyBonjourPublishManager`) with their protocol abstractions and mocks; `DependencyContainer` for environment-injected DI.
  - **`LocalNetworkMonitor`** — `NWPathMonitor`-backed primitive that tells the Discover tab whether the device is on a Wi-Fi or Ethernet path so it can surface a distinct empty state when scanning literally can't reach anything (cellular-only or offline). `@MainActor` protocol + production class + synchronous mock, driven by `AsyncStream` for structured cancellation.
  - **`BonjourAICore`** — the provider-agnostic AI layer every backend implements against: protocols (`BonjourChatSessionProtocol`, `BonjourServiceExplainerProtocol`), prompt builders (`BonjourServicePromptBuilder`, `BonjourChatPromptBuilder`), the input validator and safety rules, the intent broker that bridges tool calls to view-model side effects, shared chat UI primitives, mocks and simulator stubs, and `AICloudCredentialsStore` with Keychain + in-memory implementations.
  - **`BonjourAIApple`** — the on-device implementation on Apple's FoundationModels, plus `AppleIntelligenceSupport` for availability gating.
  - **`BonjourAIAnthropic`** — Anthropic Claude over a native `URLSession` + SSE streaming client (no third-party SDK), with prompt caching for the static system block and `AnthropicModelCatalog` fetching the live model list.
  - **`BonjourAIGemini`** — Google Gemini against the Gemini Developer API, with `GeminiModelCatalog` filtered to models advertising `generateContent`. Keys ride in the `x-goog-api-key` header, never the query string.
  - **`BonjourAIOpenAI`** — OpenAI GPT against the Responses API, with `store: false` on every request and `OpenAIModelCatalog` filtered to chat-capable model families.
  - **`BonjourAI`** — the umbrella. `CloudAwareBonjourChatSessionFactory` / `CloudAwareBonjourServiceExplainerFactory` read `preferencesStore.aiBackend` and route to the right provider; `@_exported import BonjourAICore` keeps older `import BonjourAI` call sites working.
  - **`BonjourUI`** — every SwiftUI view, view model, and the design-system primitives consumed by every screen (semantic `CGFloat` tokens, the `Image.xxx` SF-Symbol façade, the `AmbientMeshBackground` colour wash).
  - **`BonjourAppIntents`** — App Intents (`ScanForServicesIntent`, `ListDiscoveredServicesIntent`) for Siri / Shortcuts integration, plus the `BonjourService` / `BonjourServiceType` entity projections.
- **Dependency injection** via `DependencyContainer` + SwiftUI environment; the shared `BonjourServicesViewModel` is owned by `AppCoreViewModel` so the Discover and Chat tabs see the same scanner delegate
- **FoundationModels** for on-device AI, with availability gating that hides the AI surfaces on ineligible hardware rather than failing at call time
- **Pluggable AI backend** ([ADR 0005](docs/adr/0005-pluggable-ai-backend.md), extended by [ADR 0006](docs/adr/0006-google-gemini-backend.md) and [ADR 0007](docs/adr/0007-openai-backend.md)) — one protocol layer, four implementations, selected in Settings and swapped without an app restart. Each cloud provider's model list is fetched at runtime from its own API, falling back to a compiled-in list offline, and each remembers its own model choice. API keys live only in the Keychain (`whenUnlockedThisDeviceOnly`, never iCloud-synced); KozBon never operates them
- **Liquid Glass** via a single `platformGlassBackground` helper that routes to `.glassEffect(in:)` on iOS / macOS and `.glassBackgroundEffect()` on visionOS
- **HapticFeedback** provider injected via environment so view models can request haptics without direct UIKit dependencies
- **Swift Testing** — 1,271 tests across 110 suites covering prompt-quality invariants, view-model logic, state machines (sentence haptic tracker, broadcast publish flow), design-token value pins, haptic mocks, scanner delegate flows, streaming-client wire formats, and chat-session rejection paths
- **SwiftLint** — project-wide rules plus a custom rule forbidding literal SF Symbol strings in favor of the `Image.xxx` façade
- **CI** — GitHub Actions workflows for Native CI (iOS + macOS build matrix), SPM package tests, multi-platform builds (macOS + visionOS), SwiftLint, a String Catalog validator that pins translation completeness across all 8 locales, a Markdown link checker, and a Release workflow that publishes a GitHub Release whenever a `v*` tag is pushed

### Where the structure comes from

The shape above — a two-file Xcode app target sitting on a 15-module local SPM package — is not ad hoc. It follows the Apple-platform conventions installed by [AppBootstrapAI](https://github.com/kelvinkosbab/AppBootstrapAI):

- **`apple-modular-architecture.md`** sets the thin-app-target-over-local-package layout, the one-way module dependency graph, and the rule that a cross-module need moves *down* a layer rather than becoming a feature-to-feature edge.
- **`apple-spm-package-conventions.md`** supplies the manifest pattern: one `makeTargets(name:…)` call per module composed with `+`, a single `sharedSwiftSettings` pinning `.swiftLanguageMode(.v6)`, and a uniform `{Module}/Sources` + `{Module}/Tests` layout. Adding a module is a two-line change to [`Package.swift`](KozBonPackages/Package.swift).
- 18 rules and 10 skills are committed under [`.claude/`](.claude/), so every agent session in this repo inherits the same conventions — accessibility, localization, Swift 6 strict concurrency, logging, testing strategy, and the TestFlight release path — instead of being told them again each time.

Installed 2026-06-12 from bundle commit `b64ec75`. [`.claude/.appbootstrap-manifest.json`](.claude/.appbootstrap-manifest.json) records the installed file set with checksums, so the bundle can be updated without clobbering local edits.

## Build

```bash
# iOS Simulator
xcodebuild -workspace KozBon.xcworkspace -scheme KozBon \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

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
