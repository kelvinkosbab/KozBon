//
//  BonjourServiceTests.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourModels
import BonjourCore

// MARK: - BonjourServiceTests

@Suite("BonjourService")
@MainActor
struct BonjourServiceTests {

    // MARK: - Helpers

    private func makeService(
        name: String = "Test Device",
        type: String = "http",
        domain: String = "local.",
        port: Int32 = 8080
    ) -> BonjourService {
        let serviceType = BonjourServiceType(name: "HTTP", type: type, transportLayer: .tcp)
        return BonjourService(
            service: NetService(domain: domain, type: serviceType.fullType, name: name, port: port),
            serviceType: serviceType
        )
    }

    // MARK: - Init

    @Test func initSetsProperties() {
        let service = makeService()
        #expect(service.service.name == "Test Device")
        #expect(service.serviceType.type == "http")
        #expect(service.serviceIdentifier != 0)
    }

    @Test func serviceIdentifierIsStable() {
        let netService = NetService(domain: "local.", type: "_http._tcp", name: "Stable Device", port: 8080)
        let serviceType = BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp)
        let a = BonjourService(service: netService, serviceType: serviceType)
        let expectedId = netService.hashValue
        #expect(a.serviceIdentifier == expectedId)
    }

    // MARK: - Default State

    @Test func hostNameReturnsNAWhenNoHostName() {
        let service = makeService()
        #expect(service.hostName == "NA")
    }

    @Test func hasResolvedAddressesMatchesNetServiceState() {
        let service = makeService()
        // NetService.addresses is non-nil after init with a port, so hasResolvedAddresses reflects that
        #expect(service.hasResolvedAddresses == (service.service.addresses != nil))
    }

    @Test func isResolvingIsFalseInitially() {
        let service = makeService()
        #expect(!service.isResolving)
    }

    @Test func isPublishingIsFalseInitially() {
        let service = makeService()
        #expect(!service.isPublishing)
    }

    @Test func addressesAreEmptyInitially() {
        let service = makeService()
        #expect(service.addresses.isEmpty)
    }

    @Test func dataRecordsAreEmptyInitially() {
        let service = makeService()
        #expect(service.dataRecords.isEmpty)
    }

    // MARK: - Identifiable

    @Test func identifiableIdMatchesServiceIdentifier() {
        let service = makeService()
        #expect(service.id == service.serviceIdentifier)
    }

    // MARK: - Equality

    @Test func equalityBasedOnNSObjectIdentity() {
        let a = makeService(name: "Device A")
        let b = makeService(name: "Device A")
        #expect(a != b)
    }

    // MARK: - Delegate

    @Test func delegateIsWeakReference() {
        let service = makeService()
        var delegate: MockDelegate? = MockDelegate()
        service.delegate = delegate
        #expect(service.delegate != nil)
        delegate = nil
        #expect(service.delegate == nil)
    }
}

// MARK: - MockDelegate

@MainActor
private final class MockDelegate: MyNetServiceDelegate {
    func serviceDidResolveAddress(_ service: BonjourService) {}
}
