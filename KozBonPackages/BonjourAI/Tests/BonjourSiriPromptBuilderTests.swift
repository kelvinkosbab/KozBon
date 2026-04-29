//
//  BonjourSiriPromptBuilderTests.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourAI
import BonjourCore
import BonjourModels

// MARK: - BonjourSiriPromptBuilderTests

/// Pin the Siri-specific prompt's voice-friendly properties. The
/// in-app chat prompt has its own suite — these tests target the
/// places where the Siri surface MUST diverge: prose-only output,
/// no tool guidance, and the explicit redirect for questions about
/// live network state.
@Suite("BonjourSiriPromptBuilder")
@MainActor
struct BonjourSiriPromptBuilderTests {

    // MARK: - Scope

    @Test("System instructions scope the assistant to Bonjour and KozBon")
    func instructionsContainScope() {
        let instructions = BonjourSiriPromptBuilder.systemInstructions()
        #expect(instructions.contains("Bonjour"))
        #expect(instructions.contains("KozBon"))
    }

    @Test("System instructions name the user's preferred language explicitly")
    func instructionsIncludeLanguageDirective() {
        let instructions = BonjourSiriPromptBuilder.systemInstructions()
        let language = BonjourServicePromptBuilder.preferredLanguageName
        #expect(instructions.contains("Respond in \(language)"))
    }

    @Test("Language directive is the first line so it survives mid-prompt context truncation")
    func instructionsStartWithLanguageDirective() {
        let instructions = BonjourSiriPromptBuilder.systemInstructions()
        #expect(instructions.hasPrefix("TOP PRIORITY: Respond in"))
    }

    // MARK: - Voice Formatting Rules

    @Test("System instructions explicitly forbid Markdown — Siri reads the response aloud")
    func instructionsForbidMarkdown() {
        // Asterisks, backticks, underscores, and hyphen-lists all
        // render terribly through voice synthesis. The chat surface
        // uses Markdown freely; the Siri surface must not.
        let instructions = BonjourSiriPromptBuilder.systemInstructions()
        #expect(instructions.contains("Plain prose only"))
        #expect(instructions.contains("Markdown"))
    }

    @Test("System instructions cap response length at two to three sentences")
    func instructionsRequireBriefResponses() {
        // Voice answers grow tedious past 3 sentences. The chat
        // surface allows longer answers because the user reads them.
        let instructions = BonjourSiriPromptBuilder.systemInstructions()
        #expect(instructions.contains("Two to three sentences"))
    }

    @Test("System instructions tell the model to spell out wire types as readable words")
    func instructionsSpellOutWireTypes() {
        // \"_airplay._tcp\" read aloud sounds wrong. The model
        // should say \"AirPlay over TCP\" or \"AirPlay\" — pin
        // the rule so a future prompt edit doesn't strip it.
        let instructions = BonjourSiriPromptBuilder.systemInstructions()
        #expect(instructions.contains("Spell out service types"))
    }

    @Test("System instructions forbid conversational preamble so the answer starts fast")
    func instructionsForbidPreamble() {
        let instructions = BonjourSiriPromptBuilder.systemInstructions()
        #expect(instructions.contains("No conversational preamble"))
    }

    // MARK: - Live-State Redirect

    @Test("System instructions redirect live-network questions to the Discover tab")
    func instructionsRedirectLiveQuestionsToDiscover() {
        // Phase 1 has no scanner state — the prompt must be honest
        // about that and tell the user where to look. Without this
        // rule the model would invent a "yes" or "no" answer about
        // devices it can't actually see.
        let instructions = BonjourSiriPromptBuilder.systemInstructions()
        #expect(instructions.contains("Open KozBon's Discover tab"))
        #expect(instructions.contains("can't see live results"))
    }

    @Test("System instructions decline to answer questions about specific devices on the network")
    func instructionsDeclineLiveDeviceQuestions() {
        let instructions = BonjourSiriPromptBuilder.systemInstructions()
        #expect(instructions.contains("CANNOT answer"))
        #expect(instructions.contains("specific device"))
    }

    // MARK: - Off-Topic Refusal

    @Test("System instructions ship a one-sentence refusal template for off-topic questions")
    func instructionsHaveRefusalTemplate() {
        let instructions = BonjourSiriPromptBuilder.systemInstructions()
        #expect(instructions.contains("Refusal template"))
        #expect(instructions.contains("That's outside what I can help with"))
    }

    @Test("Off-topic refusal mentions Bonjour AND KozBon so the redirect points somewhere useful")
    func refusalRedirectsToBothScopes() {
        let instructions = BonjourSiriPromptBuilder.systemInstructions()
        #expect(instructions.contains("ask me about Bonjour or"))
    }

    // MARK: - Single-Turn Awareness

