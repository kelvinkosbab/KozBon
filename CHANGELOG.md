# Changelog

All notable changes to KozBon will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Search bar on the Discover tab — case-insensitive substring filter against service name, hostname, friendly type name, and `_type._tcp` wire form. Composes with the existing sort/category filter.
- Settings → Insights footer now surfaces a localized notice when Apple Intelligence is in an actionable unavailable state ("turned off in Settings", "model still downloading"), so users on capable hardware know what to do when AI features don't respond.
- Insights footer copy now mentions the Chat tab as well as long-press service explanations, since the toggle gates both.
- Arabic and Hebrew translations across the entire string catalog (395 keys × 2 languages = 790 new translations covering UI labels, navigation, accessibility text, error messages, and the full service-type protocol-description library). Layout mirrors automatically for these right-to-left locales; the diagonal arrow on chat suggestion cards now flips to point in the user's reading direction.
- Distinct "Not connected to Wi-Fi" empty state on the Discover tab. When the device is on cellular-only or offline, Bonjour discovery can't reach anything from there; the new state explains the cause (with the `wifi.slash` symbol and locale-specific copy) instead of leaving users staring at the generic "no services found" message and a "Start Scanning" button that wouldn't help.
- Field-level guidance on the create-custom-service-type form. The "Service name" footer now explains the field is the human-readable display label users see when browsing; the "Bonjour type" footer explains it's the protocol identifier other devices look up to discover services of this kind, with `_http._tcp` / `_airplay._tcp` as concrete examples and a note about exact-type matching.

### Changed

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

[Unreleased]: https://github.com/kelvinkosbab/KozBon/compare/v4.3...HEAD
[4.3]: https://github.com/kelvinkosbab/KozBon/releases/tag/v4.3
