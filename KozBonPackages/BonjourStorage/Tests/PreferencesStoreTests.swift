//
//  PreferencesStoreTests.swift
//  BonjourStorage
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import SwiftData
@testable import BonjourStorage

// MARK: - PreferencesStoreTests

@Suite("PreferencesStore")
@MainActor
struct PreferencesStoreTests {

    // MARK: - Helpers

    /// Creates an in-memory preferences store for testing.
    private func makeStore() -> PreferencesStore {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        // swiftlint:disable:next force_try
        let container = try! ModelContainer(
            for: UserPreferences.self,
            configurations: config
        )
        return PreferencesStore(container: container)
    }

    // MARK: - Default Values

    @Test func defaultAiAnalysisEnabled() {
        let store = makeStore()
        #expect(store.aiAnalysisEnabled)
    }

    @Test func defaultAiExpertiseLevel() {
        let store = makeStore()
        #expect(store.aiExpertiseLevel == "basic")
    }

    @Test func defaultSortOrder() {
        let store = makeStore()
        #expect(store.defaultSortOrder == "")
    }

    // MARK: - Persistence

    @Test func aiAnalysisEnabledPersists() {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        // swiftlint:disable:next force_try
        let container = try! ModelContainer(
            for: UserPreferences.self,
            configurations: config
        )

        let store1 = PreferencesStore(container: container)
        store1.aiAnalysisEnabled = false

        let store2 = PreferencesStore(container: container)
        #expect(!store2.aiAnalysisEnabled)
    }

    @Test func aiExpertiseLevelPersists() {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        // swiftlint:disable:next force_try
        let container = try! ModelContainer(
            for: UserPreferences.self,
            configurations: config
        )

        let store1 = PreferencesStore(container: container)
        store1.aiExpertiseLevel = "technical"

        let store2 = PreferencesStore(container: container)
        #expect(store2.aiExpertiseLevel == "technical")
    }

    @Test func defaultSortOrderPersists() {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        // swiftlint:disable:next force_try
        let container = try! ModelContainer(
            for: UserPreferences.self,
            configurations: config
        )

        let store1 = PreferencesStore(container: container)
        store1.defaultSortOrder = "hostNameAsc"

        let store2 = PreferencesStore(container: container)
        #expect(store2.defaultSortOrder == "hostNameAsc")
    }

    // MARK: - Reset

    @Test func resetToDefaultsRestoresAllValues() {
        let store = makeStore()
        store.aiAnalysisEnabled = false
        store.aiExpertiseLevel = "technical"
        store.defaultSortOrder = "serviceNameDesc"

        store.resetToDefaults()

        #expect(store.aiAnalysisEnabled)
        #expect(store.aiExpertiseLevel == "basic")
        #expect(store.defaultSortOrder == "")
    }

    // MARK: - Single Row

    @Test func multipleStoreInstancesShareSameRow() {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        // swiftlint:disable:next force_try
        let container = try! ModelContainer(
            for: UserPreferences.self,
            configurations: config
        )

        let storeA = PreferencesStore(container: container)
        storeA.aiExpertiseLevel = "technical"

        let storeB = PreferencesStore(container: container)
        #expect(storeB.aiExpertiseLevel == "technical")
    }

    // MARK: - Reset Uses Defaults

    @Test func resetUsesUserPreferencesDefaults() {
        let store = makeStore()
        store.resetToDefaults()
        #expect(store.aiAnalysisEnabled == UserPreferences.defaultAIAnalysisEnabled)
        #expect(store.aiExpertiseLevel == UserPreferences.defaultAIExpertiseLevel)
        #expect(store.defaultSortOrder == UserPreferences.defaultSortOrder)
    }

    // MARK: - Default Init

    @Test func defaultInitCreatesWorkingStore() {
        let store = PreferencesStore()
        #expect(store.aiAnalysisEnabled)
        #expect(store.aiExpertiseLevel == "basic")
        #expect(store.defaultSortOrder == "")
    }
}
