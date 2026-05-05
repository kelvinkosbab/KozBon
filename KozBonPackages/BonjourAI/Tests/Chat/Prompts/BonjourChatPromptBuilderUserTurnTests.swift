//
//  BonjourChatPromptBuilderUserTurnTests.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourAI
import BonjourCore
import BonjourModels

// MARK: - BonjourChatPromptBuilderUserTurnTests

/// Pin user-turn composition: when context blocks attach, ChatContext
/// defaults, the queried-descriptions block, and how it integrates into
/// `userTurn`. Split from the main suite so each file stays under
/// SwiftLint's `type_body_length` / `file_length` thresholds without
/// disabling them.
@Suite("BonjourChatPromptBuilder · User Turn")
@MainActor
struct BonjourChatPromptBuilderUserTurnTests {

    // MARK: - Helpers

    private func makeService(name: String = "Test", type: String = "http") -> BonjourService {
        let serviceType = BonjourServiceType(name: type.uppercased(), type: type, transportLayer: .tcp)
        return BonjourService(
            service: NetService(
                domain: "local.",
                type: serviceType.fullType,
                name: name,
                port: 8080
            ),
            serviceType: serviceType
        )
    }

    private func makeServiceType(name: String, type: String) -> BonjourServiceType {
        BonjourServiceType(name: name, type: type, transportLayer: .tcp)
    }

    // MARK: - User Turn Builder

    @Test("First turn always carries the `<context>` block so the model has the network state")
    func userTurnOnFirstTurnIncludesContext() {
        let services = [makeService(name: "Printer", type: "ipp")]
        let context = BonjourChatPromptBuilder.ChatContext(discoveredServices: services)
        let turn = BonjourChatPromptBuilder.userTurn(
            message: "What is this?",
            context: context,
            isFirstTurn: true,
            contextChanged: false
        )
        #expect(turn.contains("<context>"))
        #expect(turn.contains("Printer"))
        #expect(turn.contains("What is this?"))
    }

    @Test("Context-changed turns re-emit `<context>` so the model sees the refreshed state")
    func userTurnWhenContextChangedIncludesContext() {
        let services = [makeService(name: "AirPlay", type: "airplay")]
        let context = BonjourChatPromptBuilder.ChatContext(discoveredServices: services)
        let turn = BonjourChatPromptBuilder.userTurn(
            message: "What about the new one?",
            context: context,
            isFirstTurn: false,
            contextChanged: true
        )
        #expect(turn.contains("<context>"))
        #expect(turn.contains("AirPlay"))
    }

    @Test("Stable subsequent turns omit `<context>` to save tokens and the message goes through verbatim")
    func userTurnOnSubsequentStableContextOmitsContext() {
        let context = BonjourChatPromptBuilder.ChatContext()
        let turn = BonjourChatPromptBuilder.userTurn(
            message: "Tell me more",
            context: context,
            isFirstTurn: false,
            contextChanged: false
        )
        #expect(!turn.contains("<context>"))
        #expect(turn == "Tell me more")
    }

    // MARK: - ChatContext Defaults

    @Test("`ChatContext()` defaults all collections to empty so callers opt in to context")
    func chatContextDefaultsToEmpty() {
        let context = BonjourChatPromptBuilder.ChatContext()
        #expect(context.discoveredServices.isEmpty)
        #expect(context.publishedServices.isEmpty)
        #expect(context.serviceTypeLibrary.isEmpty)
    }

    // MARK: - Queried Descriptions Block

    @Test("Queried block is empty when the user's question does not name any library type")
    func queriedBlockEmptyWhenQueryMatchesNoType() {
        let library = [makeServiceType(name: "HTTP", type: "http")]
        let context = BonjourChatPromptBuilder.ChatContext(serviceTypeLibrary: library)
        let block = BonjourChatPromptBuilder.queriedDescriptionsBlock(
            context: context,
            query: "What's the weather today?"
        )
        #expect(block.isEmpty)
    }

    @Test("Queried block surfaces the matched type's localized detail so the model has authoritative copy")
    func queriedBlockIncludesMatchedTypeDescription() {
        let serviceType = BonjourServiceType(
            name: "AirPlay",
            type: "airplay",
            transportLayer: .tcp,
            detail: "Streams audio/video from Apple devices to compatible receivers."
        )
        let context = BonjourChatPromptBuilder.ChatContext(serviceTypeLibrary: [serviceType])
        let block = BonjourChatPromptBuilder.queriedDescriptionsBlock(
            context: context,
            query: "How does AirPlay work on my network?"
        )
        #expect(block.contains("AirPlay"))
        #expect(block.contains("Streams audio"))
    }

    @Test("Queried block matches type names case-insensitively so casual capitalization still matches")
    func queriedBlockIsCaseInsensitive() {
        let serviceType = BonjourServiceType(
            name: "HomeKit",
            type: "hap",
            transportLayer: .tcp,
            detail: "Apple's smart-home accessory protocol."
        )
        let context = BonjourChatPromptBuilder.ChatContext(serviceTypeLibrary: [serviceType])
        let block = BonjourChatPromptBuilder.queriedDescriptionsBlock(
            context: context,
            query: "Tell me about homekit setup"
        )
        #expect(block.contains("HomeKit"))
    }

    @Test("Queried block omits matched types that have no localized detail to avoid empty placeholder lines")
    func queriedBlockSkipsTypesWithoutDetail() {
        // If a matched type has no localized detail, there's nothing
        // to tell the model that it wouldn't already know — so it's
        // skipped rather than shipping an empty placeholder line.
        let typed = BonjourServiceType(name: "Ghost", type: "ghost", transportLayer: .tcp)
        let context = BonjourChatPromptBuilder.ChatContext(serviceTypeLibrary: [typed])
        let block = BonjourChatPromptBuilder.queriedDescriptionsBlock(
            context: context,
            query: "ghost service running"
        )
        #expect(block.isEmpty)
    }

    // MARK: - User Turn: Queried Descriptions Integration

    @Test("User turn embeds a `<referenced>` block when the query matches a known service type")
    func userTurnIncludesQueriedBlockWhenMatch() {
        let serviceType = BonjourServiceType(
            name: "SSH",
            type: "ssh",
            transportLayer: .tcp,
            detail: "Secure shell for remote terminal access."
        )
        let context = BonjourChatPromptBuilder.ChatContext(serviceTypeLibrary: [serviceType])
        let turn = BonjourChatPromptBuilder.userTurn(
            message: "Can I ssh to this machine?",
            context: context,
            isFirstTurn: true,
            contextChanged: false
        )
        #expect(turn.contains("<referenced>"))
        #expect(turn.contains("Secure shell"))
    }

    @Test("User turn omits the `<referenced>` block when the query matches no library type")
    func userTurnOmitsReferencedBlockWhenNoMatch() {
        let context = BonjourChatPromptBuilder.ChatContext()
        let turn = BonjourChatPromptBuilder.userTurn(
            message: "Hello!",
            context: context,
            isFirstTurn: true,
            contextChanged: false
        )
        #expect(!turn.contains("<referenced>"))
    }
}
