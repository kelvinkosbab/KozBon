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

    @Test("`.stopped.string` is populated so the status row never renders blank")
    func stoppedStringIsNotEmpty() {
        #expect(!BonjourServiceBrowserState.stopped.string.isEmpty)
    }

    @Test("`.searching.string` is populated so the status row never renders blank")
    func searchingStringIsNotEmpty() {
        #expect(!BonjourServiceBrowserState.searching.string.isEmpty)
    }

    @Test("`.stopped.isStopped` is true")
    func stoppedIsStopped() {
        #expect(BonjourServiceBrowserState.stopped.isStopped)
    }

    @Test("`.stopped.isSearching` is false to keep the two predicates mutually exclusive")
    func stoppedIsNotSearching() {
        #expect(!BonjourServiceBrowserState.stopped.isSearching)
    }

    @Test("`.searching.isSearching` is true")
    func searchingIsSearching() {
        #expect(BonjourServiceBrowserState.searching.isSearching)
    }

    @Test("`.searching.isStopped` is false to keep the two predicates mutually exclusive")
    func searchingIsNotStopped() {
        #expect(!BonjourServiceBrowserState.searching.isStopped)
    }
}
