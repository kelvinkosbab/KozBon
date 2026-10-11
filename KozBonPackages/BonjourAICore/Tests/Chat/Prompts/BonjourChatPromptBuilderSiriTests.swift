//
//  BonjourChatPromptBuilderSiriTests.swift
//  BonjourAICore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourAICore

// MARK: - BonjourChatPromptBuilderSiriTests

@Suite("BonjourChatPromptBuilder · Siri")
struct BonjourChatPromptBuilderSiriTests {

    @Test("The Siri block is empty for unrelated questions")
    func emptyForUnrelatedQuery() {
        #expect(BonjourChatPromptBuilder.siriBlock(query: "What is Matter?").isEmpty)
    }

    @Test("The Siri block lists the real phrases")
    func listsRealPhrases() {
        let block = BonjourChatPromptBuilder.siriBlock(query: "How do I use Siri with KozBon?")
        #expect(block.contains("Scan my network with KozBon"))
        #expect(block.contains("Find printers with KozBon"))
        #expect(block.contains("Stop broadcasting with KozBon"))
    }

    @Test("A Siri question gets a <siri> block in the user turn")
    @MainActor
    func userTurnIncludesSiriBlock() {
        let turn = BonjourChatPromptBuilder.userTurn(
            message: "How do I use Siri and Shortcuts with KozBon?",
            context: BonjourChatPromptBuilder.ChatContext(),
            isFirstTurn: false,
            contextChanged: false
        )
        #expect(turn.contains("<siri>"))
    }

    @Test("A network question gets no <siri> block")
    @MainActor
    func userTurnOmitsSiriBlock() {
        let turn = BonjourChatPromptBuilder.userTurn(
            message: "What's on my network?",
            context: BonjourChatPromptBuilder.ChatContext(),
            isFirstTurn: false,
            contextChanged: false
        )
        #expect(!turn.contains("<siri>"))
    }
}
