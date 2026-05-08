//
//  CustomServiceTypeTests.swift
//  BonjourStorage
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourStorage
import BonjourCore

// MARK: - CustomServiceTypeTests

@Suite("CustomServiceType")
@MainActor
struct CustomServiceTypeTests {

    // MARK: - Helpers

    /// Cleans up all custom service types before each test to ensure a fresh state.
    private func cleanUp() {
        CustomServiceType.deleteAll()
    }

    // MARK: - Create

    @Test("`createOrUpdate` persists name, type, and transport layer onto the new managed object")
    func createSetsProperties() {
        cleanUp()

        let object = CustomServiceType.createOrUpdate(
            name: "HTTP Web Server",
            serviceType: "http",
            transportLayerValue: Int16(TransportLayer.tcp.rawValue)
        )

        #expect(object.name == "HTTP Web Server")
        #expect(object.serviceType == "http")
        #expect(object.transportLayerValue == Int16(TransportLayer.tcp.rawValue))

        cleanUp()
    }

    // MARK: - Create or Update

    @Test("`createOrUpdate` inserts a new row when no matching `(serviceType, transport)` exists")
    func createOrUpdateCreatesNewWhenNotExists() {
        cleanUp()

        _ = CustomServiceType.createOrUpdate(
            name: "HTTP",
            serviceType: "http",
            transportLayerValue: Int16(TransportLayer.tcp.rawValue)
        )

        #expect(CustomServiceType.countAll() == 1)

        cleanUp()
    }

    @Test("`createOrUpdate` mutates the existing row in place rather than creating a duplicate")
    func createOrUpdateUpdatesExisting() {
        cleanUp()

        _ = CustomServiceType.createOrUpdate(
            name: "HTTP",
            serviceType: "http",
            transportLayerValue: Int16(TransportLayer.tcp.rawValue)
        )
        _ = CustomServiceType.createOrUpdate(
            name: "HTTP Updated",
            serviceType: "http",
            transportLayerValue: Int16(TransportLayer.tcp.rawValue)
        )

        #expect(CustomServiceType.countAll() == 1)

        let fetched = CustomServiceType.fetch(
            serviceType: "http",
            transportLayerValue: Int16(TransportLayer.tcp.rawValue)
        )
        #expect(fetched?.name == "HTTP Updated")

        cleanUp()
    }

    // MARK: - Fetch

    @Test("`fetch(serviceType:transportLayerValue:)` returns a previously inserted row")
    func fetchFindsExisting() {
        cleanUp()

        _ = CustomServiceType.createOrUpdate(
            name: "SSH",
            serviceType: "ssh",
            transportLayerValue: Int16(TransportLayer.tcp.rawValue)
        )

        let fetched = CustomServiceType.fetch(
            serviceType: "ssh",
            transportLayerValue: Int16(TransportLayer.tcp.rawValue)
        )

        #expect(fetched != nil)
        #expect(fetched?.name == "SSH")

        cleanUp()
    }

    @Test("`fetch` returns nil for an unknown `(serviceType, transport)` pair")
    func fetchReturnsNilWhenNotFound() {
        cleanUp()

        let fetched = CustomServiceType.fetch(
            serviceType: "nonexistent",
            transportLayerValue: Int16(TransportLayer.tcp.rawValue)
        )

        #expect(fetched == nil)
    }

    // MARK: - Full Type

    @Test("`fullType` for a TCP row formats as `_<service>._tcp` for Bonjour browsing")
    func fullTypeFormatsCorrectly() {
        cleanUp()

        let object = CustomServiceType.createOrUpdate(
            name: "HTTP",
            serviceType: "http",
            transportLayerValue: Int16(TransportLayer.tcp.rawValue)
        )

        #expect(object.fullType == "_http._tcp")

        cleanUp()
    }

    @Test("`fullType` for a UDP row formats as `_<service>._udp` for Bonjour browsing")
    func fullTypeWithUdp() {
        cleanUp()

        let object = CustomServiceType.createOrUpdate(
            name: "DNS",
            serviceType: "dns",
            transportLayerValue: Int16(TransportLayer.udp.rawValue)
        )

        #expect(object.fullType == "_dns._udp")

        cleanUp()
    }

    // MARK: - Delete

    @Test("`deleteOne(_:)` removes the targeted row from the store")
    func deleteOneRemovesObject() {
        cleanUp()

        let object = CustomServiceType.createOrUpdate(
            name: "FTP",
            serviceType: "ftp",
            transportLayerValue: Int16(TransportLayer.tcp.rawValue)
        )

        CustomServiceType.deleteOne(object)

        #expect(CustomServiceType.countAll() == 0)
    }

    @Test("`deleteAll()` purges every row regardless of transport layer")
    func deleteAllRemovesAll() {
        cleanUp()

        _ = CustomServiceType.createOrUpdate(
            name: "HTTP",
            serviceType: "http",
            transportLayerValue: Int16(TransportLayer.tcp.rawValue)
        )
        _ = CustomServiceType.createOrUpdate(
            name: "SSH",
            serviceType: "ssh",
            transportLayerValue: Int16(TransportLayer.tcp.rawValue)
        )
        _ = CustomServiceType.createOrUpdate(
            name: "DNS",
            serviceType: "dns",
            transportLayerValue: Int16(TransportLayer.udp.rawValue)
        )

        CustomServiceType.deleteAll()

        #expect(CustomServiceType.countAll() == 0)
    }

    // MARK: - Count and Fetch All

    @Test("`countAll()` reflects the number of inserted rows")
    func countAllReturnsCorrectCount() {
        cleanUp()

        _ = CustomServiceType.createOrUpdate(
            name: "HTTP",
            serviceType: "http",
            transportLayerValue: Int16(TransportLayer.tcp.rawValue)
        )
        _ = CustomServiceType.createOrUpdate(
            name: "SSH",
            serviceType: "ssh",
            transportLayerValue: Int16(TransportLayer.tcp.rawValue)
        )
        _ = CustomServiceType.createOrUpdate(
            name: "DNS",
            serviceType: "dns",
            transportLayerValue: Int16(TransportLayer.udp.rawValue)
        )

        #expect(CustomServiceType.countAll() == 3)

        cleanUp()
    }

    @Test("`fetchAll()` returns every persisted row across transport layers")
    func fetchAllReturnsAllObjects() {
        cleanUp()

        _ = CustomServiceType.createOrUpdate(
            name: "HTTP",
            serviceType: "http",
            transportLayerValue: Int16(TransportLayer.tcp.rawValue)
        )
        _ = CustomServiceType.createOrUpdate(
            name: "SSH",
            serviceType: "ssh",
            transportLayerValue: Int16(TransportLayer.tcp.rawValue)
        )
        _ = CustomServiceType.createOrUpdate(
            name: "DNS",
            serviceType: "dns",
            transportLayerValue: Int16(TransportLayer.udp.rawValue)
        )

        let all = CustomServiceType.fetchAll()
        #expect(all.count == 3)

        cleanUp()
    }
}
