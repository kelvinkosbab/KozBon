//
//  BonjourServiceEntityTests.swift
//  BonjourAppIntents
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourCore
import BonjourModels
@testable import BonjourAppIntents

// MARK: - BonjourServiceEntityTests

/// Pin the projection from runtime ``BonjourService`` to the
/// `Sendable` ``BonjourServiceEntity`` value type that crosses
/// the App Intents boundary into Shortcuts.
///
/// `BonjourService` is `@MainActor`-isolated and holds a
/// non-`Sendable` `NetService`. The entity init captures the
/// fields a Shortcuts user actually consumes — name, voice
/// name, service type (wire + display), hostname, port — so
/// the result travels safely. These tests pin that the
/// capture is faithful for both user-given names ("Living
/// Room TV") and auto-generated hostname-style names that
/// need voice-friendly substitution.
@Suite("BonjourServiceEntity")
@MainActor
struct BonjourServiceEntityTests {

    // MARK: - Helpers

    private func makeService(
        name: String = "Living Room TV",
        type: String = "airplay",
        port: Int = 7000
    ) -> BonjourService {
        BonjourService(
            service: NetService(
                domain: Constants.Network.defaultDomain,
                type: "_\(type)._tcp",
                name: name,
                port: Int32(port)
            ),
            serviceType: BonjourServiceType(
                name: "AirPlay",
                type: type,
                transportLayer: .tcp,
                detail: "Apple AirPlay"
            )
        )
    }

    // MARK: - Initialization

    @Test("`init(from:)` captures the user-facing service name verbatim")
    func capturesServiceName() {
        let entity = BonjourServiceEntity(from: makeService(name: "Living Room TV"))
        #expect(entity.name == "Living Room TV")
    }

    @Test("`init(from:)` projects port from `Int32` to `Int`")
    func projectsPort() {
        let entity = BonjourServiceEntity(from: makeService(port: 8080))
        #expect(entity.port == 8080)
    }

    @Test("`init(from:)` captures the wire `_<type>._tcp` form for Shortcuts pipelines")
    func capturesWireServiceType() {
        let entity = BonjourServiceEntity(from: makeService(type: "airplay"))
        #expect(entity.serviceType == "_airplay._tcp")
    }

    @Test("`init(from:)` captures the friendly type display name for Siri voice playback")
    func capturesServiceTypeDisplayName() {
        // The friendly form ("AirPlay") is what gets read aloud
        // when a Shortcut pipes the entity into "Speak Text".
        // The wire form would be unintelligible.
        let entity = BonjourServiceEntity(from: makeService())
        #expect(entity.serviceTypeDisplayName == "AirPlay")
    }

    @Test("`init(from:)` projects `BonjourService.id` (Int) to a stable String identifier")
    func projectsIdToString() {
        let service = makeService()
        let entity = BonjourServiceEntity(from: service)
        #expect(entity.id == String(service.id))
    }

    @Test("Two entities from the same service are equal (Hashable conformance honors id)")
    func sameServiceHashesEqual() {
        let service = makeService()
        let a = BonjourServiceEntity(from: service)
        let b = BonjourServiceEntity(from: service)
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
    }

    // MARK: - EntityQuery

    @Test("`BonjourServiceEntityQuery.entities(for:)` returns empty (Bonjour discoveries don't persist)")
    func queryEntitiesIsEmpty() async throws {
        let query = BonjourServiceEntityQuery()
        let result = try await query.entities(for: ["any-id"])
        #expect(result.isEmpty)
    }

    @Test("`BonjourServiceEntityQuery.suggestedEntities()` returns empty")
    func querySuggestedIsEmpty() async throws {
        let query = BonjourServiceEntityQuery()
        let result = try await query.suggestedEntities()
        #expect(result.isEmpty)
    }
}
