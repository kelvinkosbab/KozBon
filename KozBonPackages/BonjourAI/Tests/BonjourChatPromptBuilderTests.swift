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

@Suite("BonjourChatPromptBuilder")
@MainActor
struct BonjourChatPromptBuilderTests {

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

    // MARK: - Context Block — Discovered Services

    @Test func contextBlockShowsNoneWhenNoDiscoveredServices() {
        let context = BonjourChatPromptBuilder.ChatContext()
        let block = BonjourChatPromptBuilder.contextBlock(context: context)
        #expect(block.contains("Discovered services: none"))
    }

    @Test func contextBlockIncludesDiscoveredServiceNames() {
        let services = [
            makeService(name: "Living Room Apple TV", type: "airplay"),
            makeService(name: "Office Printer", type: "ipp")
        ]
        let context = BonjourChatPromptBuilder.ChatContext(discoveredServices: services)
        let block = BonjourChatPromptBuilder.contextBlock(context: context)
        #expect(block.contains("Living Room Apple TV"))
        #expect(block.contains("Office Printer"))
    }

    @Test func contextBlockShowsCountForDiscoveredServices() {
        let services = (0..<3).map { makeService(name: "Service \($0)") }
        let context = BonjourChatPromptBuilder.ChatContext(discoveredServices: services)
        let block = BonjourChatPromptBuilder.contextBlock(context: context)
        #expect(block.contains("(3)"))
    }

    // MARK: - Context Block — Published Services

    @Test func contextBlockShowsNoneWhenNoPublishedServices() {
        let context = BonjourChatPromptBuilder.ChatContext()
        let block = BonjourChatPromptBuilder.contextBlock(context: context)
        #expect(block.contains("Published services from this device: none"))
    }

    @Test func contextBlockIncludesPublishedServiceNames() {
        let services = [makeService(name: "My Web Server", type: "http")]
        let context = BonjourChatPromptBuilder.ChatContext(publishedServices: services)
        let block = BonjourChatPromptBuilder.contextBlock(context: context)
        #expect(block.contains("My Web Server"))
    }

    // MARK: - Context Block — Library

    @Test func contextBlockIncludesLibraryCount() {
        let library = [
            makeServiceType(name: "HTTP", type: "http"),
            makeServiceType(name: "SSH", type: "ssh")
        ]
        let context = BonjourChatPromptBuilder.ChatContext(serviceTypeLibrary: library)
        let block = BonjourChatPromptBuilder.contextBlock(context: context)
        #expect(block.contains("2 types supported"))
    }

    @Test func contextBlockIncludesLibraryNames() {
        let library = [
            makeServiceType(name: "HTTP", type: "http"),
            makeServiceType(name: "SSH", type: "ssh")
        ]
        let context = BonjourChatPromptBuilder.ChatContext(serviceTypeLibrary: library)
        let block = BonjourChatPromptBuilder.contextBlock(context: context)
        #expect(block.contains("HTTP"))
        #expect(block.contains("SSH"))
    }

    // MARK: - Context Block — Large Lists

    @Test func contextBlockTruncatesDiscoveredServicesAt50() {
        let services = (0..<75).map { makeService(name: "Service \($0)") }
        let context = BonjourChatPromptBuilder.ChatContext(discoveredServices: services)
        let block = BonjourChatPromptBuilder.contextBlock(context: context)
        #expect(block.contains("(75)"))
        #expect(block.contains("25 more"))
    }

    @Test func contextBlockHandlesExactly50DiscoveredServices() {
        let services = (0..<50).map { makeService(name: "Service \($0)") }
        let context = BonjourChatPromptBuilder.ChatContext(discoveredServices: services)
        let block = BonjourChatPromptBuilder.contextBlock(context: context)
        #expect(block.contains("(50)"))
        #expect(!block.contains("more"))
    }

    // MARK: - Context Preamble

    @Test func contextPreambleWrapsInTags() {
        let context = BonjourChatPromptBuilder.ChatContext()
        let preamble = BonjourChatPromptBuilder.contextPreamble(context: context)
        #expect(preamble.contains("<context>"))
        #expect(preamble.contains("</context>"))
    }

    @Test func contextPreambleIncludesContextBlock() {
        let services = [makeService(name: "Test Device", type: "http")]
        let context = BonjourChatPromptBuilder.ChatContext(discoveredServices: services)
        let preamble = BonjourChatPromptBuilder.contextPreamble(context: context)
        #expect(preamble.contains("Test Device"))
    }

    // MARK: - User Turn Builder

    @Test func userTurnOnFirstTurnIncludesContext() {
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

    @Test func userTurnWhenContextChangedIncludesContext() {
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

    @Test func userTurnOnSubsequentStableContextOmitsContext() {
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

    @Test func chatContextDefaultsToEmpty() {
        let context = BonjourChatPromptBuilder.ChatContext()
        #expect(context.discoveredServices.isEmpty)
        #expect(context.publishedServices.isEmpty)
        #expect(context.serviceTypeLibrary.isEmpty)
    }
}
