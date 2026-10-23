//
//  ConnectivityRequirementTests.swift
//  InternetConnectivity
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Testing
import InternetConnectivity

// MARK: - ConnectivityRequirementTests

@Suite("ConnectivityRequirement")
struct ConnectivityRequirementTests {

    @Test("On-device work is satisfied whether or not the device is online", arguments: [true, false])
    func noneIsAlwaysSatisfied(isConnected: Bool) {
        #expect(ConnectivityRequirement.none.isSatisfied(isConnected: isConnected))
    }

    @Test("Internet work needs a connection")
    func internetNeedsConnection() {
        #expect(ConnectivityRequirement.internet.isSatisfied(isConnected: true))
        #expect(!ConnectivityRequirement.internet.isSatisfied(isConnected: false))
    }
}
