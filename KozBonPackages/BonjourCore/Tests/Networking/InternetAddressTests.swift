//
//  InternetAddressTests.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Testing
@testable import BonjourCore

// MARK: - InternetAddressTests

@Suite("InternetAddress")
struct InternetAddressTests {

    // MARK: - ipPortString

    @Test("IPv4 `ipPortString` uses bare `host:port` form")
    func ipv4PortString() {
        let address = InternetAddress(ip: "192.168.1.1", port: 8080, protocol: .v4)
        #expect(address.ipPortString == "192.168.1.1:8080")
    }

    @Test("IPv6 `ipPortString` brackets the host to disambiguate from the port colon")
    func ipv6PortString() {
        let address = InternetAddress(ip: "::1", port: 443, protocol: .v6)
        #expect(address.ipPortString == "[::1]:443")
    }

    @Test("Port 0 still renders into `ipPortString` rather than being elided")
    func ipv4PortZero() {
        let address = InternetAddress(ip: "10.0.0.1", port: 0, protocol: .v4)
        #expect(address.ipPortString == "10.0.0.1:0")
    }

    // MARK: - Equality

    @Test("Two addresses with identical IP, port, and protocol compare equal")
    func equalAddressesAreEqual() {
        let a = InternetAddress(ip: "192.168.1.1", port: 80, protocol: .v4)
        let b = InternetAddress(ip: "192.168.1.1", port: 80, protocol: .v4)
        #expect(a == b)
    }

    @Test("Different IPs break equality even when port and protocol match")
    func differentIPsAreNotEqual() {
        let a = InternetAddress(ip: "192.168.1.1", port: 80, protocol: .v4)
        let b = InternetAddress(ip: "192.168.1.2", port: 80, protocol: .v4)
        #expect(a != b)
    }

    @Test("Different ports break equality even when IP and protocol match")
    func differentPortsAreNotEqual() {
        let a = InternetAddress(ip: "192.168.1.1", port: 80, protocol: .v4)
        let b = InternetAddress(ip: "192.168.1.1", port: 443, protocol: .v4)
        #expect(a != b)
    }

    @Test("IPv4 vs IPv6 are not equal even with identical IP/port — protocol participates in equality")
    func differentProtocolsAreNotEqual() {
        let a = InternetAddress(ip: "::1", port: 80, protocol: .v4)
        let b = InternetAddress(ip: "::1", port: 80, protocol: .v6)
        #expect(a != b)
    }

    // MARK: - Protocol

    @Test("`.v4.stringRepresentation` is the user-facing `IPv4` label")
    func v4StringRepresentation() {
        let address = InternetAddress(ip: "1.1.1.1", port: 80, protocol: .v4)
        #expect(address.protocol.stringRepresentation == "IPv4")
    }

    @Test("`.v6.stringRepresentation` is the user-facing `IPv6` label")
    func v6StringRepresentation() {
        let address = InternetAddress(ip: "::1", port: 80, protocol: .v6)
        #expect(address.protocol.stringRepresentation == "IPv6")
    }
}
