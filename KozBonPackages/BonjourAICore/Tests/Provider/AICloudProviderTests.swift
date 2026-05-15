//
//  AICloudProviderTests.swift
//  BonjourAICore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Testing
@testable import BonjourAICore

// MARK: - AICloudProviderTests

@Suite("AICloudProvider")
struct AICloudProviderTests {

    @Test("`anthropic` round-trips through its raw value")
    func anthropicRawValueRoundTrip() {
        let provider = AICloudProvider.anthropic
        let restored = AICloudProvider(rawValue: provider.rawValue)
        #expect(restored == provider)
    }

    @Test("Every case is enumerated in `allCases`")
    func allCasesContainsAnthropic() {
        #expect(AICloudProvider.allCases.contains(.anthropic))
    }

    @Test("`init(rawValue:)` returns `nil` for unknown identifiers")
    func initRawValueRejectsUnknown() {
        #expect(AICloudProvider(rawValue: "not-a-real-provider") == nil)
    }
}
