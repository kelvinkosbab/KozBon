//
//  ConstantsTests.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Testing
@testable import BonjourCore

// MARK: - ConstantsTests

@Suite("Constants")
struct ConstantsTests {

    // MARK: - Network Constants

    @Test func minimumPortIsAboveReservedRange() {
        #expect(Constants.Network.minimumPort > 1024)
    }

    @Test func maximumPortIsValidTCPUDPLimit() {
        #expect(Constants.Network.maximumPort == 65535)
    }

    @Test func minimumPortIsLessThanMaximum() {
        #expect(Constants.Network.minimumPort < Constants.Network.maximumPort)
    }

    @Test func defaultDomainIsLocal() {
        #expect(Constants.Network.defaultDomain == "local.")
    }

    @Test func resolveTimeoutIsPositive() {
        #expect(Constants.Network.resolveTimeout > 0)
    }

    @Test func publishDelayIsPositive() {
        #expect(Constants.Network.publishDelayMilliseconds > 0)
    }

    // MARK: - Refresh Constants

    @Test func foregroundRefreshIntervalIsPositive() {
        #expect(Constants.Refresh.foregroundRefreshInterval > 0)
    }
}
