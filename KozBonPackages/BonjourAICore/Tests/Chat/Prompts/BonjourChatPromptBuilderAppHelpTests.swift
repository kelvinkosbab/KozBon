//
//  BonjourChatPromptBuilderAppHelpTests.swift
//  BonjourAICore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourAICore

// MARK: - BonjourChatPromptBuilderAppHelpTests

@Suite("BonjourChatPromptBuilder · App Help")
@MainActor
struct BonjourChatPromptBuilderAppHelpTests {

    @Test("The app-help block is empty for unrelated questions")
    func emptyForUnrelatedQuestion() {
        #expect(BonjourChatPromptBuilder.appHelpBlock(query: "What is Matter?").isEmpty)
    }

    @Test("The app-help block gives the real broadcast steps")
    func listsBroadcastSteps() {
        let block = BonjourChatPromptBuilder.appHelpBlock(query: "How do I broadcast my own service?")
        #expect(block.contains("in Discover, tap Broadcast"))
        #expect(block.contains("TCP services only"))
        #expect(block.contains("never invent buttons"))
    }

    @Test("A broadcast question gets an <app_help> block in the user turn")
    func userTurnIncludesAppHelp() {
        let turn = BonjourChatPromptBuilder.userTurn(
            message: "How do I broadcast my own service?",
            context: BonjourChatPromptBuilder.ChatContext(),
            isFirstTurn: false,
            contextChanged: false
        )
        #expect(turn.contains("<app_help>"))
        #expect(turn.hasSuffix("How do I broadcast my own service?"))
    }

    @Test("A network question gets no <app_help> block")
    func userTurnOmitsAppHelpForNetworkQuestion() {
        let turn = BonjourChatPromptBuilder.userTurn(
            message: "What services are on my network?",
            context: BonjourChatPromptBuilder.ChatContext(),
            isFirstTurn: false,
            contextChanged: false
        )
        #expect(!turn.contains("<app_help>"))
    }
}
