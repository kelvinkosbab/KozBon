//
//  BonjourChatPromptBuilderWhatsNewTests.swift
//  BonjourAICore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourCore
@testable import BonjourAICore

// MARK: - BonjourChatPromptBuilderWhatsNewTests

/// Pins the `whatsNewBlock(query:)` contract: it injects real
/// release notes ONLY for what's-new queries, caps the entry
/// count to stay within the on-device model's token budget, and
/// renders the most-recent versions newest-first with an explicit
/// "answer only from this list" guard so the model can't
/// hallucinate version history.
@Suite("BonjourChatPromptBuilder · What's New")
struct BonjourChatPromptBuilderWhatsNewTests {

    // MARK: - Gating

    @Test("Returns empty for non-what's-new queries")
    func emptyForUnrelatedQuery() {
        #expect(BonjourChatPromptBuilder.whatsNewBlock(query: "What is Matter?").isEmpty)
        #expect(BonjourChatPromptBuilder.whatsNewBlock(query: "What's on my network?").isEmpty)
        #expect(BonjourChatPromptBuilder.whatsNewBlock(query: "").isEmpty)
    }

    @Test("Returns a populated block for a what's-new query")
    func populatedForWhatsNewQuery() {
        let block = BonjourChatPromptBuilder.whatsNewBlock(query: "What's new in this version?")
        #expect(!block.isEmpty)
        #expect(block.contains("RECENT KOZBON RELEASES"))
    }

    // MARK: - Content

    @Test("Block leads with the most recent release")
    func leadsWithMostRecentRelease() {
        let block = BonjourChatPromptBuilder.whatsNewBlock(query: "what's new?")
        guard let latest = ReleaseNotes.all.first else {
            Issue.record("ReleaseNotes.all is empty")
            return
        }
        // The newest version header must appear before any older one.
        let latestRange = block.range(of: "Version \(latest.version):")
        #expect(latestRange != nil)
        if let second = ReleaseNotes.all.dropFirst().first,
           let latestRange,
           let olderRange = block.range(of: "Version \(second.version):") {
            #expect(latestRange.lowerBound < olderRange.lowerBound)
        }
    }

    @Test("Block contains the newest release's actual highlight text")
    func containsRealHighlightText() {
        let block = BonjourChatPromptBuilder.whatsNewBlock(query: "what changed recently?")
        guard let latest = ReleaseNotes.all.first,
              let firstHighlight = latest.highlights.first else {
            Issue.record("ReleaseNotes.all has no highlights")
            return
        }
        #expect(block.contains(firstHighlight))
    }

    @Test("Block instructs the model to answer only from the list")
    func includesAntiHallucinationGuard() {
        let block = BonjourChatPromptBuilder.whatsNewBlock(query: "release notes")
        #expect(block.lowercased().contains("never invent"))
    }

    // MARK: - Token Budget Cap

    @Test("Block caps the number of releases rendered")
    func capsReleaseCount() {
        let block = BonjourChatPromptBuilder.whatsNewBlock(query: "what's new?")
        let renderedVersionCount = ReleaseNotes.all.filter {
            block.contains("Version \($0.version):")
        }.count
        // The full table reaches back to 3.0; the block must render
        // strictly fewer than all of them to stay within budget.
        #expect(renderedVersionCount <= 6)
        #expect(renderedVersionCount < ReleaseNotes.all.count)
    }
}

// MARK: - ReleaseNotesTests

/// Sanity checks on the shared release-notes table that both the
/// `WhatsNewView` and the chat assistant read.
@Suite("ReleaseNotes")
struct ReleaseNotesTests {

    @Test("Table is non-empty and newest-first")
    func nonEmptyNewestFirst() {
        #expect(!ReleaseNotes.all.isEmpty)
        // First entry is the highest version (4.x), last is 3.0.
        #expect(ReleaseNotes.all.first?.version.hasPrefix("4.") == true)
        #expect(ReleaseNotes.all.last?.version == "3.0")
    }

    @Test("Every release has at least one highlight")
    func everyReleaseHasHighlights() {
        for release in ReleaseNotes.all {
            #expect(!release.highlights.isEmpty, "Release \(release.version) has no highlights")
        }
    }

    @Test("Version strings are unique")
    func versionsAreUnique() {
        let versions = ReleaseNotes.all.map(\.version)
        #expect(Set(versions).count == versions.count)
    }

    @Test("`id` is the version string")
    func idIsVersion() {
        let note = ReleaseNote(version: "9.9", highlights: ["test"])
        #expect(note.id == "9.9")
    }
}
