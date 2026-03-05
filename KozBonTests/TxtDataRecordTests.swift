//
//  TxtDataRecordTests.swift
//  KozBonTests
//
//  Created by Kelvin Kosbab on 3/5/26.
//  Copyright © 2026 Kozinga. All rights reserved.
//

import Testing
@testable import KozBon

// MARK: - TxtDataRecordTests

@Suite("BonjourService.TxtDataRecord")
struct TxtDataRecordTests {

    // MARK: - Equality

    @Test func recordsWithSameKeyAreEqual() {
        let a = BonjourService.TxtDataRecord(key: "name", value: "hello")
        let b = BonjourService.TxtDataRecord(key: "name", value: "world")
        #expect(a == b)
    }

    @Test func recordsWithDifferentKeysAreNotEqual() {
        let a = BonjourService.TxtDataRecord(key: "name", value: "hello")
        let b = BonjourService.TxtDataRecord(key: "type", value: "hello")
        #expect(a != b)
    }

    // MARK: - Comparable

    @Test func recordsSortAlphabeticallyByKey() {
        let a = BonjourService.TxtDataRecord(key: "alpha", value: "1")
        let b = BonjourService.TxtDataRecord(key: "beta", value: "2")
        #expect(a < b)
        #expect(!(b < a))
    }

    @Test func arraySortsByKey() {
        let records = [
            BonjourService.TxtDataRecord(key: "charlie", value: "3"),
            BonjourService.TxtDataRecord(key: "alpha", value: "1"),
            BonjourService.TxtDataRecord(key: "bravo", value: "2"),
        ]
        let sorted = records.sorted()
        #expect(sorted[0].key == "alpha")
        #expect(sorted[1].key == "bravo")
        #expect(sorted[2].key == "charlie")
    }
}
