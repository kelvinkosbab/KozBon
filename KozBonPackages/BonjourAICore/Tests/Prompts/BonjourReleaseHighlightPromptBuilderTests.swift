//
//  BonjourReleaseHighlightPromptBuilderTests.swift
//  BonjourAICore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourAICore

// MARK: - BonjourReleaseHighlightPromptBuilderTests

/// Pins the release-highlight Insights prompt surface (the
/// Preferences → What's New long-press "what this means for you"
/// flow). Verifies the prompt grounds the model in the verbatim
/// highlight + version and that the system instructions steer
/// toward short, user-impact-focused, anti-hallucination output.
@Suite("BonjourServicePromptBuilder · Release Highlight")
@MainActor
struct BonjourReleaseHighlightPromptBuilderTests {

    // MARK: - Prompt

    @Test("Prompt embeds the verbatim highlight text")
    func promptContainsHighlight() {
        let highlight = "Chat tab now shows a red badge for unread replies."
        let prompt = BonjourServicePromptBuilder.buildPrompt(
            releaseHighlight: highlight,
            version: "4.6"
        )
        #expect(prompt.contains(highlight))
    }

    @Test("Prompt names the version so the model can ground its answer")
    func promptContainsVersion() {
        let prompt = BonjourServicePromptBuilder.buildPrompt(
            releaseHighlight: "Some change.",
            version: "4.6"
        )
        #expect(prompt.contains("4.6"))
    }

    @Test("Prompt asks for user impact, not protocol mechanics")
    func promptAsksForUserImpact() {
        let prompt = BonjourServicePromptBuilder.buildPrompt(
            releaseHighlight: "Some change.",
            version: "4.6"
        ).lowercased()
        #expect(prompt.contains("affects me") || prompt.contains("using the app"))
    }

    @Test("Prompt carries the expertise + length directives")
    func promptCarriesDirectives() {
        let prompt = BonjourServicePromptBuilder.buildPrompt(
            releaseHighlight: "Some change.",
            version: "4.6",
            expertiseLevel: .technical,
            responseLength: .brief
        )
        // The technical tone directive and the brief length
        // directive both have recognizable fragments.
        #expect(prompt.contains("TONE:"))
        #expect(prompt.contains("LENGTH:"))
    }

    // MARK: - System Instructions

    @Test("System instructions forbid inventing changes")
    func systemInstructionsForbidInvention() {
        let instructions = BonjourServicePromptBuilder.releaseHighlightSystemInstructions.lowercased()
        #expect(instructions.contains("do not invent") || instructions.contains("only the change"))
    }

    @Test("System instructions request a short, heading-free reply")
    func systemInstructionsRequestShortReply() {
        let instructions = BonjourServicePromptBuilder.releaseHighlightSystemInstructions
        #expect(instructions.contains("ONE short paragraph"))
        #expect(instructions.lowercased().contains("do not use markdown headings"))
    }

    @Test("System instructions pin the response language")
    func systemInstructionsPinLanguage() {
        let instructions = BonjourServicePromptBuilder.releaseHighlightSystemInstructions
        #expect(instructions.contains("TOP PRIORITY: Respond in"))
    }
}
