//
//  KeychainAICloudCredentialsStoreTests.swift
//  BonjourAICloud
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourAICloud

// MARK: - KeychainAICloudCredentialsStoreTests

/// Integration tests against the real Keychain.
///
/// Each test uses a unique `service` identifier so concurrent
/// execution doesn't see another test's entry. Tests clean up
/// after themselves; if a previous run was interrupted the next
/// run's first call clears any leftover key under the same
/// unique service.
///
/// Skipped automatically under environments where the Keychain
/// isn't available — most notably the Linux Swift CLI build,
/// where the `Security` framework simply isn't present.
#if canImport(Security)
@Suite("KeychainAICloudCredentialsStore")
@MainActor
struct KeychainAICloudCredentialsStoreTests {

    private static func uniqueService() -> String {
        "com.kozinga.KozBon.AICloud.tests.\(UUID().uuidString)"
    }

    @Test("Round-trips an API key through the real Keychain")
    func roundTripsAPIKey() throws {
        let store = KeychainAICloudCredentialsStore(service: Self.uniqueService())
        try store.removeAPIKey(for: .anthropic) // belt + suspenders cleanup

        try store.setAPIKey("sk-ant-keychain-test", for: .anthropic)
        #expect(try store.apiKey(for: .anthropic) == "sk-ant-keychain-test")
        #expect(store.hasAPIKey(for: .anthropic))

        try store.removeAPIKey(for: .anthropic)
        #expect(try store.apiKey(for: .anthropic) == nil)
        #expect(!store.hasAPIKey(for: .anthropic))
    }

    @Test("Updating an existing key overwrites cleanly")
    func updateOverwrites() throws {
        let store = KeychainAICloudCredentialsStore(service: Self.uniqueService())
        try store.removeAPIKey(for: .anthropic)

        try store.setAPIKey("sk-ant-v1", for: .anthropic)
        try store.setAPIKey("sk-ant-v2", for: .anthropic)

        #expect(try store.apiKey(for: .anthropic) == "sk-ant-v2")
        try store.removeAPIKey(for: .anthropic)
    }

    @Test("Writing an empty key removes the entry")
    func emptyKeyRemoves() throws {
        let store = KeychainAICloudCredentialsStore(service: Self.uniqueService())
        try store.removeAPIKey(for: .anthropic)

        try store.setAPIKey("sk-ant-temporary", for: .anthropic)
        #expect(store.hasAPIKey(for: .anthropic))

        try store.setAPIKey("", for: .anthropic)
        #expect(!store.hasAPIKey(for: .anthropic))
    }

    @Test("Removing a missing key is a no-op")
    func removeMissingIsNoOp() throws {
        let store = KeychainAICloudCredentialsStore(service: Self.uniqueService())
        // Must not throw — Keychain returns `errSecItemNotFound`
        // which we collapse into success.
        try store.removeAPIKey(for: .anthropic)
    }
}
#endif
