//
//  BonjourServiceSortTypeSortedTests.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import KozBon

// MARK: - BonjourServiceSortTypeSortedTests

@Suite("BonjourServiceSortType.sorted")
@MainActor
struct BonjourServiceSortTypeSortedTests {

    // MARK: - Helpers

    private func makeService(name: String, typeName: String, type: String) -> BonjourService {
        let serviceType = BonjourServiceType(name: typeName, type: type, transportLayer: .tcp)
        return BonjourService(
            service: NetService(domain: "local.", type: serviceType.fullType, name: name, port: 8080),
            serviceType: serviceType
        )
    }

    private var sampleServices: [BonjourService] {
        [
            makeService(name: "Charlie", typeName: "SSH", type: "ssh"),
            makeService(name: "Alpha", typeName: "HTTP", type: "http"),
            makeService(name: "Bravo", typeName: "AFP", type: "afpovertcp")
        ]
    }

    // MARK: - Host Name Sorting

    @Test func hostNameAscSortsByNameAscending() {
        let sorted = BonjourServiceSortType.hostNameAsc.sorted(sampleServices)
        let names = sorted.map(\.service.name)
        #expect(names == ["Alpha", "Bravo", "Charlie"])
    }

    @Test func hostNameDescSortsByNameDescending() {
        let sorted = BonjourServiceSortType.hostNameDesc.sorted(sampleServices)
        let names = sorted.map(\.service.name)
        #expect(names == ["Charlie", "Bravo", "Alpha"])
    }

    // MARK: - Service Type Name Sorting

    @Test func serviceNameAscSortsByTypeNameAscending() {
        let sorted = BonjourServiceSortType.serviceNameAsc.sorted(sampleServices)
        let typeNames = sorted.map(\.serviceType.name)
        #expect(typeNames == ["AFP", "HTTP", "SSH"])
    }

    @Test func serviceNameDescSortsByTypeNameDescending() {
        let sorted = BonjourServiceSortType.serviceNameDesc.sorted(sampleServices)
        let typeNames = sorted.map(\.serviceType.name)
        #expect(typeNames == ["SSH", "HTTP", "AFP"])
    }

    // MARK: - Edge Cases

    @Test func sortingEmptyArrayReturnsEmpty() {
        let sorted = BonjourServiceSortType.hostNameAsc.sorted([])
        #expect(sorted.isEmpty)
    }

    @Test func sortingSingleElementReturnsSame() {
        let service = makeService(name: "Only", typeName: "HTTP", type: "http")
        let sorted = BonjourServiceSortType.hostNameAsc.sorted([service])
        #expect(sorted.count == 1)
        #expect(sorted.first?.service.name == "Only")
    }
}
