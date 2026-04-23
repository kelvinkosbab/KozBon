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

// One narrow `@Test` per invariant — system-instruction rules, context
// sections (scan status, discovered services, published services,
// library, per-service fields), query-triggered descriptions, and user-
// turn composition. Splitting by section would scatter tightly-related
// prompt-shape assertions across files and make it harder to see the
// full prompt contract at a glance, so the length rule is disabled for
// this suite.
@Suite("BonjourChatPromptBuilder")
@MainActor
// swiftlint:disable:next type_body_length
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
        // Library now renders as "Service type library (N types, grouped
        // by category)" so the model knows to use the taxonomy. The test
        // just pins that the count is surfaced; the exact phrasing around
        // it can evolve.
        #expect(block.contains("(2 types"))
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

    // MARK: - Context Block: Scan Status
    //
    // The scan-freshness line is the model's signal for whether an
    // empty discovered list means "nothing here" or "scan hasn't run
    // yet". Both branches matter: missing this distinction produces
    // the exact "I don't have enough information" responses that
    // triggered this whole audit.

    @Test func scanStatusReportsNoScanWhenLastScanTimeIsNil() {
        let context = BonjourChatPromptBuilder.ChatContext()
        let block = BonjourChatPromptBuilder.contextBlock(context: context)
        #expect(block.contains("no scan has run yet"))
    }

    @Test func scanStatusReportsElapsedTimeWhenLastScanKnown() {
        let tenSecondsAgo = Date(timeIntervalSinceNow: -10)
        let context = BonjourChatPromptBuilder.ChatContext(lastScanTime: tenSecondsAgo)
        let block = BonjourChatPromptBuilder.contextBlock(context: context)
        #expect(block.contains("last scan started"))
        #expect(block.contains("s ago"))
    }

    @Test func scanStatusReportsInProgressTakesPriority() {
        // Even with a prior lastScanTime, `isScanning = true` means
        // results are still populating and the model should caveat
        // accordingly. The in-progress line must take priority.
        let earlier = Date(timeIntervalSinceNow: -30)
        let context = BonjourChatPromptBuilder.ChatContext(
            lastScanTime: earlier,
            isScanning: true
        )
        let block = BonjourChatPromptBuilder.contextBlock(context: context)
        #expect(block.contains("in progress"))
        #expect(!block.contains("last scan started"))
    }

    // MARK: - Context Block: Rich Per-Service Data

    @Test func discoveredServiceLineIncludesTransportLayer() {
        // Transport (tcp/udp) is called out because the model needs it
        // to differentiate protocols that exist on both (e.g. DNS,
        // some streaming) and to caveat behaviors that depend on it.
        let service = makeService(name: "Printer", type: "ipp")
        let context = BonjourChatPromptBuilder.ChatContext(discoveredServices: [service])
        let block = BonjourChatPromptBuilder.contextBlock(context: context)
        #expect(block.contains("· tcp ·"))
    }

    @Test func discoveredServiceLineIncludesHostname() {
        let service = makeService(name: "Apple TV", type: "airplay")
        let context = BonjourChatPromptBuilder.ChatContext(discoveredServices: [service])
        let block = BonjourChatPromptBuilder.contextBlock(context: context)
        #expect(block.contains("host:"))
    }

    @Test func emptyDiscoveredListExplainsScanMayNotHaveRunYet() {
        // When the context is empty, the block must distinguish "nothing
        // on the network" from "scan hasn't populated yet". The richer
        // copy tells the model to suggest waiting rather than declaring
        // the network empty.
        let context = BonjourChatPromptBuilder.ChatContext()
        let block = BonjourChatPromptBuilder.contextBlock(context: context)
        #expect(block.contains("scan has not populated any results"))
    }

    // MARK: - Context Block: Grouped Library

    @Test func libraryListsCategoriesWhenTypesMatch() {
        // Types that belong in known categories should render under
        // their category heading so the model doesn't have to infer
        // taxonomy from names alone.
        let library = [
            makeServiceType(name: "AirPlay", type: "airplay"),
            makeServiceType(name: "HomeKit", type: "hap"),
            makeServiceType(name: "IPP", type: "ipp")
        ]
        let context = BonjourChatPromptBuilder.ChatContext(serviceTypeLibrary: library)
        let block = BonjourChatPromptBuilder.contextBlock(context: context)
        #expect(block.contains("Apple Devices"))
        #expect(block.contains("Smart Home"))
        #expect(block.contains("Printers & Scanners"))
    }

    @Test func libraryBucketsUncategorizedTypesUnderOther() {
        // Types not in any predefined category must still appear so the
        // model knows they exist. An "Other" bucket catches them.
        let library = [
            makeServiceType(name: "Obscure", type: "some-unknown-proto")
        ]
        let context = BonjourChatPromptBuilder.ChatContext(serviceTypeLibrary: library)
        let block = BonjourChatPromptBuilder.contextBlock(context: context)
        #expect(block.contains("Other:"))
        #expect(block.contains("Obscure"))
    }

    // MARK: - Queried Descriptions Block

    @Test func queriedBlockEmptyWhenQueryMatchesNoType() {
        let library = [makeServiceType(name: "HTTP", type: "http")]
        let context = BonjourChatPromptBuilder.ChatContext(serviceTypeLibrary: library)
        let block = BonjourChatPromptBuilder.queriedDescriptionsBlock(
            context: context,
            query: "What's the weather today?"
        )
        #expect(block.isEmpty)
    }

    @Test func queriedBlockIncludesMatchedTypeDescription() {
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

    @Test func queriedBlockIsCaseInsensitive() {
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

    @Test func queriedBlockSkipsTypesWithoutDetail() {
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

    @Test func userTurnIncludesQueriedBlockWhenMatch() {
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

    @Test func userTurnOmitsReferencedBlockWhenNoMatch() {
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
