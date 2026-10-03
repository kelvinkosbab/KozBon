# Changelog

All notable changes to KozBon will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

Nothing yet.

## [4.7] - 2026-10-03

### Added

- **Google Gemini backend ([ADR 0006](docs/adr/0006-google-gemini-backend.md))** — a third AI option alongside Apple Intelligence and Anthropic Claude, using your own Google AI Studio key from Settings → Assistant. Runs against the Gemini Developer API; the key rides in the `x-goog-api-key` header, never a query string, and lives in the Keychain (`whenUnlockedThisDeviceOnly`) like the Anthropic one.
- Runtime model catalogs for both cloud providers — the Claude and Gemini model pickers fetch each provider's current model list with your key, so new models appear without an app update. Offline, they fall back to a compiled-in list. Resolution is live fetch → this session's cached fetch (1h TTL) → compiled-in.
- Each cloud provider now remembers its own model choice, so switching backends and back preserves both instead of handing one provider the other's identifier.
- **Ambient background** — a slow mesh-gradient colour wash behind every tab, tinted per tab and carried into the detail pages opened from it.
- Ambient Background switch in Settings → Display turns the wash off and restores plain system styling. It also steps aside automatically for Increase Contrast, Reduce Transparency, and Smart Invert, and holds still under Reduce Motion or Low Power Mode.
- Sectioned Nearby list — one section per device by default, or one per service type with a short description of the type when sorting by service name.
- Siri and Shortcuts support — `Scan for Services` and `List Discovered Services` are exposed as App Intents with spoken phrases localized in all 8 languages, reachable from Siri, the Shortcuts app, and Spotlight.
- iPhone landscape and wide layouts, including the iPhone Duo's inner display, where the sidebar and detail pane open side by side. Settings, Chat, and detail pages keep a readable width, and the service badge names the host too — "AirPlay – Living Room".
- Every AI Insights long-press now has a matching VoiceOver action, and the Broadcast forms move VoiceOver focus to the first error when a submit fails.
- Permission prompts are now translated into Arabic and Hebrew.
- The built-in service-type library grows to 158 entries, refreshed against the IANA service-name registry.

### Changed

- Chat suggestions are now iMessage-style blue capsules with a send arrow, so they read as prompts you can send rather than links.
- The Preferences tab is now called Settings.
- The AI layer splits into `BonjourAICore` (protocols, prompt builders, safety, credentials store), `BonjourAIApple`, `BonjourAIAnthropic`, and `BonjourAIGemini`, with `BonjourAI` as the umbrella whose `CloudAware*Factory` routers pick a provider from `preferencesStore.aiBackend`. Replaces the former `BonjourAI` / `BonjourAICloud` pair.
- Minimum OS raised to iOS 26, iPadOS 26, macOS 26, and visionOS 26 — all together, so no `#available` gating is needed for 26-era APIs.

### Removed

- **GitHub Models backend** — GitHub retired the service on 2026-07-30, taking the inference API and the endpoint's DNS with it, so every request from a GitHub-backed session failed outright. A stored `"github"` preference migrates to Apple Intelligence, and Settings shows a one-time notice offering to delete the orphaned Personal Access Token.
- The chat tab's unread badge. It was pre-baked into a bitmap via `ImageRenderer` because the `Tab` icon channel strips wrapping modifiers; with the dot gone, that flattening went too and the icon falls back to the system tint.

## [4.6] - 2026-06-10

### Fixed

- The assistant tab badge and brand icons render correctly again on the Xcode 27 / iOS 26 SDK.
- Swipe-delete animation glitch in the broadcast TXT-record list.

### Changed

- Brand names (Apple Intelligence, Claude, GitHub) now reliably stay in English across every locale.

## [4.5] - 2026-06-04

Covers everything landed since 4.3, including work staged for an unreleased 4.4.

### Added

