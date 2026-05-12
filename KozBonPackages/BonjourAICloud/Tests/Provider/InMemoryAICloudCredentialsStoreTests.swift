//
//  InMemoryAICloudCredentialsStoreTests.swift
//  BonjourAICloud
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Testing
@testable import BonjourAICloud

// MARK: - InMemoryAICloudCredentialsStoreTests

@Suite("InMemoryAICloudCredentialsStore")
@MainActor
struct InMemoryAICloudCredentialsStoreTests {

    @Test("An empty store reports no key for any provider")
    func emptyStoreHasNoKey() throws {
        let store = InMemoryAICloudCredentialsStore()
        #expect(try store.apiKey(for: .anthropic) == nil)
        #expect(!store.hasAPIKey(for: .anthropic))
    }

    @Test("`setAPIKey` then `apiKey(for:)` returns the value")
    func setThenGetRoundTrips() throws {
        let store = InMemoryAICloudCredentialsStore()
        try store.setAPIKey("sk-ant-test-1234", for: .anthropic)

        #expect(try store.apiKey(for: .anthropic) == "sk-ant-test-1234")
        #expect(store.hasAPIKey(for: .anthropic))
    }

    @Test("Writing an empty string removes the entry")
    func setEmptyRemoves() throws {
        let store = InMemoryAICloudCredentialsStore(seed: [.anthropic: "sk-ant-existing"])
        #expect(store.hasAPIKey(for: .anthropic))

        try store.setAPIKey("", for: .anthropic)

        #expect(try store.apiKey(for: .anthropic) == nil)
        #expect(!store.hasAPIKey(for: .anthropic))
    }

    @Test("`removeAPIKey` is a no-op when no key is stored")
    func removeMissingIsNoOp() throws {
        let store = InMemoryAICloudCredentialsStore()
        // Must not throw — matches Keychain semantics where
        // `errSecItemNotFound` is collapsed into success.
        try store.removeAPIKey(for: .anthropic)
        #expect(try store.apiKey(for: .anthropic) == nil)
    }

    @Test("Seed values populate the store on init")
    func seedPopulates() throws {
        let store = InMemoryAICloudCredentialsStore(seed: [.anthropic: "sk-ant-seed"])
        #expect(try store.apiKey(for: .anthropic) == "sk-ant-seed")
    }

    @Test("Seeded empty strings are filtered out")
    func seedFiltersEmptyStrings() throws {
        let store = InMemoryAICloudCredentialsStore(seed: [.anthropic: ""])
        #expect(try store.apiKey(for: .anthropic) == nil)
        #expect(!store.hasAPIKey(for: .anthropic))
    }
}
