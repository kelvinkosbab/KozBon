//
//  TopLevelDestinationTests.swift
//  KozBonTests
//
//  Created by Kelvin Kosbab on 3/5/26.
//  Copyright © 2026 Kozinga. All rights reserved.
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

    @Test func bluetoothIdIsBluetooth() {
        #expect(TopLevelDestination.bluetooth.id == "bluetooth")
    }

    @Test func allIdsAreUnique() {
        let ids = [
            TopLevelDestination.bonjour.id,
            TopLevelDestination.bonjourServiceTypes.id,
            TopLevelDestination.bluetooth.id,
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

    @Test func bluetoothTitleIsBluetooth() {
        #expect(TopLevelDestination.bluetooth.titleString == "Bluetooth")
    }

    @Test func allTitlesAreNonEmpty() {
        let destinations: [TopLevelDestination] = [.bonjour, .bonjourServiceTypes, .bluetooth]
        for destination in destinations {
            #expect(!destination.titleString.isEmpty)
        }
    }
}
