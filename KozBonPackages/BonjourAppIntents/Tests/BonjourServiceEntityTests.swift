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
/// need voice-friendly substitution, and that unresolved values
/// reach Shortcuts as `nil`.
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

    @Test("An unresolved port is `nil`, not 0, so Shortcuts sees no value")
    func unresolvedPortIsNil() {
        let entity = BonjourServiceEntity(from: makeService(port: 0))
        #expect(entity.port == nil)
    }

    @Test("An unresolved hostname is `nil`, not the display sentinel \"NA\"")
    func unresolvedHostnameIsNil() {
        // A NetService built in a test never resolves a host.
        let entity = BonjourServiceEntity(from: makeService())
        #expect(entity.hostname == nil)
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

    @Test("The query finds entities from the latest List result by id")
    func queryFindsRecentEntitiesById() async throws {
        let store = RecentServiceEntities()
        let tv = BonjourServiceEntity(from: makeService(name: "Living Room TV"))
        let printer = BonjourServiceEntity(from: makeService(name: "Office Printer", type: "ipp"))
        await store.replace(with: [tv, printer])

        let query = BonjourServiceEntityQuery(store: store)
        let result = try await query.entities(for: [printer.id])
        #expect(result == [printer])
    }

    @Test("Unknown ids resolve to nothing")
    func queryReturnsEmptyForUnknownIds() async throws {
        let store = RecentServiceEntities()
        await store.replace(with: [BonjourServiceEntity(from: makeService())])

        let query = BonjourServiceEntityQuery(store: store)
        let result = try await query.entities(for: ["not-a-service"])
        #expect(result.isEmpty)
    }

    @Test("Suggestions are the latest List result, and empty before any scan")
    func querySuggestsRecentEntities() async throws {
        let store = RecentServiceEntities()
        let query = BonjourServiceEntityQuery(store: store)
        #expect(try await query.suggestedEntities().isEmpty)

        let entity = BonjourServiceEntity(from: makeService())
        await store.replace(with: [entity])
        #expect(try await query.suggestedEntities() == [entity])
    }
}
