//
//  BonjourChatPromptBuilderTests.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourAI
import BonjourCore
import BonjourModels

// MARK: - BonjourChatPromptBuilderTests

/// Pin the chat assistant's system instructions: scope, refusal,
/// language, multi-turn awareness, and the prompt-quality guardrails
/// introduced in the audit.
///
/// Context-block rendering tests live in
/// `BonjourChatPromptBuilderContextTests`. User-turn composition and
/// queried-descriptions tests live in
/// `BonjourChatPromptBuilderUserTurnTests`. The split keeps each suite
/// well under SwiftLint's `type_body_length` and `file_length`
/// thresholds so neither needs an inline disable.
@Suite("BonjourChatPromptBuilder")
@MainActor
struct BonjourChatPromptBuilderTests {

    // MARK: - System Instructions

    @Test func systemInstructionsContainsScope() {
        let instructions = BonjourChatPromptBuilder.systemInstructions()
        #expect(instructions.contains("Bonjour"))
        #expect(instructions.contains("KozBon"))
    }

    @Test func systemInstructionsRefusesOffTopic() {
        let instructions = BonjourChatPromptBuilder.systemInstructions()
        #expect(instructions.contains("CANNOT answer"))
        #expect(instructions.contains("Refusal template"))
    }

    @Test func systemInstructionsIncludesLanguageDirective() {
        let instructions = BonjourChatPromptBuilder.systemInstructions()
        let language = BonjourServicePromptBuilder.preferredLanguageName
        #expect(instructions.contains("Respond in \(language)"))
    }

    @Test func systemInstructionsMentionsTabs() {
        let instructions = BonjourChatPromptBuilder.systemInstructions()
        #expect(instructions.contains("Discover"))
        #expect(instructions.contains("Library"))
        #expect(instructions.contains("Preferences"))
    }

    @Test func systemInstructionsStartsWithLanguageDirective() {
        let instructions = BonjourChatPromptBuilder.systemInstructions()
        #expect(instructions.hasPrefix("TOP PRIORITY: Respond in"))
    }

    @Test func systemInstructionsMentionsMultiTurn() {
        let instructions = BonjourChatPromptBuilder.systemInstructions()
        #expect(instructions.contains("previous turns"))
        #expect(instructions.contains("follow-up"))
    }

    // MARK: - Prompt Quality Invariants
    //
    // Pin the chat-specific rules introduced in the prompt audit. Each
    // test asserts one behavior the user would feel regress if the rule
    // were removed, so failures point at a specific deleted guardrail
    // rather than "the prompt string changed".

    @Test func systemInstructionsRequireCitingServicesByName() {
        // Without this, the chat model answers abstractly ("AirPlay lets
        // you stream...") instead of grounding the answer in the user's
        // actual network ("Your 'Living Room Apple TV' is..."). Citing
        // names demonstrates the model has read the context block and
        // lets the user verify the answer matches their setup.
        let instructions = BonjourChatPromptBuilder.systemInstructions()
        #expect(instructions.contains("quote the specific service name or hostname verbatim"))
    }

    @Test func systemInstructionsHasUncertaintyPhrasing() {
        // Standardized hedge prefixes let the model express doubt
        // consistently instead of confabulating with confident language.
        let instructions = BonjourChatPromptBuilder.systemInstructions()
        #expect(instructions.contains("\"Likely:\""))
        #expect(instructions.contains("\"This typically means:\""))
    }

    @Test func systemInstructionsAsksForClarificationWhenAmbiguous() {
        // When the user's question could apply to several services, the
        // model should ask rather than guess. This materially improves
        // multi-turn chat quality — guesses force the user to correct,
        // clarifying questions get the answer right the first time.
        let instructions = BonjourChatPromptBuilder.systemInstructions()
        #expect(instructions.contains("ambiguous"))
        #expect(instructions.contains("ask one brief clarifying question"))
    }

    @Test func systemInstructionsForbidPreamble() {
        // Tokens stream visibly; conversational preambles make streaming
        // feel sluggish before useful content arrives.
        let instructions = BonjourChatPromptBuilder.systemInstructions()
        #expect(instructions.contains("Do not emit"))
        #expect(instructions.contains("preamble"))
    }

    @Test func systemInstructionsDirectSecondPersonVoice() {
        // "you" reads warmer than "the user". The explicit rule keeps
        // voice consistent across turns even when responses vary in
        // length or topic.
        let instructions = BonjourChatPromptBuilder.systemInstructions()
        #expect(instructions.contains("Address the user as \"you\""))
    }

    @Test func systemInstructionsRefusalTemplateIsOneSentence() {
        // The old refusal was two sentences ending in a question. The
        // new one-sentence refusal still pivots to relevant topics but
        // reads decisively, not apologetically.
        let instructions = BonjourChatPromptBuilder.systemInstructions()
        #expect(instructions.contains("That's outside what I can help with"))
    }
}
