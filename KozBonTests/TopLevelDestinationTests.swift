//
//  TopLevelDestinationTests.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Testing
@testable import KozBon

// MARK: - TopLevelDestinationTests

@Suite("TopLevelDestination")
struct TopLevelDestinationTests {

    // MARK: - id

    @Test func bonjourIdIsBonjour() {
        #expect(TopLevelDestination.bonjour.id == "bonjour")
    }

    @Test func bonjourServiceTypesIdIsBonjourServiceTypes() {
        #expect(TopLevelDestination.bonjourServiceTypes.id == "bonjourServiceTypes")
    }

    @Test func chatIdIsChat() {
        #expect(TopLevelDestination.chat.id == "chat")
    }

    @Test func settingsIdIsSettings() {
        #expect(TopLevelDestination.settings.id == "settings")
    }

    @Test func allIdsAreUnique() {
        let ids = [
            TopLevelDestination.bonjour.id,
            TopLevelDestination.bonjourServiceTypes.id,
            TopLevelDestination.chat.id,
            TopLevelDestination.settings.id,
        ]
        #expect(Set(ids).count == ids.count)
    }

    // MARK: - titleString

    @Test("`bonjour` destination renders as `Discover` (the user-facing tab title)")
    func bonjourTitleIsDiscover() {
        #expect(TopLevelDestination.bonjour.titleString == "Discover")
    }

    @Test("`bonjourServiceTypes` destination renders as `Library` (the user-facing tab title)")
    func bonjourServiceTypesTitleIsLibrary() {
        #expect(TopLevelDestination.bonjourServiceTypes.titleString == "Library")
    }

    @Test func chatTitleIsPlatformSpecific() {
        #if os(macOS) || os(visionOS)
        #expect(TopLevelDestination.chat.titleString == "Explore")
        #else
        #expect(TopLevelDestination.chat.titleString == "Chat")
        #endif
    }

    @Test func settingsTitleIsPreferences() {
        #expect(TopLevelDestination.settings.titleString == "Preferences")
    }

    @Test func allTitlesAreNonEmpty() {
        let destinations: [TopLevelDestination] = [.bonjour, .bonjourServiceTypes, .chat, .settings]
        for destination in destinations {
            #expect(!destination.titleString.isEmpty)
        }
    }
}
