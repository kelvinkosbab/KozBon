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

    @Test("Initializer wires up `NetService`, `serviceType`, and a non-zero `serviceIdentifier`")
    func initSetsProperties() {
        let service = makeService()
        #expect(service.service.name == "Test Device")
        #expect(service.serviceType.type == "http")
        #expect(service.serviceIdentifier != 0)
    }

    @Test("`serviceIdentifier` is cached from `NetService.hashValue` at init for in-session stability")
    func serviceIdentifierIsStable() {
        let netService = NetService(domain: "local.", type: "_http._tcp", name: "Stable Device", port: 8080)
        let serviceType = BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp)
        let a = BonjourService(service: netService, serviceType: serviceType)
        let expectedId = netService.hashValue
        #expect(a.serviceIdentifier == expectedId)
    }

    // MARK: - Default State

    @Test("`hostName` falls back to `NA` when the underlying `NetService` has none yet")
    func hostNameReturnsNAWhenNoHostName() {
        let service = makeService()
        #expect(service.hostName == "NA")
    }

    @Test("`hasResolvedAddresses` mirrors whether `NetService.addresses` is non-nil")
    func hasResolvedAddressesMatchesNetServiceState() {
        let service = makeService()
        // NetService.addresses is non-nil after init with a port, so hasResolvedAddresses reflects that
        #expect(service.hasResolvedAddresses == (service.service.addresses != nil))
    }

    @Test("`isResolving` defaults to false so newly constructed services aren't shown as in-flight")
    func isResolvingIsFalseInitially() {
        let service = makeService()
        #expect(!service.isResolving)
    }

    @Test("`isPublishing` defaults to false so newly constructed services aren't shown as publishing")
    func isPublishingIsFalseInitially() {
        let service = makeService()
        #expect(!service.isPublishing)
    }

    @Test("`addresses` is empty before `resolve()` populates it")
    func addressesAreEmptyInitially() {
        let service = makeService()
        #expect(service.addresses.isEmpty)
    }

    @Test("`dataRecords` is empty before any TXT record update arrives")
    func dataRecordsAreEmptyInitially() {
        let service = makeService()
        #expect(service.dataRecords.isEmpty)
    }

    // MARK: - Identifiable

    @Test("`Identifiable.id` returns the cached `serviceIdentifier` for stable list diffing")
    func identifiableIdMatchesServiceIdentifier() {
        let service = makeService()
        #expect(service.id == service.serviceIdentifier)
    }

    // MARK: - Equality

    @Test("Two services with identical descriptors are not equal — equality uses `NSObject` identity")
    func equalityBasedOnNSObjectIdentity() {
        let a = makeService(name: "Device A")
        let b = makeService(name: "Device A")
        #expect(a != b)
    }

    // MARK: - Delegate

    @Test("`delegate` is weak — releasing the delegate clears it without manual unregistration")
    func delegateIsWeakReference() {
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
