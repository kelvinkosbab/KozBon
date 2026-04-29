//
//  BonjourSiriPromptBuilder.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourCore
import BonjourModels

// MARK: - BonjourSiriPromptBuilder

/// Builds the system instructions and user-turn payload for the
/// Siri ``AskKozBonIntent``.
///
/// The Siri surface differs from the in-app chat in three ways
/// that justify a separate prompt builder:
///
/// 1. **Voice output** — the response is read aloud, so Markdown
///    formatting (`**bold**`, code spans, lists) is jarring.
///    Prose only.
///
/// 2. **Single turn** — Siri intents are one-shot. There's no
///    conversation history to carry across calls, so guidance
///    about referencing prior turns is irrelevant and removing it
///    saves tokens.
///
/// 3. **No tool calls** — Siri can't open sheets or confirmation
///    dialogs from inside the intent's response, so the chat's
///    tool-orchestration guidance would mislead the model into
///    promising actions it can't actually perform.
///
/// Phase 1 of the Siri integration intentionally answers without
/// access to the live discovered-services list — the intent runs
/// in a transient process that doesn't share scanner state with
/// the app. The prompt is honest about that boundary so the model
/// redirects users to the Discover tab when they ask about
/// specific devices on their network.
public enum BonjourSiriPromptBuilder {

    // MARK: - System Instructions

    /// Builds the static system prompt for the Siri Q&A intent.
    ///
    /// The prompt scopes the assistant to Bonjour and KozBon,
    /// requires concise voice-friendly output, and tells the model
    /// to redirect questions about specific devices to the
    /// Discover tab (since this surface has no live network
    /// state to consult).
    @MainActor
    public static func systemInstructions() -> String {
        let language = BonjourServicePromptBuilder.preferredLanguageName
        return """
            TOP PRIORITY: Respond in \(language).

            You are KozBon's Siri assistant. You answer brief voice questions \
            about Bonjour (mDNS/DNS-SD) network services and the KozBon app. \
            Your reply will be read aloud, so format matters.

            ## Scope
            You CAN answer questions about:
            - What Bonjour and DNS-SD are
            - What a specific service type does (e.g. \"What is _ipp._tcp?\")
            - How to use KozBon (Discover tab, Library tab, broadcasting, \
            filters)
            - The service type library (the protocols KozBon recognizes)

            You CANNOT answer:
            - Whether a specific device is on the user's network right now — \
            this surface has no access to live scanner state. If asked, tell \
            the user to open KozBon's Discover tab.
            - Anything unrelated to Bonjour or this app (weather, general \
            knowledge, news, code, etc.)

            ## Refusal template
            For off-topic questions, reply with one short sentence:
            \"That's outside what I can help with — ask me about Bonjour or \
            KozBon.\"

            For live-network questions, reply with one short sentence:
            \"Open KozBon's Discover tab to see what's on your network — I \
            can't see live results from here.\"

            ## Voice output rules
            - Plain prose only. Do NOT use Markdown: no asterisks, backticks, \
            underscores, hyphens for lists, or numbered lists.
            - Spell out service types as words rather than reading the wire \
            form. \"_airplay._tcp\" should read as \"AirPlay over TCP\" or \
            simply \"AirPlay\".
            - Two to three sentences for most answers. The user is listening, \
            not reading — long answers are tiring and easy to lose track of.
            - Address the user as \"you\". Use second person, active voice.
            - Start with the answer. No conversational preamble (\"Sure,\", \
            \"Great question,\"). Siri reads the first words first.

            ## Honesty
            - Never invent port numbers, protocol versions, or device names. \
            If you don't know, say so plainly.
            - When inferring something not directly stated, prefix with \
            \"Likely:\" so the user knows it's a guess.
            """
    }

    // MARK: - User Turn

    /// Builds the user-turn string sent to the language model for a
    /// single Siri question.
    ///
    /// The turn includes a `<library>` block with the service type
    /// catalog (built-in + custom) so the model can answer
    /// type-specific questions without having to remember the
    /// taxonomy. Discovered/published services are deliberately
    /// omitted — see the type's documentation for why.
    @MainActor
    public static func userTurn(
        question: String,
        library: [BonjourServiceType] = []
    ) -> String {
        let trimmedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        var sections: [String] = []
        if !library.isEmpty {
            sections.append(libraryBlock(library: library))
            sections.append("")
        }
        sections.append("User question: \(trimmedQuestion)")
        return sections.joined(separator: "\n")
    }

    // MARK: - Library Block

    /// Renders the service-type library as a compact `<library>` block
    /// for a single Siri turn. Names only — full descriptions would
    /// blow the context budget without changing the kind of question
    /// the model can answer.
    private static func libraryBlock(library: [BonjourServiceType]) -> String {
        let lines: [String] = library
            .prefix(siriLibraryCap)
            .map { "- \($0.name) (\($0.fullType))" }
        let header = "<library>\nKozBon recognizes \(library.count) Bonjour service types:"
        let trailer = library.count > siriLibraryCap
            ? "(...and \(library.count - siriLibraryCap) more)\n</library>"
            : "</library>"
        return ([header] + lines + [trailer]).joined(separator: "\n")
    }

    /// Maximum number of library entries rendered into the user turn.
    /// Higher than the chat builder's library section because we don't
    /// also send a discovered-services block alongside it.
    private static let siriLibraryCap = 60
}
