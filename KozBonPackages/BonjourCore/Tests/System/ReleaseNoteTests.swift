//
//  ReleaseNoteTests.swift
//  BonjourCore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Testing
import Foundation
@testable import BonjourCore

// MARK: - ReleaseNotesTests

/// `ReleaseNotes.all` is hand-curated on every release and read by
/// two unrelated surfaces — the Settings → About → What's New page
/// and the chat assistant's prompt builder. These pin the shape both
/// consumers assume, since a malformed entry shows up as a blank row
/// for users or as a confused answer from the assistant.
@Suite("ReleaseNotes")
struct ReleaseNotesTests {

    /// `WhatsNewView` renders `all` in order without sorting, and
    /// `ReleaseNote.id` is the version — so a duplicate version
    /// collapses two releases into one row in the list.
    @Test("Versions are unique")
    func versionsAreUnique() {
        let versions = ReleaseNotes.all.map(\.version)

        #expect(Set(versions).count == versions.count)
    }

    /// The view builds a `Section` per release, so an empty
    /// highlights array renders a header with nothing under it.
    @Test("Every release has at least one non-blank highlight")
    func everyReleaseHasHighlights() {
        for release in ReleaseNotes.all {
            #expect(!release.highlights.isEmpty, "\(release.version) has no highlights")
            #expect(
                release.highlights.allSatisfy { !$0.trimmingCharacters(in: .whitespaces).isEmpty },
                "\(release.version) has a blank highlight"
            )
        }
    }

    /// Both consumers present the list as-is and describe it as
    /// newest-first: the page reads top-down and the prompt builder
    /// tells the model the first entry is the current release.
    @Test("Releases are ordered newest-first")
    func releasesAreNewestFirst() {
        let versions = ReleaseNotes.all.map(\.version)
        let sorted = versions.sorted { lhs, rhs in
            lhs.compare(rhs, options: .numeric) == .orderedDescending
        }

        #expect(versions == sorted)
    }

    /// The assistant answers "what's new?" from the first entry, so
    /// an entry prepended out of order would have the model describe
    /// an older version's changes as the current ones.
    ///
    /// Deliberately not pinned to a literal version — that would
    /// need editing on every release, and `MARKETING_VERSION` is
    /// bumped in the Xcode project rather than here.
    @Test("The newest entry is the highest version in the list")
    func newestEntryIsHighestVersion() throws {
        let newest = try #require(ReleaseNotes.all.first)
        let highest = try #require(
            ReleaseNotes.all.map(\.version).max { lhs, rhs in
                lhs.compare(rhs, options: .numeric) == .orderedAscending
            }
        )

        #expect(newest.version == highest)
    }

    /// `ReleaseNote.id` is the version string rather than a separate
    /// uuid, which is what lets `ForEach` keep row identity stable
    /// across launches.
    @Test("Identity is the version string")
    func identityIsTheVersion() throws {
        let newest = try #require(ReleaseNotes.all.first)

        #expect(newest.id == newest.version)
    }
}
