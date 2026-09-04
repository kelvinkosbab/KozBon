//
//  AIBackendTests.swift
//  BonjourAICore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import SwiftData
import Testing
import BonjourStorage
@testable import BonjourAICore

// MARK: - AIBackendTests

@Suite("AIBackend")
@MainActor
struct AIBackendTests {

    // MARK: - Helpers

    private func makeStore() throws -> PreferencesStore {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserPreferences.self, configurations: config)
        return PreferencesStore(container: container)
    }

    // MARK: - Resolution

    @Test("`.default` is `.appleIntelligence` so cloud is strictly opt-in")
    func defaultIsAppleIntelligence() {
        // ADR 0005 requires this — switching off the on-device
        // default must be a deliberate user action.
        #expect(AIBackend.default == .appleIntelligence)
    }

    @Test("`resolved(rawValue:)` returns the matching case for known identifiers")
    func resolvedMatchesKnownIdentifiers() {
        #expect(AIBackend.resolved(rawValue: "apple") == .appleIntelligence)
        #expect(AIBackend.resolved(rawValue: "anthropic") == .anthropic)
    }

    @Test("`resolved(rawValue:)` falls back to default for unknown / nil values")
    func resolvedFallsBackForUnknown() {
        #expect(AIBackend.resolved(rawValue: "openai") == .default)
        // GitHub Models was retired 2026-07-30 and the case removed —
        // stored preferences must migrate to the default, not dangle.
        #expect(AIBackend.resolved(rawValue: "github") == .default)
        #expect(AIBackend.resolved(rawValue: nil) == .default)
        #expect(AIBackend.resolved(rawValue: "") == .default)
    }

    // MARK: - Classification

    @Test("`isCloud` is false for Apple Intelligence and true for every cloud backend")
    func isCloudPerCase() {
        #expect(!AIBackend.appleIntelligence.isCloud)
        #expect(AIBackend.anthropic.isCloud)
    }

    @Test("`cloudProvider` is nil for Apple and matches the picker case for cloud backends")
    func cloudProviderPerCase() {
        #expect(AIBackend.appleIntelligence.cloudProvider == nil)
        #expect(AIBackend.anthropic.cloudProvider == .anthropic)
    }

    // MARK: - PreferencesStore Bridge

    @Test("Typed `aiBackend` reads back `.appleIntelligence` from a fresh store")
    func typedAccessorReadsDefault() throws {
        let store = try makeStore()
        #expect(store.aiBackend == .appleIntelligence)
    }

    @Test("Writing typed `aiBackend = .anthropic` persists as raw `\"anthropic\"`")
    func typedAccessorWritesRawValue() throws {
        let store = try makeStore()
        store.aiBackend = .anthropic
        #expect(store.aiBackendRawValue == "anthropic")
        #expect(store.aiBackend == .anthropic)
    }

    @Test("A persisted `\"github\"` raw value reads back as the default after retirement")
    func retiredGitHubRawValueReadsBackAsDefault() throws {
        let store = try makeStore()
        // Simulates a user who selected GitHub Models before it was
        // retired: the raw value survives in SwiftData, but the typed
        // accessor must hand back a working backend.
        store.aiBackendRawValue = "github"
        #expect(store.aiBackend == .appleIntelligence)
    }

    @Test("Retired backend identifiers fall back to the default")
    func retiredBackendFallsBack() throws {
        let store = try makeStore()
        // Simulate a future schema that retired a backend
        store.aiBackendRawValue = "deprecated-provider"
        #expect(store.aiBackend == .default)
    }
}
