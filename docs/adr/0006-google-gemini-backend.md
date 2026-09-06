# ADR 0006: Add Google Gemini as a third AI backend

## Status

Accepted, 2026-09-05. Extends ADR 0005 (which stays in force — this adds a
provider to the pluggable surface it introduced, it does not supersede it).

## Context

ADR 0005 made the AI backend pluggable and shipped two providers: on-device
Apple Foundation Models (the default) and Anthropic Claude (opt-in, BYO key).
GitHub Models was a third until GitHub retired it on 2026-07-30, leaving users
whose hardware can't run Apple Intelligence with exactly one cloud option.

Gemini is a reasonable second cloud option for this app: a generous free tier
on the Developer API, a million-token context window, and streaming with the
same user-perceived shape as the existing backends.

Two questions had to be settled before writing any code.

**Which Gemini API.** The Developer API
(`generativelanguage.googleapis.com`) authenticates with a single API key from
Google AI Studio. Vertex AI authenticates with service-account OAuth.

**Where the selected model lives.** `aiCloudModelIdentifier` was one shared
`String`, and its typed bridge lived inside `BonjourAIAnthropic`.

## Decision

**Ship Gemini via the Developer API**, as `BonjourAIGemini`, mirroring
`BonjourAIAnthropic`'s shape: client, SSE decoder, runtime model catalog with a
compiled-in offline floor, chat session, explainer, mock.

**Give each provider its own model slot.** `UserPreferences` gains
`aiGeminiModelRawValue` alongside `aiCloudModelRawValue`, and the bridge moves
to `BonjourAICore` as `PreferencesStore.aiCloudModelIdentifier(for:)`.

Ground rules carried from ADR 0005 apply unchanged: strictly opt-in, key in the
Keychain, Settings copy discloses that questions go to Google, and the factory
degrades to Apple Intelligence when no key is configured.

Two implementation constraints worth recording:

- **The key goes in the `x-goog-api-key` header, never the `?key=` query
  parameter** the Gemini docs also accept. Query strings land in logs, proxies,
  and crash reports.
- **The catalog filters to models advertising `generateContent`.**
  `GET /v1beta/models` returns the whole lineup — embedding, image, and TTS
  variants included — and offering one of those in a chat picker produces a
  request the API rejects.

## Consequences

- Users without Apple Intelligence hardware have a choice of cloud providers
  again, which is what the GitHub retirement took away.
- Every `AIBackend` / `AICloudProvider` switch gains a third case. The compiler
  enumerates them, which is why both remain enums rather than strings.
- The per-provider slot is an additive SwiftData property: existing rows decode
  with the default, so no migration plan is required.
- Gemini's wire format differs from Anthropic's in ways the abstraction doesn't
  hide — the assistant role is `model`, the model addresses the URL rather than
  the body, system instructions are a separate top-level field, and there is no
  terminal stop event. Each is pinned by a test.
- Google returns 403 for both a bad key and a genuine permission problem, so
  the mapping inspects the message to route the user to the right remediation.
- A third provider is a third set of brand strings and translations to keep
  current across 8 locales.

## Alternatives considered

- **Vertex AI.** More capable (regional endpoints, enterprise controls) but
  authenticates with service-account OAuth, which the paste-an-API-key sheet
  can't express, and which no consumer user of this app would have.
- **Keep one shared model slot** and validate the stored identifier against the
  active provider's catalog. No schema change, but switching providers to
  compare them silently forgets the previous model choice.
- **Generalize the two provider modules into one OpenAI-compatible client.**
  Gemini does offer an OpenAI-compatible endpoint, but it's a translation layer
  that lags the native API and doesn't expose the model list the picker needs.
