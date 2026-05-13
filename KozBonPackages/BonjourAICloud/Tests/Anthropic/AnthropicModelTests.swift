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
        #expect(AnthropicModel.resolved(rawValue: "claude-opus-4-1") == .opus)
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

    @Test("Every case exposes a non-empty marketing version")
    func everyCaseHasVersion() {
        for model in AnthropicModel.allCases {
            #expect(!model.version.isEmpty, "version empty for \(model.rawValue)")
        }
    }

    @Test("Display name embeds the marketing version so users see the model generation")
    func displayNameIncludesVersion() {
        // The UI surfaces both the model name and the version in
        // the picker — this assertion locks the format down so a
        // future "tighten the name" refactor can't silently drop
        // the version. Localized strings in the catalog should
        // mirror this format ("Claude Opus 4.1" etc). Opus
        // intentionally lags Sonnet / Haiku by one minor revision
        // — see the version-property comment in
        // `AnthropicModel.swift`.
        #expect(AnthropicModel.opus.displayName == "Claude Opus 4.1")
        #expect(AnthropicModel.sonnet.displayName == "Claude Sonnet 4.5")
        #expect(AnthropicModel.haiku.displayName == "Claude Haiku 4.5")
    }

    @Test("Version matches the suffix encoded in the API identifier")
    func versionMatchesRawValueSuffix() {
        // Trip-wire — if the raw value (the API identifier) ever
        // drifts away from the marketing version, the two will
        // disagree and this test will fail. Bumping one requires
        // bumping the other.
        for model in AnthropicModel.allCases {
            let dashedVersion = model.version.replacingOccurrences(of: ".", with: "-")
            #expect(
                model.rawValue.hasSuffix(dashedVersion),
                "rawValue (\(model.rawValue)) should end with version (\(dashedVersion))"
            )
        }
    }

    @Test("`id` equals `rawValue` for Identifiable lookups")
    func idMatchesRawValue() {
        for model in AnthropicModel.allCases {
            #expect(model.id == model.rawValue)
        }
    }
}
