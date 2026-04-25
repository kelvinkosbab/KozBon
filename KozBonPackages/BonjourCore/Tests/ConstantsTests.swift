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

    @Test("`minimumPort` stays above the IANA well-known range (>1024)")
    func minimumPortIsAboveReservedRange() {
        #expect(Constants.Network.minimumPort > 1024)
    }

    @Test("`maximumPort` is the 16-bit TCP/UDP ceiling (65535)")
    func maximumPortIsValidTCPUDPLimit() {
        #expect(Constants.Network.maximumPort == 65535)
    }

    @Test("`minimumPort` is strictly less than `maximumPort` so the range is non-empty")
    func minimumPortIsLessThanMaximum() {
        #expect(Constants.Network.minimumPort < Constants.Network.maximumPort)
    }

    @Test("`defaultDomain` is the mDNS-standard `local.` domain")
    func defaultDomainIsLocal() {
        #expect(Constants.Network.defaultDomain == "local.")
    }

    @Test("`resolveTimeout` is positive so `NetService.resolve(withTimeout:)` actually waits")
    func resolveTimeoutIsPositive() {
        #expect(Constants.Network.resolveTimeout > 0)
    }

    @Test("`publishDelayMilliseconds` is positive to debounce rapid re-publish requests")
    func publishDelayIsPositive() {
        #expect(Constants.Network.publishDelayMilliseconds > 0)
    }

    // MARK: - Refresh Constants

    @Test("`foregroundRefreshInterval` is positive so the auto-refresh timer makes progress")
    func foregroundRefreshIntervalIsPositive() {
        #expect(Constants.Refresh.foregroundRefreshInterval > 0)
    }
}
