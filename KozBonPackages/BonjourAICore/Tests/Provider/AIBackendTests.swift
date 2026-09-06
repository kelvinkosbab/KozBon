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

// MARK: - AIBackendTests · Completeness

/// Guards against a half-added provider.
///
/// Most `AIBackend` call sites are switches, so the compiler
/// enumerates them — but not all. The Settings picker listed its
/// rows by hand and silently omitted Gemini when it was added,
/// which no switch and no test caught; only a screenshot did. The
/// picker now iterates `allCases`, and these pin the per-case data
/// that iteration depends on.
extension AIBackendTests {

    @Test("Every backend has a distinct display name and subtitle")
    func everyBackendHasDistinctCopy() {
        let names = Set(AIBackend.allCases.map { String(localized: $0.displayName) })
        let subtitles = Set(AIBackend.allCases.map { String(localized: $0.displaySubtitle) })

        #expect(names.count == AIBackend.allCases.count)
        #expect(subtitles.count == AIBackend.allCases.count)
    }

    @Test("Exactly the cloud backends map to a provider, and each maps to a distinct one")
    func cloudBackendsMapToDistinctProviders() {
        let cloud = AIBackend.allCases.filter(\.isCloud)
        let providers = cloud.compactMap(\.cloudProvider)

        // `isCloud` and `cloudProvider` are separate switches; a
        // new case that updates one and not the other routes to
        // the wrong backend rather than failing to compile.
        #expect(providers.count == cloud.count)
        #expect(Set(providers).count == providers.count)

        let onDevice = AIBackend.allCases.filter { !$0.isCloud }
        #expect(onDevice.allSatisfy { $0.cloudProvider == nil })
    }

    @Test("Every cloud provider names a non-empty default model, except retired GitHub")
    func cloudProvidersDeclareDefaultModels() {
        for backend in AIBackend.allCases {
            guard let provider = backend.cloudProvider else { continue }
            #expect(
                !provider.defaultModelIdentifier.isEmpty,
                "\(provider) needs a default model for the preferences fallback"
            )
        }
    }
}
