//
//  TransportLayerTests.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Testing
@testable import BonjourCore

// MARK: - TransportLayerTests

@Suite("TransportLayer")
struct TransportLayerTests {

    @Test("`.udp` raw value is pinned to 0 for stable persistence")
    func udpRawValueIsZero() {
        #expect(TransportLayer.udp.rawValue == 0)
    }

    @Test("`.tcp` raw value is pinned to 1 for stable persistence")
    func tcpRawValueIsOne() {
        #expect(TransportLayer.tcp.rawValue == 1)
    }

    @Test("`.udp.string` matches the Bonjour wire suffix `udp`")
    func udpStringIsUdp() {
        #expect(TransportLayer.udp.string == "udp")
    }

    @Test("`.tcp.string` matches the Bonjour wire suffix `tcp`")
    func tcpStringIsTcp() {
        #expect(TransportLayer.tcp.string == "tcp")
    }

    @Test("`.udp.isUdp` is true")
    func udpIsUdpReturnsTrue() {
        #expect(TransportLayer.udp.isUdp)
    }

    @Test("`.udp.isTcp` is false to avoid cross-classification")
    func udpIsTcpReturnsFalse() {
        #expect(!TransportLayer.udp.isTcp)
    }

    @Test("`.tcp.isTcp` is true")
    func tcpIsTcpReturnsTrue() {
        #expect(TransportLayer.tcp.isTcp)
    }

    @Test("`.tcp.isUdp` is false to avoid cross-classification")
    func tcpIsUdpReturnsFalse() {
        #expect(!TransportLayer.tcp.isUdp)
    }

    @Test("`allCases` exposes exactly `.udp` and `.tcp` so UI menus stay complete")
    func caseIterableContainsBothCases() {
        let allCases = TransportLayer.allCases
        #expect(allCases.count == 2)
        #expect(allCases.contains(.udp))
        #expect(allCases.contains(.tcp))
    }
}
