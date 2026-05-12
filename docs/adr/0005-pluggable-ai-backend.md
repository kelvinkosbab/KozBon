# ADR 0005: Pluggable AI backend — Apple Foundation Models or Anthropic Claude

## Status

Accepted, 2026-05-12. Supersedes [ADR 0004](0004-on-device-only-ai.md).

## Context

[ADR 0004](0004-on-device-only-ai.md) settled the AI backend question as "Apple Foundation Models, exclusively, no cloud ever." That decision aged well for users on Apple-Intelligence-eligible hardware with the feature turned on. For everyone else, it left no AI surface at all:

- iPhones older than 15 Pro (and most non-Pro 16 models in some regions) cannot run Apple Intelligence.
- Macs without M-series silicon are excluded.
- Users on capable hardware who explicitly disabled Apple Intelligence in Settings see the same blank state as users on ineligible hardware.
- The `BonjourChatSession` and `BonjourServiceExplainer` factories return `nil` for those users, so the Chat tab is hidden and long-press Insights does nothing. From a product standpoint, the feature simply doesn't exist for them.

The privacy story that motivated ADR 0004 is still important — but the practical effect of "no cloud ever" turned out to be "no AI for a meaningful slice of users." Several user reports asked specifically for an Anthropic-backed option ("Apple Intelligence isn't available on my device, but I'd happily use my own Claude account"), modeled on Xcode 26's "Sign in with ChatGPT / Claude" Intelligence panel.

A cloud option is feasible because:

- The user supplies their own Anthropic API key (generated at `console.anthropic.com`). Their account is the one billed for usage; KozBon never operates the API key.
- Network-shape data (service names, hostnames, IP addresses, TXT records) sent to Anthropic stays under Anthropic's enterprise privacy terms — which is a stronger privacy posture than the user implicitly accepts every time they use a third-party service-discovery app that phones home. It's still a different posture from on-device, which is why this is opt-in.
- Anthropic's API supports streaming and prompt caching, so the user-perceived UX matches the on-device version (token-by-token streaming, fast time-to-first-token after the first cached system prompt).

## Decision

KozBon now ships **a pluggable AI backend**. Two options, presented in Settings as a picker:

1. **Apple Intelligence (default)** — `BonjourChatSession` / `BonjourServiceExplainer` backed by `FoundationModels`, exactly as ADR 0004 specified. Available only on capable hardware with Apple Intelligence enabled.
2. **Anthropic Claude (opt-in)** — `AnthropicBonjourChatSession` / `AnthropicBonjourServiceExplainer` backed by Anthropic's Swift SDK with prompt caching enabled on the system instructions block. Requires the user to paste an API key from `console.anthropic.com` into a Settings sheet; the key is stored in the iOS Keychain.

### Ground rules

- **Apple Intelligence stays the default.** A fresh install on capable hardware uses Foundation Models with no further setup. The privacy story for default users — "everything runs on-device, no data leaves your device" — is unchanged.
- **The Anthropic backend is strictly opt-in.** The user must explicitly select it in Settings *and* supply an API key. Until both happen, nothing leaves the device.
- **No API keys ever ship in the app.** KozBon never stores, embeds, or proxies API credentials. The user's Keychain is the only place the key lives.
- **The Settings copy adapts to the selected backend.** The current "Everything runs privately on your device — no data is sent to external servers" footer is accurate when Apple Intelligence is selected; when Anthropic is selected it changes to a clear "Your questions are sent to Anthropic's API using your own account" disclosure.
- **The Chat tab now appears for any user with at least one viable backend** — capable Apple Intelligence hardware *or* a configured Anthropic key. Previously the tab was hidden unless Apple Intelligence was available; now it's hidden only if neither path is configured.
- **No hybrid routing.** Each request goes entirely to the selected backend. We do not silently route some requests to cloud and others to on-device — that would leak the routing signal (which queries are "hard enough" for cloud) and undermine the opt-in promise.
- **Both AI surfaces honor the selection.** Long-press Insights and the conversational Chat tab both run on whichever backend the user has selected. A single Settings switch flips both.

### Implementation shape

The existing protocol / factory / mock pattern accommodates the new backend cleanly:

- `BonjourChatSessionProtocol` (unchanged) — both implementations satisfy the same interface.
- `BonjourChatSessionFactory` — gains backend-selection logic. Picks between the existing Foundation Models implementation and the new Anthropic implementation based on `preferencesStore.aiBackend` (a new `@Observable` field) and Keychain key availability.
- Same shape for `BonjourServiceExplainerFactory`.
- A new `AnthropicCredentialsStore` wraps Keychain access for the API key.
- The Anthropic Swift SDK lands as a new SPM dependency on `BonjourAI`.

## Consequences

**Positive:**

- The AI surface is now available to every user, not just those on Apple-Intelligence-eligible hardware. The Chat tab and long-press Insights can be turned on by any user willing to bring their own API key.
- Users on capable hardware retain the on-device default. Nothing about their privacy posture changes.
- Anthropic's larger context window (200K vs Foundation Models' ~4K) removes the prompt-compression pressure documented in ADR 0004 for cloud-using users. The chat context block can include richer per-service detail, and runaway-generation hardening (token cap, anti-repetition rules) becomes redundant on the cloud path.
- Operating cost stays zero for KozBon — users bring their own API keys. The product remains free.

**Negative:**

- **Privacy story is no longer a single sentence.** It splits along the backend: on-device (unchanged), or cloud (with clear disclosure). The README's "On-device only" phrasing has to soften to "On-device by default, with optional Anthropic Claude backend." That nuance is correct but a less crisp headline than ADR 0004's.
- **Two implementations to maintain.** Both backends need to track prompt changes, error handling, streaming semantics, cancellation. The protocol abstraction limits the cost but doesn't eliminate it.
- **New dependency surface** — the Anthropic Swift SDK becomes a transitive dependency of the app. SDK changes (auth model, model deprecations) become things KozBon has to track.
- **Cost shows up at the user's Anthropic bill.** Long chat sessions with lots of context can run a few cents per session. The default opt-out posture and the on-device fallback keep this from being a surprise, but we should keep an eye on whether the default response length is appropriate to bill the user for.
- **Anthropic-specific failure modes.** Rate limiting, model deprecations, regional unavailability — none of these existed on the on-device path. The factory must degrade gracefully (fall back to Apple Intelligence if available; otherwise surface a clear error).

## Alternatives considered

- **OAuth with claude.ai** (the literal Xcode model). Would let users sign in with their Anthropic account directly. Rejected for v1 because it requires KozBon to be registered with Anthropic as an OAuth client — not something we can do self-serve. If Anthropic opens the OAuth flow to indie apps, this becomes a future migration.
- **Hybrid / smart routing** (use Apple Intelligence for short prompts, fall back to Anthropic for longer ones). Rejected: the routing signal itself leaks data about the user's query, which undermines the privacy contract.
- **Multiple cloud providers** (OpenAI in addition to Anthropic). Rejected for v1 to keep the surface area small. Adding OpenAI later is a clean follow-up if there's demand.
- **Stay on ADR 0004's stance.** Rejected because it left users on ineligible hardware with no AI feature at all, and the workaround (buy a different device) doesn't actually translate to product-side reach. The cloud option recovers that audience while preserving the existing privacy posture for everyone who'd choose it anyway.
