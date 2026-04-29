//
//  SiriResponsePostProcessorTests.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourAI
import BonjourCore
import BonjourModels

// MARK: - SiriResponsePostProcessorTests

/// Pin the voice-output cleanup pipeline. Each test names the
/// specific TTS-mispronunciation problem it guards against —
/// failures point to a concrete user-facing regression rather
/// than just "the post-processor changed".
@Suite("SiriResponsePostProcessor")
struct SiriResponsePostProcessorTests {

    private func makeLibrary() -> [BonjourServiceType] {
        [
            BonjourServiceType(name: "AirPlay", type: "airplay", transportLayer: .tcp),
            BonjourServiceType(name: "Web Server", type: "http", transportLayer: .tcp),
            BonjourServiceType(name: "Internet Printing", type: "ipp", transportLayer: .tcp),
            BonjourServiceType(name: "Secure Shell", type: "ssh", transportLayer: .tcp),
            BonjourServiceType(name: "Lifx Lighting", type: "lifx", transportLayer: .udp)
        ]
    }

    // MARK: - Wire-Type Replacement

    @Test("Wire type `_airplay._tcp` is rewritten to the library's friendly name `AirPlay`")
    func airplayWireTypeReplacedWithFriendlyName() {
        let library = makeLibrary()
        let result = SiriResponsePostProcessor.replaceServiceTypeWireForms(
            "AirPlay services use _airplay._tcp on the network.",
            library: library
        )
        #expect(result.contains("AirPlay"))
        #expect(!result.contains("_airplay._tcp"))
    }

    @Test("Wire type matching is case-insensitive — `_AirPlay._TCP` still resolves through the library")
    func wireTypeReplacementIsCaseInsensitive() {
        let library = makeLibrary()
        let result = SiriResponsePostProcessor.replaceServiceTypeWireForms(
            "Some clients write the type as _AirPlay._TCP.",
            library: library
        )
        #expect(result.contains("AirPlay"))
        #expect(!result.contains("_AirPlay._TCP"))
    }

    @Test("Multiple wire types in one sentence are all replaced")
    func multipleWireTypesReplacedInOnePass() {
        let library = makeLibrary()
        let result = SiriResponsePostProcessor.replaceServiceTypeWireForms(
            "Use _http._tcp for web, _ipp._tcp for printing, and _ssh._tcp for shell access.",
            library: library
        )
        #expect(result.contains("Web Server"))
        #expect(result.contains("Internet Printing"))
        #expect(result.contains("Secure Shell"))
        #expect(!result.contains("_http._tcp"))
        #expect(!result.contains("_ipp._tcp"))
        #expect(!result.contains("_ssh._tcp"))
    }

    @Test("UDP wire types (e.g. `_lifx._udp`) are matched alongside TCP")
    func udpWireTypesAlsoReplaced() {
        let library = makeLibrary()
        let result = SiriResponsePostProcessor.replaceServiceTypeWireForms(
            "LIFX bulbs advertise _lifx._udp on the network.",
            library: library
        )
        #expect(result.contains("Lifx Lighting"))
        #expect(!result.contains("_lifx._udp"))
    }

    @Test("Unknown wire type falls back to `<type> over <transport>` rendering")
    func unknownWireTypeFallsBackToOverPhrasing() {
        // A type the library doesn't have (e.g. an esoteric or
        // newly-registered protocol). The fallback ensures Siri
        // pronounces words rather than the punctuation —
        // "novel-thing over TCP" is intelligible; the raw form
        // would be read character-by-character.
        let library = makeLibrary()
        let result = SiriResponsePostProcessor.replaceServiceTypeWireForms(
            "Try _novel-thing._tcp instead.",
            library: library
        )
        #expect(result.contains("novel thing over TCP"))
        #expect(!result.contains("_novel-thing._tcp"))
    }

    @Test("Hyphens in the type name are converted to spaces in the fallback phrasing")
    func hyphensInTypeNameBecomeSpacesInFallback() {
        let library = makeLibrary()
        let result = SiriResponsePostProcessor.replaceServiceTypeWireForms(
            "Some printers use _pdl-datastream._tcp.",
            library: library
        )
        #expect(result.contains("pdl datastream over TCP"))
    }

