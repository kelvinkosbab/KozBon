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
        #expect(store.aiResponseLength == UserPreferences.defaultAIResponseLength)
        #expect(store.defaultSortOrder == UserPreferences.defaultSortOrder)
    }

    // MARK: - Default Init

    @Test func defaultInitCreatesWorkingStore() {
        let store = PreferencesStore()
        #expect(store.aiAnalysisEnabled)
        #expect(store.aiExpertiseLevel == "basic")
        #expect(store.aiResponseLength == "standard")
        #expect(store.defaultSortOrder == "")
    }

    // MARK: - Response Length

    @Test func responseLengthWriteThenRead() {
        let store = makeStore()
        store.aiResponseLength = "brief"
        #expect(store.aiResponseLength == "brief")
        store.aiResponseLength = "thorough"
        #expect(store.aiResponseLength == "thorough")
    }

    @Test func responseLengthDefaultIsStandard() {
        let store = makeStore()
        #expect(store.aiResponseLength == "standard")
    }

    @Test func responseLengthPersistsAcrossStoreInstances() {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        // swiftlint:disable:next force_try
        let container = try! ModelContainer(
            for: UserPreferences.self,
            configurations: config
        )
        let storeA = PreferencesStore(container: container)
        storeA.aiResponseLength = "thorough"

        let storeB = PreferencesStore(container: container)
        #expect(storeB.aiResponseLength == "thorough")
    }

    // MARK: - Write Then Read

    @Test func aiAnalysisEnabledWriteThenRead() {
        let store = makeStore()
        store.aiAnalysisEnabled = false
        #expect(!store.aiAnalysisEnabled)
        store.aiAnalysisEnabled = true
        #expect(store.aiAnalysisEnabled)
    }

    @Test func aiExpertiseLevelWriteThenRead() {
        let store = makeStore()
        store.aiExpertiseLevel = "technical"
        #expect(store.aiExpertiseLevel == "technical")
        store.aiExpertiseLevel = "basic"
        #expect(store.aiExpertiseLevel == "basic")
    }

    @Test func defaultSortOrderWriteThenRead() {
        let store = makeStore()
        store.defaultSortOrder = "serviceNameDesc"
        #expect(store.defaultSortOrder == "serviceNameDesc")
        store.defaultSortOrder = ""
        #expect(store.defaultSortOrder == "")
    }

    // MARK: - Reset Preserves Subsequent Changes

    @Test func resetThenModifyPersists() {
        let store = makeStore()
        store.resetToDefaults()
        store.aiAnalysisEnabled = false
        store.aiExpertiseLevel = "technical"
        store.defaultSortOrder = "hostNameDesc"
        #expect(!store.aiAnalysisEnabled)
        #expect(store.aiExpertiseLevel == "technical")
        #expect(store.defaultSortOrder == "hostNameDesc")
    }
}
