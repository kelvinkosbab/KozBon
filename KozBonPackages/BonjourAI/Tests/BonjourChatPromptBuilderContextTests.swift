//
//  BonjourChatPromptBuilderContextTests.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourAI
import BonjourCore
import BonjourModels

// MARK: - BonjourChatPromptBuilderContextTests

/// Pin the shape of the `<context>` block injected on first-turn / context-
/// changed user turns: discovered/published service rendering, scan
/// status, library grouping, large-list truncation, and the surrounding
/// preamble. Split from the main suite so each file stays under
/// SwiftLint's `type_body_length` / `file_length` thresholds without
/// disabling them.
@Suite("BonjourChatPromptBuilder · Context")
@MainActor
struct BonjourChatPromptBuilderContextTests {

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

    // MARK: - Context Block — Discovered Services

    @Test("Empty discovered list renders as `Discovered services: none` rather than blank")
    func contextBlockShowsNoneWhenNoDiscoveredServices() {
        let context = BonjourChatPromptBuilder.ChatContext()
        let block = BonjourChatPromptBuilder.contextBlock(context: context)
        #expect(block.contains("Discovered services: none"))
    }

    @Test("Discovered services are listed by name so the model can quote them verbatim")
    func contextBlockIncludesDiscoveredServiceNames() {
        let services = [
            makeService(name: "Living Room Apple TV", type: "airplay"),
            makeService(name: "Office Printer", type: "ipp")
        ]
        let context = BonjourChatPromptBuilder.ChatContext(discoveredServices: services)
        let block = BonjourChatPromptBuilder.contextBlock(context: context)
        #expect(block.contains("Living Room Apple TV"))
        #expect(block.contains("Office Printer"))
    }

    @Test("Discovered list header includes the total count so the model knows the size")
    func contextBlockShowsCountForDiscoveredServices() {
        let services = (0..<3).map { makeService(name: "Service \($0)") }
        let context = BonjourChatPromptBuilder.ChatContext(discoveredServices: services)
        let block = BonjourChatPromptBuilder.contextBlock(context: context)
        #expect(block.contains("(3)"))
    }

    // MARK: - Context Block — Published Services

    @Test("Empty published list renders as `Published services from this device: none`")
    func contextBlockShowsNoneWhenNoPublishedServices() {
        let context = BonjourChatPromptBuilder.ChatContext()
        let block = BonjourChatPromptBuilder.contextBlock(context: context)
        #expect(block.contains("Published services from this device: none"))
    }

    @Test("Published services are surfaced by name so the model distinguishes self vs others")
    func contextBlockIncludesPublishedServiceNames() {
        let services = [makeService(name: "My Web Server", type: "http")]
        let context = BonjourChatPromptBuilder.ChatContext(publishedServices: services)
        let block = BonjourChatPromptBuilder.contextBlock(context: context)
        #expect(block.contains("My Web Server"))
    }

    // MARK: - Context Block — Library

