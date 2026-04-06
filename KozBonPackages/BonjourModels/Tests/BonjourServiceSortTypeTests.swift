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

    @Test func allCasesContainsFourOptions() {
        #expect(BonjourServiceSortType.allCases.count == 4)
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

    // MARK: - Titles

    @Test func allTitlesAreNonEmpty() {
        for sortType in BonjourServiceSortType.allCases {
            #expect(!sortType.hostOrServiceTitle.isEmpty)
        }
    }
}
