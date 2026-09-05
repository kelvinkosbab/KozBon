//
//  PreferencesStoreAnthropicModelTests.swift
//  BonjourAIAnthropic
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import SwiftData
import Testing
import BonjourStorage
import BonjourAICore
@testable import BonjourAIAnthropic

// MARK: - PreferencesStoreAnthropicModelTests

/// Pins the persistence contract for the selected Claude model.
///
/// The load-bearing behavior is that an identifier this binary
/// doesn't recognize survives a round trip. The model list is
/// fetched at runtime, so "unknown" almost always means "newer
/// than this build" — the old enum round-trip silently replaced
/// those with the compiled-in default, which is what made the
/// picker appear frozen on old models.
@Suite("PreferencesStore.aiCloudModelIdentifier")
@MainActor
struct PreferencesStoreAnthropicModelTests {

    // MARK: - Helpers

    private func makeStore() throws -> PreferencesStore {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserPreferences.self, configurations: config)
        return PreferencesStore(container: container)
    }

    // MARK: - Defaults

    @Test("A fresh store reads back the default model identifier")
    func readsDefaultIdentifier() throws {
        let store = try makeStore()
        #expect(store.aiCloudModelIdentifier == AnthropicModel.default.rawValue)
    }

    @Test("A blank or whitespace-only stored value falls back to the default")
    func blankFallsBackToDefault() throws {
        let store = try makeStore()
        store.aiCloudModelRawValue = ""
        #expect(store.aiCloudModelIdentifier == AnthropicModel.default.rawValue)

        store.aiCloudModelRawValue = "   "
        #expect(store.aiCloudModelIdentifier == AnthropicModel.default.rawValue)
    }

    // MARK: - Round Trip

    @Test("A built-in identifier round-trips unchanged")
    func builtInIdentifierRoundTrips() throws {
        let store = try makeStore()
        store.aiCloudModelIdentifier = AnthropicModel.opus.rawValue
        #expect(store.aiCloudModelRawValue == AnthropicModel.opus.rawValue)
        #expect(store.aiCloudModelIdentifier == AnthropicModel.opus.rawValue)
    }

    @Test("An identifier newer than this build survives — it is NOT snapped to the default")
    func unknownIdentifierIsPreserved() throws {
        // The regression this guards: a user picks a model that
        // shipped after this binary, and the stored value must
        // still come back verbatim so requests keep addressing
        // the model they actually chose.
        let store = try makeStore()
        store.aiCloudModelIdentifier = "claude-opus-5"

        #expect(store.aiCloudModelRawValue == "claude-opus-5")
        #expect(store.aiCloudModelIdentifier == "claude-opus-5")
        #expect(store.aiCloudModelIdentifier != AnthropicModel.default.rawValue)
    }
}
