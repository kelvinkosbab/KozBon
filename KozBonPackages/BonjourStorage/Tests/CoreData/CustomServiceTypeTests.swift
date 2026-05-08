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

/// Pin every operation on the Core Data `CustomServiceType` store —
/// create, read, update, delete, count, and the
/// `fullType` formatter that Bonjour advertises with.
///
/// Each test calls ``skipIfCoreDataUnavailable()`` first. The Core
/// Data model (`iDiscover.xcdatamodeld`) is only compiled to
/// `.momd` when Xcode builds the project — `swift test` from the
/// SPM CLI ships the package without the resolved model, so any
/// access to ``MyCoreDataStack/mainContext`` would fatal-error in
/// the lazy persistent-container initializer. The skip keeps the
/// suite green-but-trivial under `swift test` and
/// green-and-asserting under `xcodebuild test`. Same pattern used
/// by `BonjourChatViewModelIntegrationTests` in `BonjourUI`.
@Suite("CustomServiceType")
@MainActor
struct CustomServiceTypeTests {

    // MARK: - Skip-on-SPM Guard

    /// Returns `true` when the Core Data model is unreachable in
    /// the current test runtime — calling sites should `return`
    /// early to skip Core-Data-dependent assertions. The skip is
    /// silent (the test reports as a pass with no `#expect`
    /// failures) so the SPM CLI run stays green.
    private func skipIfCoreDataUnavailable() -> Bool {
        !MyCoreDataStack.isBundledModelAvailable
    }

    // MARK: - Helpers

    /// Cleans up all custom service types before each test to ensure a fresh state.
    private func cleanUp() {
        CustomServiceType.deleteAll()
    }

    // MARK: - Create

    @Test("`createOrUpdate` persists name, type, and transport layer onto the new managed object")
    func createSetsProperties() {
        if skipIfCoreDataUnavailable() { return }
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
        if skipIfCoreDataUnavailable() { return }
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
        if skipIfCoreDataUnavailable() { return }
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
        if skipIfCoreDataUnavailable() { return }
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
        if skipIfCoreDataUnavailable() { return }
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
        if skipIfCoreDataUnavailable() { return }
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
        if skipIfCoreDataUnavailable() { return }
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
        if skipIfCoreDataUnavailable() { return }
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
        if skipIfCoreDataUnavailable() { return }
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
        if skipIfCoreDataUnavailable() { return }
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
        if skipIfCoreDataUnavailable() { return }
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
