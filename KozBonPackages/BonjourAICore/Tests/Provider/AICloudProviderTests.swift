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

    @Test("`github` round-trips through its raw value")
    func githubRawValueRoundTrip() {
        let provider = AICloudProvider.github
        let restored = AICloudProvider(rawValue: provider.rawValue)
        #expect(restored == provider)
        #expect(provider.rawValue == "github")
    }

    @Test("Every case is enumerated in `allCases`")
    func allCasesContainsAnthropicAndGitHub() {
        #expect(AICloudProvider.allCases.contains(.anthropic))
        #expect(AICloudProvider.allCases.contains(.github))
    }

    @Test("`init(rawValue:)` returns `nil` for unknown identifiers")
    func initRawValueRejectsUnknown() {
        #expect(AICloudProvider(rawValue: "not-a-real-provider") == nil)
    }
}
