//
//  CustomServiceTypeTests.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourData
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

    @Test func createSetsProperties() {
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

    @Test func createOrUpdateCreatesNewWhenNotExists() {
        cleanUp()

        _ = CustomServiceType.createOrUpdate(
            name: "HTTP",
            serviceType: "http",
            transportLayerValue: Int16(TransportLayer.tcp.rawValue)
        )

        #expect(CustomServiceType.countAll() == 1)

        cleanUp()
    }

    @Test func createOrUpdateUpdatesExisting() {
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

    @Test func fetchFindsExisting() {
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

    @Test func fetchReturnsNilWhenNotFound() {
        cleanUp()

        let fetched = CustomServiceType.fetch(
            serviceType: "nonexistent",
            transportLayerValue: Int16(TransportLayer.tcp.rawValue)
        )

        #expect(fetched == nil)
    }

    // MARK: - Full Type

    @Test func fullTypeFormatsCorrectly() {
        cleanUp()

        let object = CustomServiceType.createOrUpdate(
            name: "HTTP",
            serviceType: "http",
            transportLayerValue: Int16(TransportLayer.tcp.rawValue)
        )

        #expect(object.fullType == "_http._tcp")

        cleanUp()
    }

    @Test func fullTypeWithUdp() {
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

    @Test func deleteOneRemovesObject() {
        cleanUp()

        let object = CustomServiceType.createOrUpdate(
            name: "FTP",
            serviceType: "ftp",
            transportLayerValue: Int16(TransportLayer.tcp.rawValue)
        )

        CustomServiceType.deleteOne(object)

        #expect(CustomServiceType.countAll() == 0)
    }

    @Test func deleteAllRemovesAll() {
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

    @Test func countAllReturnsCorrectCount() {
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

    @Test func fetchAllReturnsAllObjects() {
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
