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
/// in the two newest major versions newest-first, shapes the answer
/// by Detail level (two short paragraphs for Basic, a detailed
/// answer for Technical) while staying within the on-device model's
/// token budget, and carries an explicit "answer only from this
/// list" guard so the model can't hallucinate version history.
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
        #expect(block.contains("KOZBON 4.x and 3.x RELEASES"))
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
        let latestRange = block.range(of: "Version \(latest.version) (latest):")
        #expect(latestRange != nil)
        if let second = ReleaseNotes.all.dropFirst().first,
           let latestRange,
           let olderRange = block.range(of: "Version \(second.version):") {
            #expect(latestRange.lowerBound < olderRange.lowerBound)
        }
    }

    @Test("Technical block contains the newest release's actual highlight text")
    func containsRealHighlightText() {
        let block = BonjourChatPromptBuilder.whatsNewBlock(query: "what changed recently?", expertiseLevel: .technical)
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

    @Test("Block covers every release in the two newest major versions", arguments: [
        BonjourServicePromptBuilder.ExpertiseLevel.basic, .technical
    ])
    func coversTwoNewestMajorVersions(_ level: BonjourServicePromptBuilder.ExpertiseLevel) throws {
        let block = BonjourChatPromptBuilder.whatsNewBlock(query: "what's new?", expertiseLevel: level)
        let majors = ReleaseNotes.all.compactMap { $0.version.split(separator: ".").first }
        let newest = try #require(majors.first)
        let previous = try #require(majors.first { $0 != newest })
        for release in ReleaseNotes.all {
            let major = release.version.split(separator: ".").first
            let isRecent = major == newest || major == previous
            #expect(
                block.contains("Version \(release.version)") == isRecent,
                "Version \(release.version) inclusion should match its major version"
            )
        }
    }

    @Test("Releases outside the two newest majors are left out")
    func recentMajorReleasesStopsAtTwoMajors() {
        let releases = BonjourChatPromptBuilder.recentMajorReleases(offeringCloudProviders: true)
        let majors = Set(releases.compactMap { $0.version.split(separator: ".").first })
        #expect(majors.count == 2)
        #expect(releases.map(\.version) == ReleaseNotes.all.filter {
            $0.version.split(separator: ".").first.map { majors.contains($0) } ?? false
        }.map(\.version))
    }

    // MARK: - Detail Level

    @Test("Basic asks for two short paragraphs and sends summaries only")
    func basicUsesTwoParagraphsAndSummaries() throws {
        let block = BonjourChatPromptBuilder.whatsNewBlock(query: "What's new", expertiseLevel: .basic)
        #expect(block.contains("two short paragraphs"))
        #expect(block.contains("4.x, then 3.x"))
        let releases = BonjourChatPromptBuilder.recentMajorReleases(offeringCloudProviders: true)
        for release in releases {
            for highlight in release.highlights where !release.summary.contains(highlight) {
                #expect(!block.contains(highlight), "Basic should omit highlights of \(release.version)")
            }
        }
        let latest = try #require(releases.first)
        let summary = latest.summary.components(separatedBy: "\n\n").joined(separator: " ")
        #expect(block.contains("Version \(latest.version) (latest): \(summary)"))
    }

    @Test("Technical asks for a detailed answer and adds the newest releases' highlights")
    func technicalUsesHighlightsForNewest() throws {
        let block = BonjourChatPromptBuilder.whatsNewBlock(query: "What's new", expertiseLevel: .technical)
        #expect(block.contains("detailed, technical answer"))
        let releases = BonjourChatPromptBuilder.recentMajorReleases(offeringCloudProviders: true)
        let count = BonjourChatPromptBuilder.technicalHighlightCount
        for release in releases.prefix(count) {
            for highlight in release.highlights {
                #expect(block.contains("- \(highlight)"))
            }
        }
        let older = try #require(releases.dropFirst(count).first)
        let summary = older.summary.components(separatedBy: "\n\n").joined(separator: " ")
        #expect(block.contains("Version \(older.version): \(summary)"))
    }

    @Test("Each summarized release renders on its own line", arguments: [
        BonjourServicePromptBuilder.ExpertiseLevel.basic, .technical
    ])
    func oneLinePerRelease(_ level: BonjourServicePromptBuilder.ExpertiseLevel) {
        let block = BonjourChatPromptBuilder.whatsNewBlock(query: "what's new?", expertiseLevel: level)
        let releases = BonjourChatPromptBuilder.recentMajorReleases(offeringCloudProviders: true)
        let detailedCount = level == .technical ? BonjourChatPromptBuilder.technicalHighlightCount : 0
        let highlightLines = releases.prefix(detailedCount).reduce(0) { $0 + $1.highlights.count }
        // Header, answer-shape line, then one line per release plus any highlight bullets.
        #expect(block.components(separatedBy: "\n").count == 2 + releases.count + highlightLines)
    }

    @Test("Chat context carries the Detail level into the user turn")
    @MainActor
    func userTurnUsesContextExpertiseLevel() {
        let technical = BonjourChatPromptBuilder.ChatContext(expertiseLevel: .technical)
        let turn = BonjourChatPromptBuilder.userTurn(
            message: "What's new",
            context: technical,
            isFirstTurn: false,
            contextChanged: false
        )
        #expect(turn.contains("detailed, technical answer"))
        let basicTurn = BonjourChatPromptBuilder.userTurn(
            message: "What's new",
            context: BonjourChatPromptBuilder.ChatContext(),
            isFirstTurn: false,
            contextChanged: false
        )
        #expect(basicTurn.contains("two short paragraphs"))
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
