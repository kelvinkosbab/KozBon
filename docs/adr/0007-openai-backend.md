# ADR 0007: Add OpenAI as a fourth AI backend

## Status

Accepted, 2026-10-04. Extends ADR 0005 and ADR 0006, both of which stay in
force — this adds a provider to the pluggable surface, it does not change it.

## Context

ADR 0006 brought the cloud options to two (Anthropic Claude, Google Gemini).
OpenAI's GPT models are the ones users most often ask for by name — usually
as "ChatGPT", which is a consumer subscription, not an API credential. A
ChatGPT Plus subscriber has no API key and can't use one with KozBon.

Two questions had to be settled.

**Which OpenAI API.** OpenAI ships two text-generation endpoints: Chat
Completions (`/v1/chat/completions`) and the newer Responses API
(`/v1/responses`).

**What to call it.** "ChatGPT" is what users recognize; "OpenAI" is what
issues the key the sign-in sheet asks for.

## Decision

**Ship OpenAI via the Responses API**, as `BonjourAIOpenAI`, mirroring
`BonjourAIGemini`'s shape: client, SSE decoder, runtime model catalog with a
compiled-in offline floor, chat session, explainer, mock. The selected model
gets its own preference slot (`aiOpenAIModelRawValue`), per ADR 0006.

**Label it "OpenAI GPT"**, matching the company-plus-family pattern of
"Anthropic Claude" and "Google Gemini", and say in the sign-in copy that API
usage is billed separately from a ChatGPT subscription.

Implementation constraints worth recording:

- **Every request sends `store: false`.** KozBon replays its own history on
  each turn, so a server-side copy would be retention with no benefit.
- **Reasoning models get `reasoning.effort: "low"`, and only they do.** At
  the default effort a reasoning model can spend the whole output budget
  thinking about a one-line question; sending the parameter to a model that
  doesn't accept it fails the request outright. The allowlist
  (`OpenAIReasoning.forModel(_:)`) is by identifier family, and an unknown
  family gets nothing.
- **The output budget is 4,096 tokens per chat turn**, against 1,024 for
  Claude and Gemini, because on reasoning models it also pays for the hidden
  reasoning. An incomplete response with no text throws rather than finishing
  normally, which would otherwise roll the turn back silently.
- **The catalog filters by name.** `GET /v1/models` returns identifiers only,
  with no capability field, mixing chat models with embedding, speech, image,
  moderation, and realtime ones — so the filter keeps the `gpt-` and
  `o`-series families, drops the specialized variants and dated snapshots,
  and sorts newest first. Display names are derived from the identifier
  (`gpt-5.4-mini` → "GPT-5.4 Mini") because the endpoint has none.
- **429 means two things.** `insufficient_quota` is an empty balance and
  routes to the billing remediation; any other 429 is a rate limit.

## Consequences

- Users without Apple Intelligence hardware have a third cloud choice.
- Every `AIBackend` / `AICloudProvider` switch gains a case — the compiler
  enumerates them.
- Adding the case exposed that `AppCoreViewModel.shouldShowChatTab` counted
  only an Anthropic key, hiding the Chat tab from Gemini users on ineligible
  hardware since ADR 0006. It now enumerates every live provider.
- The name-based catalog filter is the piece most likely to need upkeep as
  OpenAI adds model families; a model it wrongly drops is still reachable as
  a stored identifier, but won't appear in the picker.
- A fourth provider is another set of brand strings to keep current across
  8 locales.

## Alternatives considered

- **Chat Completions.** Older and widely mirrored by third parties, but
  OpenAI offers its newer models on the Responses API first, some only there,
  and system instructions would have to travel as a pseudo-message.
- **Label it "ChatGPT".** More recognizable, but invites users to expect
  their ChatGPT subscription to work, and it doesn't.
- **Omit `reasoning` entirely and raise the budget further.** Robust to every
  model, but slower and costlier answers on exactly the models most users
  will pick.
