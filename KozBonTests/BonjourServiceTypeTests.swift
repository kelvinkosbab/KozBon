//
//  BonjourServiceTypeTests.swift
//  KozBonTests
//
//  Created by Kelvin Kosbab on 3/5/26.
//  Copyright © 2026 Kozinga. All rights reserved.
//

import Testing
@testable import KozBon

// MARK: - BonjourServiceTypeTests

@Suite("BonjourServiceType")
@MainActor
struct BonjourServiceTypeTests {

    // MARK: - generateFullType

    @Test func generateFullTypeWithTcp() {
        let fullType = BonjourServiceType.generateFullType(type: "http", transportLayer: .tcp)
        #expect(fullType == "_http._tcp")
    }

    @Test func generateFullTypeWithUdp() {
        let fullType = BonjourServiceType.generateFullType(type: "dns", transportLayer: .udp)
        #expect(fullType == "_dns._udp")
    }

    // MARK: - Init

    @Test func initSetsFullType() {
        let serviceType = BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp)
        #expect(serviceType.fullType == "_http._tcp")
    }

    @Test func initSetsAllProperties() {
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

    @Test func initDetailDefaultsToNil() {
        let serviceType = BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp)
        #expect(serviceType.detail == nil)
    }

    // MARK: - Equality

    @Test func equalServiceTypesAreEqual() {
        let a = BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp, detail: "Web")
        let b = BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp, detail: "Web")
        #expect(a == b)
    }

    @Test func differentNamesAreNotEqual() {
        let a = BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp)
        let b = BonjourServiceType(name: "HTTPS", type: "http", transportLayer: .tcp)
        #expect(a != b)
    }

    @Test func differentTypesAreNotEqual() {
        let a = BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp)
        let b = BonjourServiceType(name: "HTTP", type: "https", transportLayer: .tcp)
        #expect(a != b)
    }

    @Test func differentDetailsAreNotEqual() {
        let a = BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp, detail: "Web")
        let b = BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp, detail: "Other")
        #expect(a != b)
    }

    // MARK: - Hashing

    @Test func sameFullTypeProducesSameHash() {
        let a = BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp)
        let b = BonjourServiceType(name: "Different", type: "http", transportLayer: .tcp)
        #expect(a.hashValue == b.hashValue)
    }

    @Test func differentFullTypeProducesDifferentHash() {
        let a = BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp)
        let b = BonjourServiceType(name: "DNS", type: "dns", transportLayer: .udp)
        #expect(a.hashValue != b.hashValue)
    }

    @Test func canBeUsedInSet() {
        let a = BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp)
        let b = BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp)
        let set: Set<BonjourServiceType> = [a, b]
        // Equal instances should be deduplicated in a set
        #expect(set.count == 1)
    }

    // MARK: - fetch (with explicit serviceTypes array)

    @Test func fetchByTypeAndTransportLayer() {
        let types = [
            BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp),
            BonjourServiceType(name: "DNS", type: "dns", transportLayer: .udp),
        ]
        let result = BonjourServiceType.fetch(serviceTypes: types, type: "http", transportLayer: .tcp)
        #expect(result != nil)
        #expect(result?.name == "HTTP")
    }

    @Test func fetchByTypeAndTransportLayerNotFound() {
        let types = [
            BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp),
        ]
        let result = BonjourServiceType.fetch(serviceTypes: types, type: "ssh", transportLayer: .tcp)
        #expect(result == nil)
    }

    @Test func fetchByFullType() {
        let types = [
            BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp),
            BonjourServiceType(name: "DNS", type: "dns", transportLayer: .udp),
        ]
        let result = BonjourServiceType.fetch(serviceTypes: types, fullType: "_dns._udp")
        #expect(result != nil)
        #expect(result?.name == "DNS")
    }

    @Test func fetchByFullTypeNotFound() {
        let types = [
            BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp),
        ]
        let result = BonjourServiceType.fetch(serviceTypes: types, fullType: "_ssh._tcp")
        #expect(result == nil)
    }

    // MARK: - exists (with explicit serviceTypes array)

    @Test func existsReturnsTrueWhenFound() {
        let types = [
            BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp),
        ]
        #expect(BonjourServiceType.exists(serviceTypes: types, type: "http", transportLayer: .tcp))
    }

    @Test func existsReturnsFalseWhenNotFound() {
        let types = [
            BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp),
        ]
        #expect(!BonjourServiceType.exists(serviceTypes: types, type: "ssh", transportLayer: .tcp))
    }

    @Test func existsByFullType() {
        let types = [
            BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp),
        ]
        #expect(BonjourServiceType.exists(serviceTypes: types, fullType: "_http._tcp"))
    }

    // MARK: - isBuiltIn

    @Test func builtInServiceTypeIsRecognized() {
        // Check that the library contains a service type with type "http" and transportLayer .tcp
        let library = BonjourServiceType.serviceTypeLibrary
        let httpExists = library.contains { $0.type == "http" && $0.transportLayer == .tcp }
        #expect(httpExists)
    }

    @Test func customServiceTypeIsNotBuiltIn() {
        let custom = BonjourServiceType(name: "My Custom Service", type: "mycustom", transportLayer: .tcp)
        #expect(!custom.isBuiltIn)
    }

    // MARK: - serviceTypeLibrary

    @Test func serviceTypeLibraryIsNotEmpty() {
        #expect(!BonjourServiceType.serviceTypeLibrary.isEmpty)
    }

    // MARK: - imageSystemName

    @Test func airplayImageIsAirplayVideo() {
        let type = BonjourServiceType(name: "AirPlay", type: "airplay", transportLayer: .tcp)
        #expect(type.imageSystemName == "airplayvideo")
    }

    @Test func sshImageIsGreaterThanSquare() {
        let type = BonjourServiceType(name: "Secure Shell (SSH)", type: "ssh", transportLayer: .tcp)
        #expect(type.imageSystemName == "greaterthan.square")
    }

    @Test func unknownServiceDefaultsToWifi() {
        let type = BonjourServiceType(name: "Unknown Service", type: "unknown", transportLayer: .tcp)
        #expect(type.imageSystemName == "wifi")
    }

    @Test func homekitImageIsHomekit() {
        let type = BonjourServiceType(name: "Apple HomeKit", type: "homekit", transportLayer: .tcp)
        #expect(type.imageSystemName == "homekit")
    }
}