- Chat tab shows a red badge in compact / portrait windows when an assistant reply lands while you're scrolled away from the bottom. The badge clears the moment you scroll back to the latest message.
- New What's New page in Preferences → About listing every release since 3.0.
- Wider Discover and Library sidebars on macOS so hostnames and service-type identifiers fit on one line.
- Tighter wide-window tab bar and detail layouts on iPad and macOS.
- **Pluggable AI backend ([ADR 0005](docs/adr/0005-pluggable-ai-backend.md))** — Settings now offers a picker between on-device Apple Foundation Models (the default, unchanged privacy story) and Anthropic Claude (opt-in, via the user's own API key). Chat and Insights both honor the selection; the Chat tab now surfaces for any user with at least one viable backend, including users on Apple-Intelligence-ineligible hardware who bring a Claude account.
- **Sign in to Claude** sheet in Settings — paste an Anthropic API key from `console.anthropic.com`, validated against the `sk-ant-` prefix. Keys land in the iOS Keychain (`whenUnlockedThisDeviceOnly`, never iCloud-synced); KozBon never sees the key on a server.
- **Claude model picker** — choose between Opus (most capable), Sonnet (balanced, default), or Haiku (fastest, lowest cost). Selection applies to both the Chat tab and long-press Insights.
- New **`BonjourAICloud`** Swift package — provider-agnostic cloud-AI scaffolding (`AICloudProvider`, `AICloudCredentialsStore`, `AICloudError`, `AIBackend`) plus the Anthropic v1 implementation: native `URLSession` + SSE streaming client (no third-party SDK dependency), `AnthropicBonjourChatSession`, `AnthropicBonjourServiceExplainer`, and `CloudAware*Factory` routers. Designed to host additional providers (OpenAI, Gemini) as additive enum cases.
- 27 new localized strings across all 8 locales (en/es/fr/de/ja/zh-Hans/ar/he) covering the new AI Backend section, sign-in sheet, model picker, and accessibility hints.
- Search bar on the Discover tab — case-insensitive substring filter against service name, hostname, friendly type name, and `_type._tcp` wire form. Composes with the existing sort/category filter.
- Settings → Insights footer now surfaces a localized notice when Apple Intelligence is in an actionable unavailable state ("turned off in Settings", "model still downloading"), so users on capable hardware know what to do when AI features don't respond.
- Insights footer copy now mentions the Chat tab as well as long-press service explanations, since the toggle gates both.
- Arabic and Hebrew translations across the entire string catalog (395 keys × 2 languages = 790 new translations covering UI labels, navigation, accessibility text, error messages, and the full service-type protocol-description library). Layout mirrors automatically for these right-to-left locales; the diagonal arrow on chat suggestion cards now flips to point in the user's reading direction.
- Distinct "Not connected to Wi-Fi" empty state on the Discover tab. When the device is on cellular-only or offline, Bonjour discovery can't reach anything from there; the new state explains the cause (with the `wifi.slash` symbol and locale-specific copy) instead of leaving users staring at the generic "no services found" message and a "Start Scanning" button that wouldn't help.
- Field-level guidance on the create-custom-service-type form. The "Service name" footer now explains the field is the human-readable display label users see when browsing; the "Bonjour type" footer explains it's the protocol identifier other devices look up to discover services of this kind, with `_http._tcp` / `_airplay._tcp` as concrete examples and a note about exact-type matching.

### Changed

- The Chat tab visibility gate broadens to "Apple Intelligence available OR Anthropic key configured" so users on ineligible hardware with a Claude account get a working Chat tab. Previously gated solely on Apple Intelligence availability per ADR 0004.
- The on-device-only privacy claim in the README softens to "On-device by default, with optional Anthropic Claude backend." The default story is unchanged; cloud users see a clear "Your questions are sent to Anthropic" footer in Settings.
- Reset to Defaults section in Preferences animates in/out smoothly when any preference changes, not just the AI toggle.
- Picking the default sort option ("Host name ascending") in Preferences no longer makes the Reset to Defaults button appear — the persisted state stays canonical (`""` = default).
- Chat assistant accessibility label keeps the localized "thinking…" text until the response stream finishes, then swaps once to the final content. Previously the label updated on every streamed token, which made VoiceOver re-announce the bubble repeatedly.
- Chat responses now render numbered Markdown lists (`1.`, `2.`, …) as proper enumerated items in addition to the existing bullet (`-`) and heading (`#`/`##`/`###`) support. The Foundation Model's discovered-services responses always arrived as numbered lists; previously the renderer dropped them back to plain paragraphs, which is what made "What's on my network?" read as a wall of text. Paired with a tightened FORMATTING section in the chat system prompt that includes a worked example so the model has a clean format to mirror.
- Discover empty-state CTA reads "Scan nearby" (was "Start scanning") in all 8 locales — shorter, friendlier, and pairs better with the Discover tab's "Nearby" name in the nav.
- The "This description will be used to explain your service when users long press 'Insights'" footnote on the Additional Details field of the create-service-type form now only renders when AI Insights is enabled in Preferences. When the feature is disabled, mentioning it was misleading — pointing at an affordance the user can't actually use.

### Fixed

- Asking "What devices are on my network?" in chat could push the on-device Foundation Model into a generation loop where every discovered service repeated until the context window was exceeded. Three layers of defense now bound the failure: the chat system prompt has explicit anti-repetition rules, discovered/published services in the context block are numbered (so the model has explicit indices to stop at), and `streamResponse` runs with `GenerationOptions(maximumResponseTokens: 2048)` as a hard cap.
- Navigating away from the chat tab or dismissing the Insights sheet mid-stream now properly cancels generation. Previously the model kept generating into a no-longer-visible bubble and tied up the session for the next interaction.

## [4.3] - 2026-04-29

First versioned changelog entry. The 4.3 release ships:

- On-device AI Chat tab grounded in the user's live network, with Apple Foundation Models tool-calling for service-type creation and broadcast drafting (see "AI Chat" in `README.md` for the full feature surface).
- 110+-entry built-in service-type library covering HTTP, AirPlay, AirDrop, HomeKit, Matter, Thread, IPP, SSH, SMB, Sonos, Spotify Connect, Chromecast, Plex, Jellyfin, and more.
- Service broadcasting with custom port, domain, and TXT records.
- Long-press Insights — on-device AI explanation of what a discovered service does and how to interact with it.
- Siri / App Intents — "Scan for Services" and "List Discovered Services" voice phrases.
- Apple + non-Apple device identification from Bonjour TXT records.
- Six languages: English, Spanish, French, German, Japanese, Simplified Chinese.
- iOS 18.6+, iPadOS 18.6+, macOS 15.6+, visionOS 2.0+ — Liquid Glass on iOS 26 / macOS 26.

[Unreleased]: https://github.com/kelvinkosbab/KozBon/compare/v4.7...HEAD
[4.7]: https://github.com/kelvinkosbab/KozBon/releases/tag/v4.7
[4.6]: https://github.com/kelvinkosbab/KozBon/releases/tag/v4.6
[4.5]: https://github.com/kelvinkosbab/KozBon/releases/tag/v4.5
[4.3]: https://github.com/kelvinkosbab/KozBon/releases/tag/v4.3