    @Test("Text with no wire types passes through unchanged")
    func noWireTypesIsNoOp() {
        let library = makeLibrary()
        let input = "AirPlay lets you stream audio and video to compatible receivers."
        let result = SiriResponsePostProcessor.replaceServiceTypeWireForms(input, library: library)
        #expect(result == input)
    }

    @Test("Empty library still does the fallback rendering — wire form never reaches Siri")
    func emptyLibraryStillRendersFallback() {
        let result = SiriResponsePostProcessor.replaceServiceTypeWireForms(
            "Use _airplay._tcp for streaming.",
            library: []
        )
        #expect(result.contains("airplay over TCP"))
        #expect(!result.contains("_airplay._tcp"))
    }

    // MARK: - Markdown Stripping

    @Test("Bold markers (`**text**`) are stripped, content preserved")
    func boldMarkersStripped() {
        let result = SiriResponsePostProcessor.stripMarkdown(
            "AirPlay is a **streaming** protocol."
        )
        #expect(result == "AirPlay is a streaming protocol.")
    }

    @Test("Single-asterisk emphasis (`*text*`) is stripped")
    func emphasisMarkersStripped() {
        let result = SiriResponsePostProcessor.stripMarkdown("Use *AirPlay* for streaming.")
        #expect(result == "Use AirPlay for streaming.")
    }

    @Test("Inline code backticks are stripped, content preserved")
    func inlineCodeStripped() {
        let result = SiriResponsePostProcessor.stripMarkdown(
            "The protocol is `AirPlay` over TCP."
        )
        #expect(result == "The protocol is AirPlay over TCP.")
    }

    @Test("Code-fence triple-backticks are stripped — Siri shouldn't say `triple backtick`")
    func codeFencesStripped() {
        let input = "```\nthe code\n```"
        let result = SiriResponsePostProcessor.stripMarkdown(input)
        #expect(!result.contains("```"))
        #expect(result.contains("the code"))
    }

    @Test("Markdown link `[text](url)` is collapsed to just the text")
    func markdownLinksCollapsed() {
        let result = SiriResponsePostProcessor.stripMarkdown(
            "Read [the spec](https://example.com) for details."
        )
        #expect(result == "Read the spec for details.")
    }

    @Test("Heading markers (`#`, `##`) at line starts are stripped")
    func headingMarkersStripped() {
        let result = SiriResponsePostProcessor.stripMarkdown("# Title\nBody text.")
        #expect(!result.contains("# Title"))
        #expect(result.contains("Title"))
        #expect(result.contains("Body text"))
    }

    @Test("Bulleted list markers (`- `) at line starts are stripped, content preserved")
    func bulletListMarkersStripped() {
        let result = SiriResponsePostProcessor.stripMarkdown(
            "Services include:\n- AirPlay\n- HTTP\n- SSH"
        )
        #expect(!result.contains("- AirPlay"))
        #expect(result.contains("AirPlay"))
        #expect(result.contains("HTTP"))
        #expect(result.contains("SSH"))
    }

    @Test("Numbered list markers (`1. `, `2. `) at line starts are stripped")
    func numberedListMarkersStripped() {
        let result = SiriResponsePostProcessor.stripMarkdown(
            "Steps:\n1. First\n2. Second\n3. Third"
        )
        #expect(!result.contains("1. First"))
        #expect(result.contains("First"))
        #expect(result.contains("Second"))
        #expect(result.contains("Third"))
    }

    @Test("Underscores in identifiers are NOT stripped — protects wire-type fallback rendering")
    func underscoreItalicsLeftAlone() {
        // A literal underscore-italic in model output is
        // extremely rare; underscore-rich identifiers are
        // common. The processor errs on the side of preserving
        // identifiers so the wire-type pipeline above can do
        // its job.
        let result = SiriResponsePostProcessor.stripMarkdown("snake_case_identifier appears.")
        #expect(result.contains("snake_case_identifier"))
    }

