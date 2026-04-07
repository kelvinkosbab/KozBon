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

    @Test func allIdsAreUnique() {
        let ids = [
            TopLevelDestination.bonjour.id,
            TopLevelDestination.bonjourServiceTypes.id,
        ]
        #expect(Set(ids).count == ids.count)
    }

    // MARK: - titleString

    @Test func bonjourTitleIsBonjour() {
        #expect(TopLevelDestination.bonjour.titleString == "Bonjour")
    }

    @Test func bonjourServiceTypesTitleIsSupportedServices() {
        #expect(TopLevelDestination.bonjourServiceTypes.titleString == "Supported services")
    }

    @Test func allTitlesAreNonEmpty() {
        let destinations: [TopLevelDestination] = [.bonjour, .bonjourServiceTypes]
        for destination in destinations {
            #expect(!destination.titleString.isEmpty)
        }
    }
}