    @Test("Library header carries the type count so the model knows the taxonomy size")
    func contextBlockIncludesLibraryCount() {
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

    @Test("Library entries are emitted by display name so the model can reference them")
    func contextBlockIncludesLibraryNames() {
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

    @Test("Discovered list past 50 entries shows total count plus an `N more` overflow line")
    func contextBlockTruncatesDiscoveredServicesAt50() {
        let services = (0..<75).map { makeService(name: "Service \($0)") }
        let context = BonjourChatPromptBuilder.ChatContext(discoveredServices: services)
        let block = BonjourChatPromptBuilder.contextBlock(context: context)
        #expect(block.contains("(75)"))
        #expect(block.contains("25 more"))
    }

    @Test("Exactly 50 discovered services renders without an `N more` overflow line")
    func contextBlockHandlesExactly50DiscoveredServices() {
        let services = (0..<50).map { makeService(name: "Service \($0)") }
        let context = BonjourChatPromptBuilder.ChatContext(discoveredServices: services)
        let block = BonjourChatPromptBuilder.contextBlock(context: context)
        #expect(block.contains("(50)"))
        #expect(!block.contains("more"))
    }

    // MARK: - Context Preamble

    @Test("Preamble wraps the block in `<context>`/`</context>` tags for parsing clarity")
    func contextPreambleWrapsInTags() {
        let context = BonjourChatPromptBuilder.ChatContext()
        let preamble = BonjourChatPromptBuilder.contextPreamble(context: context)
        #expect(preamble.contains("<context>"))
        #expect(preamble.contains("</context>"))
    }

    @Test("Preamble inlines the context block contents inside the wrapping tags")
    func contextPreambleIncludesContextBlock() {
        let services = [makeService(name: "Test Device", type: "http")]
        let context = BonjourChatPromptBuilder.ChatContext(discoveredServices: services)
        let preamble = BonjourChatPromptBuilder.contextPreamble(context: context)
        #expect(preamble.contains("Test Device"))
    }

    // MARK: - Context Block: Scan Status
    //
    // The scan-freshness line is the model's signal for whether an
    // empty discovered list means "nothing here" or "scan hasn't run
    // yet". Both branches matter: missing this distinction produces
    // the exact "I don't have enough information" responses that
    // triggered this whole audit.

    @Test("Nil `lastScanTime` renders as `no scan has run yet`, not as a stale empty list")
    func scanStatusReportsNoScanWhenLastScanTimeIsNil() {
        let context = BonjourChatPromptBuilder.ChatContext()
        let block = BonjourChatPromptBuilder.contextBlock(context: context)
        #expect(block.contains("no scan has run yet"))
    }

    @Test("Known `lastScanTime` renders elapsed seconds so the model can hedge on staleness")
    func scanStatusReportsElapsedTimeWhenLastScanKnown() {
        let tenSecondsAgo = Date(timeIntervalSinceNow: -10)
        let context = BonjourChatPromptBuilder.ChatContext(lastScanTime: tenSecondsAgo)
        let block = BonjourChatPromptBuilder.contextBlock(context: context)
        #expect(block.contains("last scan started"))
        #expect(block.contains("s ago"))
    }

    @Test("`isScanning` overrides `lastScanTime` so the model knows results are still streaming")
    func scanStatusReportsInProgressTakesPriority() {
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

    @Test("Each discovered-service line includes the transport layer for protocol disambiguation")
    func discoveredServiceLineIncludesTransportLayer() {
        // Transport (tcp/udp) is called out because the model needs it
        // to differentiate protocols that exist on both (e.g. DNS,
        // some streaming) and to caveat behaviors that depend on it.
        let service = makeService(name: "Printer", type: "ipp")
        let context = BonjourChatPromptBuilder.ChatContext(discoveredServices: [service])
        let block = BonjourChatPromptBuilder.contextBlock(context: context)
        #expect(block.contains("· tcp ·"))
    }

    @Test("Each discovered-service line surfaces the `host:` tag so the model can ground replies")
    func discoveredServiceLineIncludesHostname() {
        let service = makeService(name: "Apple TV", type: "airplay")
        let context = BonjourChatPromptBuilder.ChatContext(discoveredServices: [service])
        let block = BonjourChatPromptBuilder.contextBlock(context: context)
        #expect(block.contains("host:"))
    }

    @Test("Empty discovered block warns the scan may not have populated yet, not that the network is empty")
    func emptyDiscoveredListExplainsScanMayNotHaveRunYet() {
        // When the context is empty, the block must distinguish "nothing
        // on the network" from "scan hasn't populated yet". The richer
        // copy tells the model to suggest waiting rather than declaring
        // the network empty.
        let context = BonjourChatPromptBuilder.ChatContext()
        let block = BonjourChatPromptBuilder.contextBlock(context: context)
        #expect(block.contains("scan has not populated any results"))
    }

    // MARK: - Context Block: Grouped Library

    @Test("Library renders known types under category headings so the model has explicit taxonomy")
    func libraryListsCategoriesWhenTypesMatch() {
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

    @Test("Library uses an `Other:` bucket for types outside any predefined category")
    func libraryBucketsUncategorizedTypesUnderOther() {
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
}
