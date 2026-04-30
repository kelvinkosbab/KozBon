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

    /// Creates a fresh in-memory `ModelContainer` for tests. Each call
    /// returns a brand-new container so tests are isolated. The function
    /// throws on container-init failure (rather than swallowing with
    /// `try!`), which Swift Testing surfaces as a test failure with the
    /// underlying error — strictly more informative than a crash.
    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: UserPreferences.self,
            configurations: config
        )
    }

    /// Convenience that wraps ``makeContainer()`` in a fresh
    /// ``PreferencesStore``. Tests that don't need to inspect the
    /// underlying container directly should prefer this.
    private func makeStore() throws -> PreferencesStore {
        PreferencesStore(container: try makeContainer())
    }

    // MARK: - Default Values

    @Test("Fresh store reports `aiAnalysisEnabled` as true by default")
    func defaultAiAnalysisEnabled() throws {
        let store = try makeStore()
        #expect(store.aiAnalysisEnabled)
    }

    @Test("Fresh store reports `aiExpertiseLevel` as `\"basic\"` by default")
    func defaultAiExpertiseLevel() throws {
        let store = try makeStore()
        #expect(store.aiExpertiseLevel == "basic")
    }

    @Test("Fresh store reports `defaultSortOrder` as the empty string by default")
    func defaultSortOrder() throws {
        let store = try makeStore()
        #expect(store.defaultSortOrder == "")
    }

    // MARK: - Persistence

    @Test("`aiAnalysisEnabled` survives across new store instances on the same container")
    func aiAnalysisEnabledPersists() throws {
        let container = try makeContainer()

        let store1 = PreferencesStore(container: container)
        store1.aiAnalysisEnabled = false

        let store2 = PreferencesStore(container: container)
        #expect(!store2.aiAnalysisEnabled)
    }

    @Test("`aiExpertiseLevel` survives across new store instances on the same container")
    func aiExpertiseLevelPersists() throws {
        let container = try makeContainer()

        let store1 = PreferencesStore(container: container)
        store1.aiExpertiseLevel = "technical"

        let store2 = PreferencesStore(container: container)
        #expect(store2.aiExpertiseLevel == "technical")
    }

    @Test("`defaultSortOrder` survives across new store instances on the same container")
    func defaultSortOrderPersists() throws {
        let container = try makeContainer()

        let store1 = PreferencesStore(container: container)
        store1.defaultSortOrder = "hostNameAsc"

        let store2 = PreferencesStore(container: container)
        #expect(store2.defaultSortOrder == "hostNameAsc")
    }

    // MARK: - Reset

    @Test("`resetToDefaults` restores every preference to its documented default value")
    func resetToDefaultsRestoresAllValues() throws {
        let store = try makeStore()
        store.aiAnalysisEnabled = false
        store.aiExpertiseLevel = "technical"
        store.defaultSortOrder = "serviceNameDesc"

        store.resetToDefaults()

        #expect(store.aiAnalysisEnabled)
        #expect(store.aiExpertiseLevel == "basic")
        #expect(store.defaultSortOrder == "")
    }

    // MARK: - Single Row

    @Test("Two store instances on one container read and write the same singleton row")
    func multipleStoreInstancesShareSameRow() throws {
        let container = try makeContainer()

        let storeA = PreferencesStore(container: container)
        storeA.aiExpertiseLevel = "technical"

        let storeB = PreferencesStore(container: container)
        #expect(storeB.aiExpertiseLevel == "technical")
    }

    // MARK: - Reset Uses Defaults

    @Test("`resetToDefaults` mirrors `UserPreferences.default*` constants exactly")
    func resetUsesUserPreferencesDefaults() throws {
        let store = try makeStore()
        store.resetToDefaults()
        #expect(store.aiAnalysisEnabled == UserPreferences.defaultAIAnalysisEnabled)
        #expect(store.aiExpertiseLevel == UserPreferences.defaultAIExpertiseLevel)
        #expect(store.aiResponseLength == UserPreferences.defaultAIResponseLength)
        #expect(store.defaultSortOrder == UserPreferences.defaultSortOrder)
    }

    // MARK: - Default Init

    @Test("Zero-argument `PreferencesStore()` produces a usable store with default values")
    func defaultInitCreatesWorkingStore() {
        let store = PreferencesStore()
        #expect(store.aiAnalysisEnabled)
        #expect(store.aiExpertiseLevel == "basic")
        #expect(store.aiResponseLength == "standard")
        #expect(store.defaultSortOrder == "")
    }

    // MARK: - Response Length

    @Test("`aiResponseLength` round-trips through writes for `\"brief\"` and `\"thorough\"`")
    func responseLengthWriteThenRead() throws {
        let store = try makeStore()
        store.aiResponseLength = "brief"
        #expect(store.aiResponseLength == "brief")
        store.aiResponseLength = "thorough"
        #expect(store.aiResponseLength == "thorough")
    }

    @Test("Fresh store reports `aiResponseLength` as `\"standard\"` by default")
    func responseLengthDefaultIsStandard() throws {
        let store = try makeStore()
        #expect(store.aiResponseLength == "standard")
    }

    @Test("`aiResponseLength` survives across new store instances on the same container")
    func responseLengthPersistsAcrossStoreInstances() throws {
        let container = try makeContainer()
        let storeA = PreferencesStore(container: container)
        storeA.aiResponseLength = "thorough"

        let storeB = PreferencesStore(container: container)
        #expect(storeB.aiResponseLength == "thorough")
    }

    // MARK: - Write Then Read

    @Test("`aiAnalysisEnabled` round-trips through writes in both directions")
    func aiAnalysisEnabledWriteThenRead() throws {
        let store = try makeStore()
        store.aiAnalysisEnabled = false
        #expect(!store.aiAnalysisEnabled)
        store.aiAnalysisEnabled = true
        #expect(store.aiAnalysisEnabled)
    }

    @Test("`aiExpertiseLevel` round-trips through writes for `\"technical\"` and `\"basic\"`")
    func aiExpertiseLevelWriteThenRead() throws {
        let store = try makeStore()
        store.aiExpertiseLevel = "technical"
        #expect(store.aiExpertiseLevel == "technical")
        store.aiExpertiseLevel = "basic"
        #expect(store.aiExpertiseLevel == "basic")
    }

    @Test("`defaultSortOrder` round-trips through writes including back to the empty string")
    func defaultSortOrderWriteThenRead() throws {
        let store = try makeStore()
        store.defaultSortOrder = "serviceNameDesc"
        #expect(store.defaultSortOrder == "serviceNameDesc")
        store.defaultSortOrder = ""
        #expect(store.defaultSortOrder == "")
    }

    // MARK: - Reset Preserves Subsequent Changes

    @Test("Writes after `resetToDefaults` are persisted normally instead of being clobbered")
    func resetThenModifyPersists() throws {
        let store = try makeStore()
        store.resetToDefaults()
        store.aiAnalysisEnabled = false
        store.aiExpertiseLevel = "technical"
        store.defaultSortOrder = "hostNameDesc"
        #expect(!store.aiAnalysisEnabled)
        #expect(store.aiExpertiseLevel == "technical")
        #expect(store.defaultSortOrder == "hostNameDesc")
    }

}
