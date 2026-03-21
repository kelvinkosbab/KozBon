//
//  InternetAddressTests.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Testing
@testable import KozBon

// MARK: - InternetAddressTests

@Suite("InternetAddress")
struct InternetAddressTests {

    // MARK: - ipPortString

    @Test func ipv4PortString() {
        let address = InternetAddress(ip: "192.168.1.1", port: 8080, protocol: .v4)
        #expect(address.ipPortString == "192.168.1.1:8080")
    }

    @Test func ipv6PortString() {
        let address = InternetAddress(ip: "::1", port: 443, protocol: .v6)
        #expect(address.ipPortString == "[::1]:443")
    }

    @Test func ipv4PortZero() {
        let address = InternetAddress(ip: "10.0.0.1", port: 0, protocol: .v4)
        #expect(address.ipPortString == "10.0.0.1:0")
    }

    // MARK: - Equality

    @Test func equalAddressesAreEqual() {
        let a = InternetAddress(ip: "192.168.1.1", port: 80, protocol: .v4)
        let b = InternetAddress(ip: "192.168.1.1", port: 80, protocol: .v4)
        #expect(a == b)
    }

    @Test func differentIPsAreNotEqual() {
        let a = InternetAddress(ip: "192.168.1.1", port: 80, protocol: .v4)
        let b = InternetAddress(ip: "192.168.1.2", port: 80, protocol: .v4)
        #expect(a != b)
    }

    @Test func differentPortsAreNotEqual() {
        let a = InternetAddress(ip: "192.168.1.1", port: 80, protocol: .v4)
        let b = InternetAddress(ip: "192.168.1.1", port: 443, protocol: .v4)
        #expect(a != b)
    }

    @Test func differentProtocolsAreNotEqual() {
        let a = InternetAddress(ip: "::1", port: 80, protocol: .v4)
        let b = InternetAddress(ip: "::1", port: 80, protocol: .v6)
        #expect(a != b)
    }

    // MARK: - Protocol

    @Test func v4StringRepresentation() {
        let address = InternetAddress(ip: "1.1.1.1", port: 80, protocol: .v4)
        #expect(address.protocol.stringRepresentation == "IPv4")
    }

    @Test func v6StringRepresentation() {
        let address = InternetAddress(ip: "::1", port: 80, protocol: .v6)
        #expect(address.protocol.stringRepresentation == "IPv6")
    }
}
