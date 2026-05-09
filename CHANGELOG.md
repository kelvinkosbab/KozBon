# Changelog

All notable changes to KozBon will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Search bar on the Discover tab — case-insensitive substring filter against service name, hostname, friendly type name, and `_type._tcp` wire form. Composes with the existing sort/category filter.
- Settings → Insights footer now surfaces a localized notice when Apple Intelligence is in an actionable unavailable state ("turned off in Settings", "model still downloading"), so users on capable hardware know what to do when AI features don't respond.
- Insights footer copy now mentions the Chat tab as well as long-press service explanations, since the toggle gates both.

### Changed

- Reset to Defaults section in Preferences animates in/out smoothly when any preference changes, not just the AI toggle.
- Picking the default sort option ("Host name ascending") in Preferences no longer makes the Reset to Defaults button appear — the persisted state stays canonical (`""` = default).
- Chat assistant accessibility label keeps the localized "thinking…" text until the response stream finishes, then swaps once to the final content. Previously the label updated on every streamed token, which made VoiceOver re-announce the bubble repeatedly.

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
