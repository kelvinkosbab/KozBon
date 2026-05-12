# ADR 0004: On-device only AI via Apple Foundation Models

## Status

Superseded by [ADR 0005](0005-pluggable-ai-backend.md), 2026-05-12.

Originally accepted, 2026-04-25.

> ADR 0005 introduces a pluggable AI backend: Apple Foundation Models remains the default for users with Apple Intelligence enabled, with an opt-in Anthropic Claude backend for users who want cloud-quality answers (or who don't have Apple Intelligence on their device). The "no cloud, ever" decision recorded below proved too narrow once Apple Intelligence's hardware floor turned out to leave a meaningful slice of users without any AI surface at all. See ADR 0005 for the new shape and ground rules.

## Context

KozBon's AI features — long-press Insights and the Chat tab — answer questions about the user's local network and the Bonjour service-type library. Three implementation paths existed:

1. **Cloud-based LLM** (OpenAI, Anthropic, Google) called from the device.
2. **Hybrid** — small on-device model for fast cases, cloud fallback for complex ones.
3. **On-device only** via Apple's Foundation Models framework (iOS 26+).

KozBon's product-side constraints:

- The user's network is, by definition, sensitive — service names ("Living Room Apple TV"), hostnames ("Kelvin's MacBook"), and IP addresses identify the user and their devices. Sending this to a third-party server is a privacy regression for a tool that exists to *inspect* a private network.
- The app must work offline for the same reason — no network, no cloud round-trip available.
- Users on capable hardware (iPhone 15 Pro+, M-series Macs, Vision Pro) increasingly expect "private" to mean "no data leaves the device."

Engineering constraints:

- Apple Foundation Models is in `import FoundationModels`, gated behind `iOS 26 / macOS 26 / visionOS 26`, with a `~4K`-token context window on the on-device model.
- The framework provides `LanguageModelSession`, streaming responses, and tool calling — feature-complete enough for KozBon's needs.
- The model is downloaded as part of Apple Intelligence; users must enable Apple Intelligence in iOS Settings, and devices that don't support it can't run the chat.

## Decision

KozBon ships AI features that run **exclusively on-device** via Apple Foundation Models, with no cloud fallback and no third-party LLM integration ever.

Concretely:

- `BonjourServiceExplainer` (Insights) and `BonjourChatSession` (Chat) wrap `LanguageModelSession`. There is no `RemoteChatSession` and there will not be one.
- `AppleIntelligenceSupport` exposes the device's availability state distinctly: `.available`, `.deviceNotEligible`, `.appleIntelligenceDisabled`, `.modelNotReady`, `.otherUnavailable`. Devices that fundamentally can't run on-device AI hide the AI surface entirely; capable devices in temporary unavailable states show a "turn on Apple Intelligence in Settings" CTA.
- The factory pattern (`BonjourChatSessionFactory`, `BonjourServiceExplainerFactory`) returns the real implementation on capable devices, a `Simulator*` lorem-ipsum stand-in in the iOS Simulator, and `nil` on ineligible devices.
- The Chat tab is conditionally rendered on `AppleIntelligenceSupport.isDeviceSupported && preferencesStore.aiAnalysisEnabled` — the Discovery tab still works for users who can't run AI.

The `Strings.Settings.aiAnalysisFooter` reads "Everything runs privately on your device — no data is sent to external servers." That copy is a contract.

## Consequences

**Positive:**

- The privacy story is unambiguous and correct. No vendor relationships, no API keys, no per-request cost, no data residency questions.
- The app works offline for the AI features. Cell-only or airplane-mode users get the same experience as Wi-Fi users.
- No infrastructure cost. KozBon doesn't operate a backend for AI calls.
- Apple's framework handles model lifecycle (download, update, eviction) — KozBon doesn't ship the weights.

**Negative:**

- **Gated by Apple Intelligence support.** Older iPhones, Macs without M-series silicon, and any device where the user has Apple Intelligence disabled get no AI features. The fallback is "use the rest of the app, which still works." That's an acceptable trade for KozBon (an inspection tool that's useful without AI), but it would be unacceptable for an app whose AI is the product.
- **~4K context window.** Forces aggressive prompt compression. The chat context block had to be tightened (numbered service lists, per-category counts instead of full type enumerations, prompt-injection sanitization) and the chat-runaway hardening commit added a `maximumResponseTokens: 2048` cap. A cloud LLM with a 200K window would not have this constraint.
- **Single SDK vendor lock-in.** If Apple removes or changes Foundation Models materially, KozBon has no fallback. Mitigated by wrapping the framework in protocols (`BonjourChatSessionProtocol`, `BonjourServiceExplainerProtocol`) so the impl could swap to something else if needed; the feature would have to ship with a privacy regression though.
- **No transcripts / analytics.** Without a cloud round-trip, we can't see what users actually ask. Diagnostics are limited to what `os.Logger` captures and what users voluntarily share in bug reports.

## Alternatives considered

- **OpenAI / Anthropic API integration.** Rejected on the privacy story alone — sending the user's network shape to a third party contradicts the product's value proposition.
- **Hybrid: small on-device model for routine queries, cloud for harder ones.** Rejected because the trigger that decides "this is hard, send to cloud" leaks the same data we're trying to keep local. There's no privacy-preserving way to make that decision.
- **Self-hosted LLM accessed by the device.** Possible but not practical — KozBon is a consumer Bonjour scanner, not a self-hosted-LLM front-end. The infrastructure cost would dwarf the app's revenue.
- **No AI features.** Considered. Rejected because the use case (long-press to learn what a service does, ask "what's on my network?") is genuinely valuable, and Apple Foundation Models made the privacy-respecting version viable.
