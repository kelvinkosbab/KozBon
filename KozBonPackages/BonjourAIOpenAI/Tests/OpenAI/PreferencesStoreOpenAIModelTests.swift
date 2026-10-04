//
//  PreferencesStoreOpenAIModelTests.swift
//  BonjourAIOpenAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import SwiftData
import Testing
import BonjourAICore
import BonjourStorage
@testable import BonjourAIOpenAI

// MARK: - PreferencesStoreOpenAIModelTests

/// Pins OpenAI's own model slot, so switching backends can't hand
/// OpenAI a `claude-` or `gemini-` identifier.
@Suite("PreferencesStore · OpenAI model")
@MainActor
struct PreferencesStoreOpenAIModelTests {

    private func makeStore() throws -> PreferencesStore {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserPreferences.self, configurations: config)
        return PreferencesStore(container: container)
    }

    @Test("A fresh store reads the OpenAI default")
    func freshStoreReadsDefault() throws {
        let store = try makeStore()
        #expect(store.aiCloudModelIdentifier(for: .openai) == OpenAIModel.default.rawValue)
    }

    @Test("Switching between all three cloud backends preserves each choice")
    func slotsAreIndependent() throws {
        let store = try makeStore()
        store.setAICloudModelIdentifier("claude-opus-4-1", for: .anthropic)
        store.setAICloudModelIdentifier("gemini-2.5-pro", for: .gemini)
        store.setAICloudModelIdentifier("gpt-6-astra", for: .openai)

        store.aiBackend = .openai
        #expect(store.aiCloudModelIdentifier == "gpt-6-astra")
        store.aiBackend = .gemini
        #expect(store.aiCloudModelIdentifier == "gemini-2.5-pro")
        store.aiBackend = .anthropic
        #expect(store.aiCloudModelIdentifier == "claude-opus-4-1")
    }

    @Test("A blank slot falls back to the OpenAI default")
    func blankFallsBackToDefault() throws {
        let store = try makeStore()
        store.setAICloudModelIdentifier("  ", for: .openai)
        #expect(store.aiCloudModelIdentifier(for: .openai) == OpenAIModel.default.rawValue)
    }

    @Test("Reset to defaults restores the OpenAI slot")
    func resetRestoresDefault() throws {
        let store = try makeStore()
        store.setAICloudModelIdentifier("gpt-6-astra", for: .openai)
        store.resetToDefaults()
        #expect(store.aiCloudModelIdentifier(for: .openai) == OpenAIModel.default.rawValue)
    }
}
