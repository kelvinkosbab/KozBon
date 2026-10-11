//
//  AppIntentsBridgeTests.swift
//  BonjourAppIntents
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Testing
@testable import BonjourAppIntents

// MARK: - AppIntentsBridgeTests

@Suite("AppIntentsBridge")
@MainActor
struct AppIntentsBridgeTests {

    @Test("An open request is handed out once")
    func consumesOnce() {
        let bridge = AppIntentsBridge()
        let request = OpenServiceRequest(name: "Living Room", serviceType: "_airplay._tcp")
        bridge.requestOpen(request)

        #expect(bridge.consumeOpenRequest() == request)
        #expect(bridge.consumeOpenRequest() == nil)
        #expect(bridge.pendingOpenRequest == nil)
    }
}
