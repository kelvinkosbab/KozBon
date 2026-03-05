//
//  TransportLayerTests.swift
//  KozBonTests
//
//  Created by Kelvin Kosbab on 3/5/26.
//  Copyright © 2026 Kozinga. All rights reserved.
//

import Testing
@testable import KozBon

// MARK: - TransportLayerTests

@Suite("TransportLayer")
struct TransportLayerTests {

    @Test func udpRawValueIsZero() {
        #expect(TransportLayer.udp.rawValue == 0)
    }

    @Test func tcpRawValueIsOne() {
        #expect(TransportLayer.tcp.rawValue == 1)
    }

    @Test func udpStringIsUdp() {
        #expect(TransportLayer.udp.string == "udp")
    }

    @Test func tcpStringIsTcp() {
        #expect(TransportLayer.tcp.string == "tcp")
    }

    @Test func udpIsUdpReturnsTrue() {
        #expect(TransportLayer.udp.isUdp)
    }

    @Test func udpIsTcpReturnsFalse() {
        #expect(!TransportLayer.udp.isTcp)
    }

    @Test func tcpIsTcpReturnsTrue() {
        #expect(TransportLayer.tcp.isTcp)
    }

    @Test func tcpIsUdpReturnsFalse() {
        #expect(!TransportLayer.tcp.isUdp)
    }

    @Test func caseIterableContainsBothCases() {
        let allCases = TransportLayer.allCases
        #expect(allCases.count == 2)
        #expect(allCases.contains(.udp))
        #expect(allCases.contains(.tcp))
    }
}
