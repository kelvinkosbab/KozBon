//
//  PromptReadabilityTests.swift
//  BonjourAICore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourAICore

// MARK: - PromptReadabilityTests

/// Pin the readability directive into every system prompt so responses
/// from any backend stay scannable instead of arriving as dense
/// paragraphs.
@Suite("Prompt Readability")
@MainActor
struct PromptReadabilityTests {

    @Test("Readability directive caps paragraph length and asks for lists")
    func directiveCapsParagraphsAndAsksForLists() {
        let directive = BonjourServicePromptBuilder.readabilityDirective
        #expect(directive.contains("1-3 short sentences"))
        #expect(directive.contains("bulleted list"))
        #expect(directive.contains("numbered list"))
    }

    @Test("Readability directive forbids nested lists the renderer can't display")
    func directiveForbidsNestedLists() {
        #expect(BonjourServicePromptBuilder.readabilityDirective.contains("never indent or nest"))
    }

    @Test("Every system prompt embeds the readability directive")
    func systemPromptsEmbedDirective() {
        let directive = BonjourServicePromptBuilder.readabilityDirective
        #expect(BonjourServicePromptBuilder.systemInstructions.contains(directive))
        #expect(BonjourServicePromptBuilder.serviceTypeSystemInstructions.contains(directive))
        #expect(BonjourChatPromptBuilder.systemInstructions().contains(directive))
    }

    @Test("`.thorough` adds depth through bullets, not longer paragraphs")
    func thoroughDoesNotRequestLongParagraphs() {
        let directive = BonjourServicePromptBuilder.responseLengthDirective(.thorough)
        #expect(!directive.contains("4-6 sentences"))
        #expect(directive.contains("never by making a paragraph longer"))
    }

    @Test("Chat instructions route how-to questions to numbered steps")
    func chatRoutesHowToQuestionsToSteps() {
        let instructions = BonjourChatPromptBuilder.systemInstructions()
        #expect(instructions.contains("walks through steps"))
        #expect(instructions.contains("Never send one long block of text."))
    }
}
