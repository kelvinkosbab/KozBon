//
//  SiriPlainTextTests.swift
//  BonjourAppIntents
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Testing
@testable import BonjourAppIntents

// MARK: - SiriPlainTextTests

@Suite("SiriPlainText")
struct SiriPlainTextTests {

    @Test("Headings, list markers, and emphasis are dropped")
    func stripsMarkdown() {
        let markdown = """
        ## What it is
        **AirPlay** streams *audio* and `video`.

        - Works with Apple TV
        1. Pick a speaker
        > Needs the same network
        """
        #expect(SiriPlainText.from(markdown: markdown) == "What it is AirPlay streams audio and video. "
            + "Works with Apple TV Pick a speaker Needs the same network")
    }

    @Test("Links keep their text")
    func keepsLinkText() {
        #expect(SiriPlainText.from(markdown: "See [the spec](https://example.com).") == "See the spec.")
    }

    @Test("Blank input stays empty")
    func emptyInput() {
        #expect(SiriPlainText.from(markdown: "\n  \n").isEmpty)
    }
}
