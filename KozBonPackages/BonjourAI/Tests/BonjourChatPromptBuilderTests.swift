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
        let context = BonjourChatPromptBuilder.ChatContext()
        let instructions = BonjourChatPromptBuilder.systemInstructions(context: context)
        #expect(instructions.contains("Bonjour"))
        #expect(instructions.contains("KozBon"))
    }

    @Test func systemInstructionsRefusesOffTopic() {
        let context = BonjourChatPromptBuilder.ChatContext()
        let instructions = BonjourChatPromptBuilder.systemInstructions(context: context)
        #expect(instructions.contains("DO NOT"))
        #expect(instructions.contains("politely redirect"))
    }

    @Test func systemInstructionsIncludesLanguageDirective() {
        let context = BonjourChatPromptBuilder.ChatContext()
        let instructions = BonjourChatPromptBuilder.systemInstructions(context: context)
        let language = BonjourServicePromptBuilder.preferredLanguageName
        #expect(instructions.contains("respond in \(language)"))
    }

    @Test func systemInstructionsMentionsTabs() {
        let context = BonjourChatPromptBuilder.ChatContext()
        let instructions = BonjourChatPromptBuilder.systemInstructions(context: context)
        #expect(instructions.contains("Discover tab"))
        #expect(instructions.contains("Library tab"))
        #expect(instructions.contains("Preferences tab"))
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

    // MARK: - Integration: System Instructions include Context

    @Test func systemInstructionsIncludesContextBlock() {
        let services = [makeService(name: "Test Device", type: "http")]
        let context = BonjourChatPromptBuilder.ChatContext(discoveredServices: services)
        let instructions = BonjourChatPromptBuilder.systemInstructions(context: context)
        #expect(instructions.contains("CURRENT CONTEXT"))
        #expect(instructions.contains("Test Device"))
    }

    @Test func systemInstructionsReflectDifferentContexts() {
        let emptyContext = BonjourChatPromptBuilder.ChatContext()
        let populatedContext = BonjourChatPromptBuilder.ChatContext(
            discoveredServices: [makeService(name: "Discovered")]
        )
        let empty = BonjourChatPromptBuilder.systemInstructions(context: emptyContext)
        let populated = BonjourChatPromptBuilder.systemInstructions(context: populatedContext)
        #expect(empty != populated)
    }

    // MARK: - ChatContext Defaults

    @Test func chatContextDefaultsToEmpty() {
        let context = BonjourChatPromptBuilder.ChatContext()
        #expect(context.discoveredServices.isEmpty)
        #expect(context.publishedServices.isEmpty)
        #expect(context.serviceTypeLibrary.isEmpty)
    }
}
