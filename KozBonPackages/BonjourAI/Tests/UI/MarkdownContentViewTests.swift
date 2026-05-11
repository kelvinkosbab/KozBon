//
//  MarkdownContentViewTests.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourAI

// Tests for `MarkdownContentView`'s line-classification rules. The
// renderer is a SwiftUI view that builds a `VStack` of `Text` views
// per line, so we can't snapshot the rendered output here. Instead we
// exercise the parser surface — `parseOrderedListPrefix(_:)` — and
// confirm the boundary cases that the chat assistant relies on.
//
// The bullet-detection branch is too simple to need its own
// assertion (a string `hasPrefix("- ")` check), so this file
// focuses on the numbered-list parser, which is the addition that
// motivated adding tests to this view at all.

@Suite("MarkdownContentView · Ordered List Detection")
struct MarkdownContentViewOrderedListTests {

    // MARK: - Single-digit markers

    @Test("Detects a single-digit ordered marker followed by a period")
    func singleDigitDot() {
        let result = MarkdownContentView.parseOrderedListPrefix("1. Apple TV")
        #expect(result?.number == 1)
        #expect(result?.rest == "Apple TV")
    }

    @Test("Detects a single-digit ordered marker followed by a closing paren")
    func singleDigitParen() {
        let result = MarkdownContentView.parseOrderedListPrefix("3) HomePod")
        #expect(result?.number == 3)
        #expect(result?.rest == "HomePod")
    }

    // MARK: - Multi-digit markers

    @Test("Detects multi-digit ordered markers up to 4 digits")
    func multiDigit() {
        let result = MarkdownContentView.parseOrderedListPrefix("42. Printer")
        #expect(result?.number == 42)
        #expect(result?.rest == "Printer")
    }

    @Test("Caps marker length at 4 digits so a long inline number isn't mis-classified")
    func capsAtFourDigits() {
        // A 5-digit prefix means "1234" is parsed as the marker (4 digits),
        // but then position 4 is "5" — not "." or ")", so detection fails.
        // The line falls back to a paragraph render, which is exactly the
        // intended outcome for prose like "Port 12345 is in use."
        let result = MarkdownContentView.parseOrderedListPrefix("12345. Lorem ipsum")
        #expect(result == nil)
    }

    // MARK: - Non-matches

    @Test("Line without a digit prefix is not an ordered list item")
    func rejectsNoDigits() {
        #expect(MarkdownContentView.parseOrderedListPrefix("Just a sentence.") == nil)
    }

    @Test("Line with a marker but no trailing space is not an ordered list item")
    func rejectsMissingSpace() {
        // "1.Foo" — punctuation pressed against content (no space) is
        // typical inline prose (e.g., a version like "v1.2"), not a list.
        #expect(MarkdownContentView.parseOrderedListPrefix("1.Foo") == nil)
    }

    @Test("Line ending immediately after the marker (no content) is not a list item")
    func rejectsTrailingMarkerOnly() {
        #expect(MarkdownContentView.parseOrderedListPrefix("1.") == nil)
        #expect(MarkdownContentView.parseOrderedListPrefix("1. ") != nil)
        // Note: "1. " with an empty content string is technically a list
        // item with empty content — the parser accepts it and returns
        // `rest == ""`. The renderer handles empty content gracefully.
    }

    @Test("Marker followed by another non-`.`/`)` punctuation is not a list item")
    func rejectsOtherPunctuation() {
        #expect(MarkdownContentView.parseOrderedListPrefix("1: not a list") == nil)
        #expect(MarkdownContentView.parseOrderedListPrefix("1, two") == nil)
    }

    @Test("Marker without a space (just `<digit>.<content>`) is not a list item")
    func rejectsNoSpaceAfterMarker() {
        #expect(MarkdownContentView.parseOrderedListPrefix("1.Apple") == nil)
        #expect(MarkdownContentView.parseOrderedListPrefix("1)Apple") == nil)
    }

    // MARK: - Realistic chat-assistant output shapes

    @Test("Discovered-services line shape produced by the chat assistant parses cleanly")
    func discoveredServicesShape() {
        // The chat prompt's context block uses this exact shape, and
        // the model mirrors it back. Pinning this guards against
        // regressions where a renderer change leaves these lines
        // formatted as plain paragraphs.
        let line = "1. 'Living Room Apple TV' (`_airplay._tcp`) at 192.168.1.5 — advertises AirPlay 2"
        let result = MarkdownContentView.parseOrderedListPrefix(line)
        #expect(result?.number == 1)
        #expect(result?.rest == "'Living Room Apple TV' (`_airplay._tcp`) at 192.168.1.5 — advertises AirPlay 2")
    }

    @Test("Numbers above 1 in mid-list still parse — the marker resets per line")
    func midListNumber() {
        let line = "7. 'Kitchen HomePod'"
        let result = MarkdownContentView.parseOrderedListPrefix(line)
        #expect(result?.number == 7)
        #expect(result?.rest == "'Kitchen HomePod'")
    }
}
