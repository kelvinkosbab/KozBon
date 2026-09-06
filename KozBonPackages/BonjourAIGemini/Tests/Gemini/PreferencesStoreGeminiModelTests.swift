//
//  PreferencesStoreGeminiModelTests.swift
//  BonjourAIGemini
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import SwiftData
import Testing
import BonjourAICore
import BonjourStorage
@testable import BonjourAIGemini

// MARK: - PreferencesStoreGeminiModelTests

/// Pins the per-provider model slots.
///
/// The bug this guards against: one shared slot would hand Gemini
/// a `claude-` identifier the moment a user switched backends, and
/// lose their Claude choice on the way back.
@Suite("PreferencesStore · per-provider model")
@MainActor
struct PreferencesStoreGeminiModelTests {

    private func makeStore() throws -> PreferencesStore {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserPreferences.self, configurations: config)
        return PreferencesStore(container: container)
    }

    // MARK: - Independence

    @Test("Each provider keeps its own model")
    func slotsAreIndependent() throws {
        let store = try makeStore()

        store.setAICloudModelIdentifier("claude-opus-4-1", for: .anthropic)
        store.setAICloudModelIdentifier("gemini-2.5-pro", for: .gemini)

        #expect(store.aiCloudModelIdentifier(for: .anthropic) == "claude-opus-4-1")
        #expect(store.aiCloudModelIdentifier(for: .gemini) == "gemini-2.5-pro")
    }

    @Test("Switching backends and back preserves both choices")
    func switchingBackAndForthPreservesChoices() throws {
        let store = try makeStore()
        store.setAICloudModelIdentifier("claude-opus-4-1", for: .anthropic)
        store.setAICloudModelIdentifier("gemini-2.5-flash-lite", for: .gemini)

        store.aiBackend = .gemini
        #expect(store.aiCloudModelIdentifier == "gemini-2.5-flash-lite")

        store.aiBackend = .anthropic
        #expect(store.aiCloudModelIdentifier == "claude-opus-4-1")
    }

    // MARK: - Defaults

    @Test("An empty or whitespace-only slot falls back to that provider's default")
    func emptyFallsBackToProviderDefault() throws {
        let store = try makeStore()

        store.setAICloudModelIdentifier("   ", for: .gemini)
        #expect(store.aiCloudModelIdentifier(for: .gemini) == GeminiModel.default.rawValue)

        store.setAICloudModelIdentifier("", for: .anthropic)
        #expect(
            store.aiCloudModelIdentifier(for: .anthropic)
                == AICloudProvider.anthropic.defaultModelIdentifier
        )
    }

    @Test("A model this binary has never heard of is preserved, not snapped to a known case")
    func preservesUnknownIdentifier() throws {
        // The whole point of storing a `String`: a model newer
        // than the app must survive, or the picker feels frozen in
        // time. Only a live catalog may overrule it.
        let store = try makeStore()
        store.setAICloudModelIdentifier("gemini-4.0-ultra", for: .gemini)
        #expect(store.aiCloudModelIdentifier(for: .gemini) == "gemini-4.0-ultra")
    }

    // MARK: - Backend-Derived Accessor

    @Test("On the on-device backend the accessor is still readable and non-empty")
    func readableOnAppleBackend() throws {
        // Nothing consumes it in this state, but a non-optional
        // property that traps or returns "" would be a landmine.
        let store = try makeStore()
        store.aiBackend = .appleIntelligence
        #expect(!store.aiCloudModelIdentifier.isEmpty)
    }

    @Test("Writing through the derived accessor lands in the active provider's slot")
    func derivedWriteTargetsActiveProvider() throws {
        let store = try makeStore()
        store.aiBackend = .gemini
        store.aiCloudModelIdentifier = "gemini-2.5-pro"

        #expect(store.aiCloudModelIdentifier(for: .gemini) == "gemini-2.5-pro")
        // ...and left the other provider alone.
        #expect(
            store.aiCloudModelIdentifier(for: .anthropic)
                == AICloudProvider.anthropic.defaultModelIdentifier
        )
    }
}
