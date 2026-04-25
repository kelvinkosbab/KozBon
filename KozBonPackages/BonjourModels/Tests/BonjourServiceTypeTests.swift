//
//  BonjourServiceTypeTests.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Testing
import BonjourCore
@testable import BonjourModels

// MARK: - BonjourServiceTypeTests

@Suite("BonjourServiceType")
@MainActor
struct BonjourServiceTypeTests {

    // MARK: - generateFullType

    @Test("`generateFullType` formats a TCP type as `_<type>._tcp`")
    func generateFullTypeWithTcp() {
        let fullType = BonjourServiceType.generateFullType(type: "http", transportLayer: .tcp)
        #expect(fullType == "_http._tcp")
    }

    @Test("`generateFullType` formats a UDP type as `_<type>._udp`")
    func generateFullTypeWithUdp() {
        let fullType = BonjourServiceType.generateFullType(type: "dns", transportLayer: .udp)
        #expect(fullType == "_dns._udp")
    }

    // MARK: - Init

    @Test("Initializer derives `fullType` from the `(type, transportLayer)` pair")
    func initSetsFullType() {
        let serviceType = BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp)
        #expect(serviceType.fullType == "_http._tcp")
    }

    @Test("Initializer stores name, type, transport, and detail unchanged")
    func initSetsAllProperties() {
        let serviceType = BonjourServiceType(
            name: "HTTP",
            type: "http",
            transportLayer: .tcp,
            detail: "Web server"
        )
        #expect(serviceType.name == "HTTP")
        #expect(serviceType.type == "http")
        #expect(serviceType.transportLayer == .tcp)
        #expect(serviceType.detail == "Web server")
    }

    @Test("`detail` defaults to nil when not supplied to the initializer")
    func initDetailDefaultsToNil() {
        let serviceType = BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp)
        #expect(serviceType.detail == nil)
    }

    // MARK: - Equality

    @Test("Two service types with all fields equal compare equal")
    func equalServiceTypesAreEqual() {
        let a = BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp, detail: "Web")
        let b = BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp, detail: "Web")
        #expect(a == b)
    }

    @Test("Differing display name breaks equality")
    func differentNamesAreNotEqual() {
        let a = BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp)
        let b = BonjourServiceType(name: "HTTPS", type: "http", transportLayer: .tcp)
        #expect(a != b)
    }

    @Test("Differing wire type breaks equality")
    func differentTypesAreNotEqual() {
        let a = BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp)
        let b = BonjourServiceType(name: "HTTP", type: "https", transportLayer: .tcp)
        #expect(a != b)
    }

    @Test("Differing `detail` text breaks equality")
    func differentDetailsAreNotEqual() {
        let a = BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp, detail: "Web")
        let b = BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp, detail: "Other")
        #expect(a != b)
    }

    // MARK: - Hashing

    @Test("Hash is keyed on `fullType` only — two values sharing it collide regardless of name")
    func sameFullTypeProducesSameHash() {
        let a = BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp)
        let b = BonjourServiceType(name: "Different", type: "http", transportLayer: .tcp)
        #expect(a.hashValue == b.hashValue)
    }

    @Test("Different `fullType` values hash to different buckets")
    func differentFullTypeProducesDifferentHash() {
        let a = BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp)
        let b = BonjourServiceType(name: "DNS", type: "dns", transportLayer: .udp)
        #expect(a.hashValue != b.hashValue)
    }

    @Test("Equal instances dedupe inside `Set`, confirming `Hashable` matches `Equatable`")
    func canBeUsedInSet() {
        let a = BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp)
        let b = BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp)
        let set: Set<BonjourServiceType> = [a, b]
        // Equal instances should be deduplicated in a set
        #expect(set.count == 1)
    }

    // MARK: - fetch (with explicit serviceTypes array)

    @Test("`fetch(serviceTypes:type:transportLayer:)` returns the matching entry")
    func fetchByTypeAndTransportLayer() {
        let types = [
            BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp),
            BonjourServiceType(name: "DNS", type: "dns", transportLayer: .udp)
        ]
        let result = BonjourServiceType.fetch(serviceTypes: types, type: "http", transportLayer: .tcp)
        #expect(result != nil)
        #expect(result?.name == "HTTP")
    }

    @Test("`fetch(serviceTypes:type:transportLayer:)` returns nil when no entry matches")
    func fetchByTypeAndTransportLayerNotFound() {
        let types = [
            BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp)
        ]
        let result = BonjourServiceType.fetch(serviceTypes: types, type: "ssh", transportLayer: .tcp)
        #expect(result == nil)
    }

    @Test("`fetch(serviceTypes:fullType:)` looks up by the wire-format string")
    func fetchByFullType() {
        let types = [
            BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp),
            BonjourServiceType(name: "DNS", type: "dns", transportLayer: .udp)
        ]
        let result = BonjourServiceType.fetch(serviceTypes: types, fullType: "_dns._udp")
        #expect(result != nil)
        #expect(result?.name == "DNS")
    }

    @Test("`fetch(serviceTypes:fullType:)` returns nil when no entry matches")
    func fetchByFullTypeNotFound() {
        let types = [
            BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp)
        ]
        let result = BonjourServiceType.fetch(serviceTypes: types, fullType: "_ssh._tcp")
        #expect(result == nil)
    }

    // MARK: - exists (with explicit serviceTypes array)

    @Test("`exists(serviceTypes:type:transportLayer:)` is true when a match is in the array")
    func existsReturnsTrueWhenFound() {
        let types = [
            BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp)
        ]
        #expect(BonjourServiceType.exists(serviceTypes: types, type: "http", transportLayer: .tcp))
    }

    @Test("`exists(serviceTypes:type:transportLayer:)` is false when no match is in the array")
    func existsReturnsFalseWhenNotFound() {
        let types = [
            BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp)
        ]
        #expect(!BonjourServiceType.exists(serviceTypes: types, type: "ssh", transportLayer: .tcp))
    }

    @Test("`exists(serviceTypes:fullType:)` matches via the wire-format string")
    func existsByFullType() {
        let types = [
            BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp)
        ]
        #expect(BonjourServiceType.exists(serviceTypes: types, fullType: "_http._tcp"))
    }

    // MARK: - isBuiltIn

    @Test("Built-in HTTP/TCP entry is present in `serviceTypeLibrary`")
    func builtInServiceTypeIsRecognized() {
        // Check that the library contains a service type with type "http" and transportLayer .tcp
        let library = BonjourServiceType.serviceTypeLibrary
        let httpExists = library.contains { $0.type == "http" && $0.transportLayer == .tcp }
        #expect(httpExists)
    }

    @Test("A user-defined service type reports `isBuiltIn == false`")
    func customServiceTypeIsNotBuiltIn() {
        let custom = BonjourServiceType(name: "My Custom Service", type: "mycustom", transportLayer: .tcp)
        #expect(!custom.isBuiltIn)
    }

    // MARK: - serviceTypeLibrary

    @Test("`serviceTypeLibrary` is non-empty so the discover tab always has content")
    func serviceTypeLibraryIsNotEmpty() {
        #expect(!BonjourServiceType.serviceTypeLibrary.isEmpty)
    }

    // MARK: - imageSystemName

    @Test("AirPlay maps to the `airplayvideo` SF Symbol")
    func airplayImageIsAirplayVideo() {
        let type = BonjourServiceType(name: "AirPlay", type: "airplay", transportLayer: .tcp)
        #expect(type.imageSystemName == "airplayvideo")
    }

    @Test("SSH maps to the `greaterthan.square` SF Symbol")
    func sshImageIsGreaterThanSquare() {
        let type = BonjourServiceType(name: "Secure Shell (SSH)", type: "ssh", transportLayer: .tcp)
        #expect(type.imageSystemName == "greaterthan.square")
    }

    @Test("Unrecognized service types fall back to the `wifi` SF Symbol")
    func unknownServiceDefaultsToWifi() {
        let type = BonjourServiceType(name: "Unknown Service", type: "unknown", transportLayer: .tcp)
        #expect(type.imageSystemName == "wifi")
    }

    @Test("HomeKit maps to the `homekit` SF Symbol")
    func homekitImageIsHomekit() {
        let type = BonjourServiceType(name: "Apple HomeKit", type: "homekit", transportLayer: .tcp)
        #expect(type.imageSystemName == "homekit")
    }

    // MARK: - Identifiable

    @Test("`Identifiable.id` returns the `fullType` string for stable list diffing")
    func idEqualsFullType() {
        let type = BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp)
        #expect(type.id == "_http._tcp")
        #expect(type.id == type.fullType)
    }

    @Test("Same type name on TCP vs UDP yields distinct `id`s so both can coexist in a list")
    func idIsUniqueAcrossTransportLayers() {
        let tcp = BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp)
        let udp = BonjourServiceType(name: "HTTP", type: "http", transportLayer: .udp)
        #expect(tcp.id != udp.id)
    }

    // MARK: - Localized Detail

    @Test("`localizedDetail` is non-nil whenever a `detail` string was supplied")
    func localizedDetailReturnsDetailWhenPresent() {
        let type = BonjourServiceType(
            name: "HTTP", type: "http", transportLayer: .tcp, detail: "Web server"
        )
        #expect(type.localizedDetail != nil)
    }

    @Test("`localizedDetail` is nil when no underlying `detail` string was supplied")
    func localizedDetailReturnsNilWhenNoDetail() {
        let type = BonjourServiceType(
            name: "Custom", type: "custom", transportLayer: .tcp, detail: nil
        )
        #expect(type.localizedDetail == nil)
    }

    // MARK: - isBuiltIn (via Identifiable)

    @Test("Library-shipped TCP service types report `isBuiltIn == true`")
    func builtInServiceTypeReportsIsBuiltIn() {
        let builtIn = BonjourServiceType.tcpServiceTypes.first
        #expect(builtIn?.isBuiltIn == true)
    }

    @Test("Service type whose `fullType` isn't in the library reports `isBuiltIn == false`")
    func unknownServiceTypeIsNotBuiltIn() {
        let custom = BonjourServiceType(
            name: "My Service", type: "myservice", transportLayer: .tcp
        )
        #expect(!custom.isBuiltIn)
    }
}