    // MARK: - Length Cap

    @Test("Inputs at or below `maxLength` pass through unchanged — boundary is inclusive")
    func shortInputsPassThrough() {
        let input = "Short answer."
        let result = SiriResponsePostProcessor.truncateToSentenceBoundary(input, maxLength: 100)
        #expect(result == input)
    }

    @Test("Long input is cut at the LAST sentence boundary that fits within `maxLength` — preserves the most context")
    func longInputTruncatedAtSentenceBoundary() {
        // The function picks the longest sentence-aligned prefix
        // that fits, so a 35-char limit on
        // "First sentence. Second sentence. ..."
        // keeps both first sentences (32 chars total) rather than
        // bailing on the first sentence boundary it finds.
        let input = "First sentence. Second sentence. Third sentence is much, much longer than the others."
        let result = SiriResponsePostProcessor.truncateToSentenceBoundary(input, maxLength: 35)
        #expect(result == "First sentence. Second sentence.")
    }

    @Test("When only one sentence boundary fits, that's the cut point")
    func longInputCutsAtOnlyAvailableBoundary() {
        let input = "First sentence. Second sentence runs much longer than the cap."
        let result = SiriResponsePostProcessor.truncateToSentenceBoundary(input, maxLength: 25)
        #expect(result == "First sentence.")
    }

    @Test("Truncation does NOT append `...` or `(truncated)` — Siri reads such markers literally")
    func truncationLeavesNoMarker() {
        let input = "First sentence. Second sentence is too long to fit."
        let result = SiriResponsePostProcessor.truncateToSentenceBoundary(input, maxLength: 20)
        #expect(!result.contains("…"))
        #expect(!result.contains("..."))
        #expect(!result.contains("(truncated)"))
    }

    @Test("Hard truncation when the prefix has no sentence boundary at all")
    func hardTruncateWhenNoSentenceBoundary() {
        let input = String(repeating: "A", count: 1_000)
        let result = SiriResponsePostProcessor.truncateToSentenceBoundary(input, maxLength: 100)
        #expect(result.count == 100)
    }

    @Test("`maxLength` of zero returns an empty string — defensive against bad callers")
    func zeroMaxLengthReturnsEmpty() {
        let result = SiriResponsePostProcessor.truncateToSentenceBoundary("anything", maxLength: 0)
        #expect(result.isEmpty)
    }

    // MARK: - Top-Level `process`

    @Test("`process` runs all three stages in order — wire types replaced, Markdown stripped, length capped")
    func processChainsAllStagesInOrder() {
        let library = makeLibrary()
        let input = "**AirPlay** services use `_airplay._tcp` to advertise themselves."
        let result = SiriResponsePostProcessor.process(input, library: library)
        // Wire type rendered as friendly name.
        #expect(result.contains("AirPlay"))
        // No raw wire type.
        #expect(!result.contains("_airplay._tcp"))
        // No Markdown markers.
        #expect(!result.contains("**"))
        #expect(!result.contains("`"))
    }

    @Test("`process` is idempotent — running twice on the same input gives the same result")
    func processIsIdempotent() {
        let library = makeLibrary()
        let input = "**AirPlay** uses _airplay._tcp."
        let once = SiriResponsePostProcessor.process(input, library: library)
        let twice = SiriResponsePostProcessor.process(once, library: library)
        #expect(once == twice)
    }

    @Test("`process` trims leading and trailing whitespace from the final result")
    func processTrimsWhitespace() {
        let library = makeLibrary()
        let result = SiriResponsePostProcessor.process(
            "   AirPlay is great.   ",
            library: library
        )
        #expect(result == "AirPlay is great.")
    }

    @Test("`process` preserves clean input verbatim — already-voice-friendly text is a no-op")
    func processIsNoOpOnCleanText() {
        let library = makeLibrary()
        let input = "AirPlay lets you stream audio to compatible receivers."
        let result = SiriResponsePostProcessor.process(input, library: library)
        #expect(result == input)
    }
}
