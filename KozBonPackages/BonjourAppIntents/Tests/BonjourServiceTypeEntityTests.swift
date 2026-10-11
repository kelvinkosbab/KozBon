//
//  BonjourServiceTypeEntityTests.swift
//  BonjourAppIntents
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Testing
import BonjourCore
import BonjourModels
@testable import BonjourAppIntents

// MARK: - BonjourServiceTypeEntityTests

@Suite("BonjourServiceTypeEntity")
struct BonjourServiceTypeEntityTests {

    private let types = [
        BonjourServiceType(name: "Secure Shell (SSH)", type: "ssh", transportLayer: .tcp),
        BonjourServiceType(name: "AirPlay", type: "airplay", transportLayer: .tcp),
        BonjourServiceType(name: "Remote AirPlay Speaker", type: "raop", transportLayer: .tcp),
        BonjourServiceType(name: "AirPlay Remote", type: "airplay-remote", transportLayer: .tcp),
        BonjourServiceType(name: "Aardvark AirPlay", type: "aardvark", transportLayer: .tcp)
    ]

    @Test("The id is the full type and the name is the library name")
    func projectsServiceType() {
        let entity = BonjourServiceTypeEntity(serviceType: types[0])
        #expect(entity.id == "_ssh._tcp")
        #expect(entity.name == "Secure Shell (SSH)")
    }

    @Test("Exact matches come first, then prefixes, then other matches")
    func ranksMatches() {
        let names = BonjourServiceTypeEntityQuery.matching("airplay", in: types).map(\.name)
        #expect(names == ["AirPlay", "AirPlay Remote", "Aardvark AirPlay", "Remote AirPlay Speaker"])
    }

    @Test("The wire type matches, ignoring case")
    func matchesWireType() {
        #expect(BonjourServiceTypeEntityQuery.matching("SSH", in: types).map(\.type) == ["ssh"])
        #expect(BonjourServiceTypeEntityQuery.matching("_raop._tcp", in: types).map(\.type) == ["raop"])
    }

    @Test("A blank query matches nothing")
    func blankQuery() {
        #expect(BonjourServiceTypeEntityQuery.matching("  ", in: types).isEmpty)
    }
}
