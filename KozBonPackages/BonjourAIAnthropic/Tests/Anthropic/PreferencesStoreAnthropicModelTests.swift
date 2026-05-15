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

@Suite("PreferencesStore.aiCloudModel")
@MainActor
struct PreferencesStoreAnthropicModelTests {

    // MARK: - Helpers

    private func makeStore() throws -> PreferencesStore {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserPreferences.self, configurations: config)
        return PreferencesStore(container: container)
    }

    // MARK: - Tests

    @Test("Typed `aiCloudModel` reads back `.sonnet` from a fresh store")
    func typedCloudModelReadsDefault() throws {
        let store = try makeStore()
        #expect(store.aiCloudModel == .sonnet)
    }

    @Test("Writing typed `aiCloudModel = .opus` persists as raw `\"claude-opus-4-1\"`")
    func typedCloudModelWritesRawValue() throws {
        let store = try makeStore()
        store.aiCloudModel = .opus
        #expect(store.aiCloudModelRawValue == "claude-opus-4-1")
        #expect(store.aiCloudModel == .opus)
    }
}