    @Test("Siri prompt does NOT reference previous turns — the surface is one-shot")
    func instructionsDoNotMentionMultiTurn() {
        // The chat prompt tells the model "Remember previous turns".
        // The Siri prompt must not, because the intent runs as a
        // fresh `LanguageModelSession` per invocation. Mentioning
        // multi-turn would make the model promise continuity it
        // can't deliver.
        let instructions = BonjourSiriPromptBuilder.systemInstructions()
        #expect(!instructions.contains("previous turns"))
        #expect(!instructions.contains("follow-up"))
    }

    @Test("Siri prompt does NOT advertise tools — there's no UI to surface a confirmation form")
    func instructionsDoNotAdvertiseTools() {
        // The chat prompt advertises 5 tools. Siri can't open
        // sheets or dialogs from inside the intent's reply, so
        // tool guidance would mislead the model into promising
        // actions it can't perform.
        let instructions = BonjourSiriPromptBuilder.systemInstructions()
        #expect(!instructions.contains("prepareCustomServiceType"))
        #expect(!instructions.contains("prepareBroadcast"))
        #expect(!instructions.contains("prepareStopBroadcast"))
        #expect(!instructions.contains("Tool chaining"))
    }

    // MARK: - Honesty Rules

    @Test("System instructions retain the no-fabrication rule from the chat surface")
    func instructionsRequireHonesty() {
        // Voice surface or not, the model must not invent port
        // numbers, protocol versions, or device names. The chat
        // builder pins the same rule; mirroring it here makes
        // sure the Siri experience doesn't degrade in honesty.
        let instructions = BonjourSiriPromptBuilder.systemInstructions()
        #expect(instructions.contains("Never invent"))
    }

    @Test("System instructions standardize the `Likely:` hedge prefix for inferred content")
    func instructionsStandardizeHedgePrefix() {
        let instructions = BonjourSiriPromptBuilder.systemInstructions()
        #expect(instructions.contains("\"Likely:\""))
    }

    // MARK: - User Turn

    @Test("User turn includes the question verbatim so the model has the literal ask")
    func userTurnIncludesQuestion() {
        let turn = BonjourSiriPromptBuilder.userTurn(
            question: "What is _ipp._tcp?",
            library: []
        )
        #expect(turn.contains("What is _ipp._tcp?"))
    }

    @Test("User turn trims surrounding whitespace from the question before embedding")
    func userTurnTrimsWhitespace() {
        let turn = BonjourSiriPromptBuilder.userTurn(
            question: "   Hello   \n",
            library: []
        )
        #expect(turn.contains("User question: Hello"))
        #expect(!turn.contains("   Hello"))
    }

    @Test("User turn renders an empty `<library>` block as no library section at all")
    func emptyLibraryProducesNoLibraryBlock() {
        let turn = BonjourSiriPromptBuilder.userTurn(
            question: "What is _ipp._tcp?",
            library: []
        )
        #expect(!turn.contains("<library>"))
        #expect(!turn.contains("</library>"))
    }

    @Test("User turn wraps non-empty library data in `<library>`/`</library>` tags for parsing clarity")
    func libraryWrappedInTags() {
        let library = [
            BonjourServiceType(name: "Web", type: "http", transportLayer: .tcp)
        ]
        let turn = BonjourSiriPromptBuilder.userTurn(question: "?", library: library)
        #expect(turn.contains("<library>"))
        #expect(turn.contains("</library>"))
    }

    @Test("User turn lists every library entry by name and full type for cross-reference")
    func libraryListsNameAndFullType() {
        let library = [
            BonjourServiceType(name: "Web Server", type: "http", transportLayer: .tcp),
            BonjourServiceType(name: "Secure Shell", type: "ssh", transportLayer: .tcp)
        ]
        let turn = BonjourSiriPromptBuilder.userTurn(question: "?", library: library)
        #expect(turn.contains("Web Server"))
        #expect(turn.contains("_http._tcp"))
        #expect(turn.contains("Secure Shell"))
        #expect(turn.contains("_ssh._tcp"))
    }

    @Test("User turn caps library at 60 entries plus a `(...and N more)` overflow line")
    func libraryCapsAtSixty() {
        let library = (0..<100).map { index in
            BonjourServiceType(name: "Type\(index)", type: "type\(index)", transportLayer: .tcp)
        }
        let turn = BonjourSiriPromptBuilder.userTurn(question: "?", library: library)
        // The library count line should mention 100, not 60 —
        // honesty about the actual taxonomy size matters.
        #expect(turn.contains("100"))
        #expect(turn.contains("(...and 40 more)"))
    }

    @Test("User turn header reports the actual library size — not the rendered subset")
    func libraryHeaderReportsActualSize() {
        let library = (0..<5).map { index in
            BonjourServiceType(name: "T\(index)", type: "t\(index)", transportLayer: .tcp)
        }
        let turn = BonjourSiriPromptBuilder.userTurn(question: "?", library: library)
        #expect(turn.contains("recognizes 5 Bonjour service types"))
    }
}
