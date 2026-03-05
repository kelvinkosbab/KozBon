//
//  BonjourServiceBrowserStateTests.swift
//  KozBonTests
//
//  Created by Kelvin Kosbab on 3/5/26.
//  Copyright © 2026 Kozinga. All rights reserved.
//

import Testing
@testable import KozBon

// MARK: - BonjourServiceBrowserStateTests

@Suite("BonjourServiceBrowserState")
struct BonjourServiceBrowserStateTests {

    @Test func stoppedStringIsNotEmpty() {
        #expect(!BonjourServiceBrowserState.stopped.string.isEmpty)
    }

    @Test func searchingStringIsNotEmpty() {
        #expect(!BonjourServiceBrowserState.searching.string.isEmpty)
    }

    @Test func stoppedIsStopped() {
        #expect(BonjourServiceBrowserState.stopped.isStopped)
    }

    @Test func stoppedIsNotSearching() {
        #expect(!BonjourServiceBrowserState.stopped.isSearching)
    }

    @Test func searchingIsSearching() {
        #expect(BonjourServiceBrowserState.searching.isSearching)
    }

    @Test func searchingIsNotStopped() {
        #expect(!BonjourServiceBrowserState.searching.isStopped)
    }
}
