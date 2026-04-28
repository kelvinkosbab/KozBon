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

    @Test("System instructions scope the assistant to Bonjour and the KozBon app")
    func systemInstructionsContainsScope() {
        let instructions = BonjourChatPromptBuilder.systemInstructions()
        #expect(instructions.contains("Bonjour"))
        #expect(instructions.contains("KozBon"))
    }

    @Test("System instructions enumerate forbidden topics and ship a refusal template")
    func systemInstructionsRefusesOffTopic() {
        let instructions = BonjourChatPromptBuilder.systemInstructions()
        #expect(instructions.contains("CANNOT answer"))
        #expect(instructions.contains("Refusal template"))
    }

    @Test("System instructions name the user's preferred language explicitly")
    func systemInstructionsIncludesLanguageDirective() {
        let instructions = BonjourChatPromptBuilder.systemInstructions()
        let language = BonjourServicePromptBuilder.preferredLanguageName
        #expect(instructions.contains("Respond in \(language)"))
    }

    @Test("System instructions reference the app's three primary tabs by name for navigation help")
    func systemInstructionsMentionsTabs() {
        let instructions = BonjourChatPromptBuilder.systemInstructions()
        #expect(instructions.contains("Discover"))
        #expect(instructions.contains("Library"))
        #expect(instructions.contains("Preferences"))
    }

    @Test("Language directive is the first line so it survives mid-prompt context truncation")
    func systemInstructionsStartsWithLanguageDirective() {
        let instructions = BonjourChatPromptBuilder.systemInstructions()
        #expect(instructions.hasPrefix("TOP PRIORITY: Respond in"))
    }

    @Test("System instructions tell the model to use prior turns when answering follow-ups")
    func systemInstructionsMentionsMultiTurn() {
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

    @Test("System instructions require quoting the user's actual service names verbatim")
    func systemInstructionsRequireCitingServicesByName() {
        // Without this, the chat model answers abstractly ("AirPlay lets
        // you stream...") instead of grounding the answer in the user's
        // actual network ("Your 'Living Room Apple TV' is..."). Citing
        // names demonstrates the model has read the context block and
        // lets the user verify the answer matches their setup.
        let instructions = BonjourChatPromptBuilder.systemInstructions()
        #expect(instructions.contains("quote the specific service name or hostname verbatim"))
    }

    @Test("System instructions ship standardized hedge prefixes (`Likely:`, `This typically means:`)")
    func systemInstructionsHasUncertaintyPhrasing() {
        // Standardized hedge prefixes let the model express doubt
        // consistently instead of confabulating with confident language.
        let instructions = BonjourChatPromptBuilder.systemInstructions()
        #expect(instructions.contains("\"Likely:\""))
        #expect(instructions.contains("\"This typically means:\""))
    }

    @Test("System instructions tell the model to ask one clarifying question on ambiguous input")
    func systemInstructionsAsksForClarificationWhenAmbiguous() {
        // When the user's question could apply to several services, the
        // model should ask rather than guess. This materially improves
        // multi-turn chat quality — guesses force the user to correct,
        // clarifying questions get the answer right the first time.
        let instructions = BonjourChatPromptBuilder.systemInstructions()
        #expect(instructions.contains("ambiguous"))
        #expect(instructions.contains("ask one brief clarifying question"))
    }

    @Test("System instructions forbid conversational preamble so streaming feels responsive")
    func systemInstructionsForbidPreamble() {
        // Tokens stream visibly; conversational preambles make streaming
        // feel sluggish before useful content arrives.
        let instructions = BonjourChatPromptBuilder.systemInstructions()
        #expect(instructions.contains("Do not emit"))
        #expect(instructions.contains("preamble"))
    }

    @Test("System instructions pin second-person voice (`you`) for warmer, consistent tone")
    func systemInstructionsDirectSecondPersonVoice() {
        // "you" reads warmer than "the user". The explicit rule keeps
        // voice consistent across turns even when responses vary in
        // length or topic.
        let instructions = BonjourChatPromptBuilder.systemInstructions()
        #expect(instructions.contains("Address the user as \"you\""))
    }

    @Test("Refusal template is the decisive one-sentence form, not the old apologetic two-sentence one")
    func systemInstructionsRefusalTemplateIsOneSentence() {
        // The old refusal was two sentences ending in a question. The
        // new one-sentence refusal still pivots to relevant topics but
        // reads decisively, not apologetically.
        let instructions = BonjourChatPromptBuilder.systemInstructions()
        #expect(instructions.contains("That's outside what I can help with"))
    }

    // MARK: - Tools

    @Test("System instructions advertise the `prepareCustomServiceType` tool by name")
    func systemInstructionsAdvertiseCreateTool() {
        // The tool name MUST appear in the prompt so the model knows
        // when it's allowed to call it. Without this advertisement
        // the model would refuse to draft service types even when
        // the user explicitly asked.
        let instructions = BonjourChatPromptBuilder.systemInstructions()
        #expect(instructions.contains("prepareCustomServiceType"))
    }

    @Test("System instructions advertise the `prepareBroadcast` tool by name")
    func systemInstructionsAdvertiseBroadcastTool() {
        let instructions = BonjourChatPromptBuilder.systemInstructions()
        #expect(instructions.contains("prepareBroadcast"))
    }

    @Test("Tool guidance tells the model the user must confirm via the form before anything is saved")
    func systemInstructionsRequireUserConfirmation() {
        // Critical safety property: the assistant must NOT claim the
        // service type was created or that the broadcast started.
        // Both are user-confirm-only flows; the tool merely opens
        // the sheet. If this rule disappears, the assistant's reply
        // will overstate what just happened and the user will think
        // their service is published when in fact the form is just
        // sitting open waiting for them.
        let instructions = BonjourChatPromptBuilder.systemInstructions()
        #expect(instructions.contains("Never claim something"))
    }

    @Test("Tool guidance tells the model to chain `prepareCustomServiceType` before broadcasting an unknown type")
    func systemInstructionsChainCreateBeforeBroadcast() {
        // If the user asks to broadcast something that isn't in the
        // library yet, the assistant should offer to create the type
        // first. Without this rule the broadcast tool's missing-type
        // error gets surfaced to the user as a dead end, when the
        // app could have helped them create the type and then offered
        // to broadcast it.
        let instructions = BonjourChatPromptBuilder.systemInstructions()
        #expect(instructions.contains("FIRST"))
        // The exact phrasing wraps the tool name in markdown bold
        // (`**prepareCustomServiceType FIRST**`), so we test the
        // pieces independently rather than the literal substring.
        #expect(instructions.contains("prepareCustomServiceType"))
        #expect(instructions.contains("doesn't exist"))
    }

    @Test("Tool guidance tells the model not to call tools speculatively")
    func systemInstructionsForbidSpeculativeToolCalls() {
        // The model should only fire tools when the user has actually
        // asked for the action. A speculative tool call would pop a
        // sheet open mid-conversation when the user was just asking
        // a question — disorienting at best, destructive at worst.
        let instructions = BonjourChatPromptBuilder.systemInstructions()
        #expect(instructions.contains("speculatively"))
        #expect(instructions.contains("only when the user has asked"))
    }

    // MARK: - Edit / Delete / Stop Tools

    @Test("System instructions advertise the `prepareEditCustomServiceType` tool")
    func systemInstructionsAdvertiseEditTool() {
        let instructions = BonjourChatPromptBuilder.systemInstructions()
        #expect(instructions.contains("prepareEditCustomServiceType"))
    }

    @Test("System instructions advertise the `prepareDeleteCustomServiceType` tool")
    func systemInstructionsAdvertiseDeleteTool() {
        let instructions = BonjourChatPromptBuilder.systemInstructions()
        #expect(instructions.contains("prepareDeleteCustomServiceType"))
    }

    @Test("System instructions advertise the `prepareStopBroadcast` tool")
    func systemInstructionsAdvertiseStopBroadcastTool() {
        let instructions = BonjourChatPromptBuilder.systemInstructions()
        #expect(instructions.contains("prepareStopBroadcast"))
    }

    @Test("Tool guidance flags edit/delete as restricted to user-created (non-built-in) types")
    func systemInstructionsScopeEditAndDeleteToCustomTypes() {
        // Built-in types live in the bundled library and have no Core
        // Data record. Letting the assistant try to edit or delete
        // them would surface forms that don't actually do anything.
        // The guidance has to call this out so the model relays the
        // restriction instead of acting confused on the user's behalf.
        let instructions = BonjourChatPromptBuilder.systemInstructions()
        #expect(instructions.contains("Refuses for built-in types"))
    }

    // MARK: - Tool Chaining

    @Test("System instructions name the create-then-broadcast chain with the wait-for-confirmation rule")
    func systemInstructionsNameCreateThenBroadcastChain() {
        // The chain is what makes "create a foo type and broadcast
        // it" work as a multi-turn flow. The rule is that the model
        // calls the second tool only AFTER the user confirms the
        // first form — otherwise the second tool's library check
        // would fail because the new type isn't in the library yet.
        let instructions = BonjourChatPromptBuilder.systemInstructions()
        #expect(instructions.contains("Create then broadcast"))
        #expect(instructions.contains("wait for the user to confirm"))
    }

    @Test("System instructions name the stop-then-delete chain for cleanly removing an active broadcast's type")
    func systemInstructionsNameStopThenDeleteChain() {
        // If the user wants to delete a type they're currently
        // broadcasting, the broadcast has to stop first. The chain
        // guidance lets the model offer that as a two-step flow
        // rather than refusing or producing a half-baked result.
        let instructions = BonjourChatPromptBuilder.systemInstructions()
        #expect(instructions.contains("Stop then delete"))
    }

    @Test("Tool guidance has a dedicated error-handling rule telling the model to relay tool-error reasons")
    func systemInstructionsHaveErrorHandlingGuidance() {
        // Each tool returns a self-explanatory "Couldn't draft…"
        // string when validation fails. The rule keeps the model
        // from quietly retrying with the same arguments.
        let instructions = BonjourChatPromptBuilder.systemInstructions()
        #expect(instructions.contains("Couldn't draft"))
        #expect(instructions.contains("relay the reason to the user"))
    }
}
