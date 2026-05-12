//
//  AnthropicModelTests.swift
//  BonjourAICloud
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Testing
@testable import BonjourAICloud

// MARK: - AnthropicModelTests

@Suite("AnthropicModel")
struct AnthropicModelTests {

    @Test("`.default` is `.sonnet` — the balanced tier")
    func defaultIsSonnet() {
        #expect(AnthropicModel.default == .sonnet)
    }

    @Test("`resolved(rawValue:)` returns the matching case for known identifiers")
    func resolvedMatchesKnownIdentifiers() {
        #expect(AnthropicModel.resolved(rawValue: "claude-opus-4-5") == .opus)
        #expect(AnthropicModel.resolved(rawValue: "claude-sonnet-4-5") == .sonnet)
        #expect(AnthropicModel.resolved(rawValue: "claude-haiku-4-5") == .haiku)
    }

    @Test("`resolved(rawValue:)` falls back to the default for unknown identifiers")
    func resolvedFallsBackForUnknown() {
        #expect(AnthropicModel.resolved(rawValue: "claude-opus-1") == .default)
        #expect(AnthropicModel.resolved(rawValue: "gpt-4") == .default)
    }

    @Test("`resolved(rawValue:)` falls back to the default for nil")
    func resolvedFallsBackForNil() {
        #expect(AnthropicModel.resolved(rawValue: nil) == .default)
    }

    @Test("Every case has a non-empty display name and short description")
    func everyCaseHasDisplayCopy() {
        for model in AnthropicModel.allCases {
            #expect(!model.displayName.isEmpty, "displayName empty for \(model.rawValue)")
            #expect(!model.shortDescription.isEmpty, "shortDescription empty for \(model.rawValue)")
        }
    }

    @Test("`id` equals `rawValue` for Identifiable lookups")
    func idMatchesRawValue() {
        for model in AnthropicModel.allCases {
            #expect(model.id == model.rawValue)
        }
    }
}
