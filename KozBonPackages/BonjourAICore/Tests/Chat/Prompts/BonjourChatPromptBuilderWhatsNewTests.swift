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
/// release notes ONLY for what's-new queries, covers every release
/// in the current major version newest-first, keeps older releases
/// to their summaries to stay within the on-device model's token
/// budget, and carries an explicit "answer only from this list"
/// guard so the model can't hallucinate version history.
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
        #expect(block.contains("KOZBON 4.x RELEASES"))
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

    // MARK: - Major Version Coverage

    @Test("The Chat \"What's new\" suggestion gets the release notes")
    func suggestionValueTriggers() {
        #expect(!BonjourChatPromptBuilder.whatsNewBlock(query: "What's new").isEmpty)
    }

    @Test("Block covers every release in the current major version and nothing older")
    func coversCurrentMajorVersion() throws {
        let block = BonjourChatPromptBuilder.whatsNewBlock(query: "what's new?")
        let latest = try #require(ReleaseNotes.all.first)
        let major = try #require(latest.version.split(separator: ".").first)
        for release in ReleaseNotes.all {
            let isCurrentMajor = release.version.split(separator: ".").first == major
            #expect(
                block.contains("Version \(release.version)") == isCurrentMajor,
                "Version \(release.version) inclusion should match its major version"
            )
        }
        #expect(block.contains("Version \(latest.version) (latest):"))
    }

    @Test("Older releases contribute their summary, not their highlights")
    func olderReleasesUseSummaries() throws {
        let block = BonjourChatPromptBuilder.whatsNewBlock(query: "what's new?")
        let older = try #require(
            BonjourChatPromptBuilder.currentMajorReleases(offeringCloudProviders: true).dropFirst().first
        )
        let summary = older.summary.components(separatedBy: "\n\n").joined(separator: " ")
        #expect(block.contains("Version \(older.version): \(summary)"))
        for highlight in older.highlights where !older.summary.contains(highlight) {
            #expect(!block.contains(highlight))
        }
    }

    @Test("Each release renders on its own line")
    func oneLinePerRelease() {
        let block = BonjourChatPromptBuilder.whatsNewBlock(query: "what's new?")
        let releases = BonjourChatPromptBuilder.currentMajorReleases(offeringCloudProviders: true)
        let latestHighlightCount = releases.first?.highlights.count ?? 0
        // Header, latest version line, its highlights, one line per older release.
        let expected = 2 + latestHighlightCount + releases.count - 1
        #expect(block.components(separatedBy: "\n").count == expected)
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
        let note = ReleaseNote(version: "9.9", summary: "test", highlights: ["test"])
        #expect(note.id == "9.9")
    }

    // MARK: - Storefront

    /// On the China mainland storefront the chat must not repeat
    /// release notes naming a cloud AI provider (App Review,
    /// Guideline 5).
    @Test("Leaves out cloud-provider release notes where none is offered")
    func omitsCloudProvidersWhereNotOffered() {
        let withheld = BonjourChatPromptBuilder.whatsNewBlock(query: "what's new?", offeringCloudProviders: false)
        #expect(!withheld.isEmpty)
        #expect(!withheld.contains("OpenAI"))
        #expect(!withheld.contains("GPT"))
        #expect(!withheld.contains("Claude"))
        #expect(!withheld.contains("Gemini"))
    }

}
