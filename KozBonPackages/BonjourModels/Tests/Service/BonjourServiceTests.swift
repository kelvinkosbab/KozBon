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

    @Test("Initializer wires up `NetService`, `serviceType`, and the DNS-SD logical identity")
    func initSetsProperties() {
        let service = makeService()
        #expect(service.service.name == "Test Device")
        #expect(service.serviceType.type == "http")
        // The logical identity captures the DNS-SD `(name, type,
        // domain)` tuple at init time so dedup paths can compare
        // services from a `nonisolated` context without crossing
        // the `@MainActor` boundary that protects the underlying
        // `NetService` delegate state.
        #expect(!service.logicalIdentity.isEmpty)
        #expect(service.logicalIdentity.contains("Test Device"))
    }

    @Test("`logicalIdentity` captures the DNS-SD identity tuple at init time")
    func logicalIdentityCapturesDNSSDTuple() {
        let netService = NetService(domain: "local.", type: "_http._tcp", name: "Stable Device", port: 8080)
        let serviceType = BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp)
        let service = BonjourService(service: netService, serviceType: serviceType)
        // Exact format pin — pipe-separated `name|type|domain`,
        // matching the contract `id` and `hash` rely on.
        #expect(service.logicalIdentity == "Stable Device|_http._tcp|local.")
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

    @Test("`Identifiable.id` returns the DNS-SD logical identity for stable list diffing")
    func identifiableIdMatchesLogicalIdentity() {
        let service = makeService()
        #expect(service.id == service.logicalIdentity)
    }

    @Test("`logicalIdentity` is the `name|type|domain` tuple per DNS-SD")
    func logicalIdentityIsNameTypeDomainTuple() {
        // Pin the wire format so dedup paths and any future
        // serialization can rely on it. The pipe separator is a
        // character that can't legally appear in any of the three
        // DNS-SD components, so the composition is unambiguous.
        // The `makeService` helper expects the bare type label
        // ("airplay") and composes the DNS-SD form ("_airplay._tcp")
        // internally via `BonjourServiceType.fullType`.
        let service = makeService(
            name: "Living Room TV",
            type: "airplay",
            domain: "local."
        )
        #expect(service.id == "Living Room TV|_airplay._tcp|local.")
    }

    // MARK: - Equality (DNS-SD Logical Identity)

    @Test("Two services with identical (name, type, domain) compare equal — even with distinct NetService instances")
    func servicesWithSameLogicalIdentityAreEqual() {
        // The whole point of the logical-identity rework: two
        // `BonjourService` wrappers around DIFFERENT `NetService`
        // instances should still compare equal when they wrap the
        // same DNS-SD service tuple. This is what makes
        // `Set<BonjourService>` and the `firstIndex(where:
        // $0.id == new.id)` patterns dedup per-interface and
        // post-restart re-discovery callbacks.
        let a = makeService(name: "Device A")
        let b = makeService(name: "Device A")
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
    }

    @Test("Services differing in name, type, or domain compare unequal")
    func servicesWithDifferentLogicalIdentityAreUnequal() {
        let base = makeService(name: "Device A", type: "_http._tcp.", domain: "local.")
        let differentName = makeService(name: "Device B", type: "_http._tcp.", domain: "local.")
        let differentType = makeService(name: "Device A", type: "_ssh._tcp.", domain: "local.")
        let differentDomain = makeService(name: "Device A", type: "_http._tcp.", domain: "example.local.")
        #expect(base != differentName)
        #expect(base != differentType)
        #expect(base != differentDomain)
    }

    @Test("`Set<BonjourService>` dedups logical duplicates emitted by per-interface re-discovery")
    func setDedupsLogicalDuplicates() {
        // The behavior the `BonjourServiceScanner.services` Set and
        // `BonjourServiceTypeScanner.activeServices` Set rely on:
        // when Bonjour emits the same logical service twice (e.g.,
        // once per network interface), the second insertion
        // collapses into the first.
        let interfaceA = makeService(name: "Apple TV")
        let interfaceB = makeService(name: "Apple TV")
        var set = Set<BonjourService>()
        set.insert(interfaceA)
        set.insert(interfaceB)
        #expect(set.count == 1)
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
