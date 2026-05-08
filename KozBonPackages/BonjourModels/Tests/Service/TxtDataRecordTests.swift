//
//  TxtDataRecordTests.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Testing
@testable import BonjourModels

// MARK: - TxtDataRecordTests

@Suite("BonjourService.TxtDataRecord")
struct TxtDataRecordTests {

    // MARK: - Equality

    @Test("Equality is keyed on `key` only — value differences don't break equality")
    func recordsWithSameKeyAreEqual() {
        let a = BonjourService.TxtDataRecord(key: "name", value: "hello")
        let b = BonjourService.TxtDataRecord(key: "name", value: "world")
        #expect(a == b)
    }

    @Test("Different keys break equality even when values match")
    func recordsWithDifferentKeysAreNotEqual() {
        let a = BonjourService.TxtDataRecord(key: "name", value: "hello")
        let b = BonjourService.TxtDataRecord(key: "type", value: "hello")
        #expect(a != b)
    }

    // MARK: - Comparable

    @Test("`<` orders records alphabetically by key for deterministic display")
    func recordsSortAlphabeticallyByKey() {
        let a = BonjourService.TxtDataRecord(key: "alpha", value: "1")
        let b = BonjourService.TxtDataRecord(key: "beta", value: "2")
        #expect(a < b)
        #expect(!(b < a))
    }

    @Test("`Array.sorted()` orders records by key, regardless of insertion order")
    func arraySortsByKey() {
        let records = [
            BonjourService.TxtDataRecord(key: "charlie", value: "3"),
            BonjourService.TxtDataRecord(key: "alpha", value: "1"),
            BonjourService.TxtDataRecord(key: "bravo", value: "2")
        ]
        let sorted = records.sorted()
        #expect(sorted[0].key == "alpha")
        #expect(sorted[1].key == "bravo")
        #expect(sorted[2].key == "charlie")
    }
}
