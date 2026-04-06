//
//  BonjourServiceBrowserStateTests.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Testing
@testable import BonjourCore

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
