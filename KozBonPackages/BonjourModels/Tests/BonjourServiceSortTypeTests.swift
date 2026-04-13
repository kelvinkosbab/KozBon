//
//  BonjourServiceSortTypeTests.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Testing
@testable import BonjourModels

// MARK: - BonjourServiceSortTypeTests

@Suite("BonjourServiceSortType")
struct BonjourServiceSortTypeTests {

    // MARK: - CaseIterable

    @Test func allCasesContainsFiveOptions() {
        #expect(BonjourServiceSortType.allCases.count == 5)
    }

    // MARK: - ID

    @Test func allIDsAreUnique() {
        let ids = BonjourServiceSortType.allCases.map(\.id)
        let uniqueIds = Set(ids)
        #expect(ids.count == uniqueIds.count)
    }

    @Test func hostNameAscID() {
        #expect(BonjourServiceSortType.hostNameAsc.id == "hostNameAsc")
    }

    @Test func hostNameDescID() {
        #expect(BonjourServiceSortType.hostNameDesc.id == "hostNameDesc")
    }

    @Test func serviceNameAscID() {
        #expect(BonjourServiceSortType.serviceNameAsc.id == "serviceNameAsc")
    }

    @Test func serviceNameDescID() {
        #expect(BonjourServiceSortType.serviceNameDesc.id == "serviceNameDesc")
    }

    @Test func smartHomeID() {
        #expect(BonjourServiceSortType.smartHome.id == "smartHome")
    }

    @Test func allIDsRoundTripViaLookup() {
        for sortType in BonjourServiceSortType.allCases {
            let found = BonjourServiceSortType.allCases.first { $0.id == sortType.id }
            #expect(found == sortType)
        }
    }

    // MARK: - Titles

    @Test func allTitlesAreNonEmpty() {
        for sortType in BonjourServiceSortType.allCases {
            #expect(!sortType.title.isEmpty)
        }
    }

    // MARK: - Icon Names

    @Test func allIconNamesAreNonEmpty() {
        for sortType in BonjourServiceSortType.allCases {
            #expect(!sortType.iconName.isEmpty)
        }
    }
}
