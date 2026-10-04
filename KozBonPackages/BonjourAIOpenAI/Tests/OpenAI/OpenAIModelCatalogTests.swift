//
//  OpenAIModelCatalogTests.swift
//  BonjourAIOpenAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourAICore
@testable import BonjourAIOpenAI

// MARK: - Stub Client

/// Records calls and replays a canned outcome so every tier of the
/// catalog can be exercised without a network.
private actor StubOpenAICatalogClient: OpenAIModelCatalogClientProtocol {

    enum Outcome: Sendable {
        case success([OpenAIModelOption])
        case failure(AICloudError)
    }

    private let outcome: Outcome
    private(set) var callCount = 0

    init(_ outcome: Outcome) {
        self.outcome = outcome
    }

    func listModels(apiKey: String) async throws -> [OpenAIModelOption] {
        callCount += 1
        switch outcome {
        case .success(let options): return options
        case .failure(let error):   throw error
        }
    }

    func recordedCallCount() async -> Int { callCount }
}

private func liveOption(_ id: String) -> OpenAIModelOption {
    OpenAIModelOption(id: id, displayName: OpenAIModelOption.displayName(forIdentifier: id), isBuiltIn: false)
}

// MARK: - OpenAIModelCatalogTests

/// Pins the three-tier resolution the other providers' pickers rely
/// on: a live fetch wins, a failure keeps the previous list, and
/// the compiled-in list is the offline floor.
@Suite("OpenAIModelCatalog")
@MainActor
struct OpenAIModelCatalogTests {

    @Test("A fresh catalog starts on the compiled-in list so the picker is never empty")
    func startsWithBuiltInOptions() {
        let catalog = OpenAIModelCatalog(client: StubOpenAICatalogClient(.success([])))
        #expect(catalog.options == OpenAIModelOption.builtInOptions)
        #expect(!catalog.isLive)
    }

    @Test("With no key configured, nothing is fetched")
    func skipsFetchWithoutKey() async {
        let client = StubOpenAICatalogClient(.success([liveOption("gpt-7")]))
        let catalog = OpenAIModelCatalog(client: client)

        await catalog.refresh(apiKey: nil)
        await catalog.refresh(apiKey: "")

        #expect(await client.recordedCallCount() == 0)
    }

    @Test("A successful fetch replaces the list and marks it live")
    func successfulFetchReplacesOptions() async {
        let catalog = OpenAIModelCatalog(
            client: StubOpenAICatalogClient(.success([liveOption("gpt-7"), liveOption("gpt-7-mini")]))
        )

        await catalog.refresh(apiKey: "sk-test")

        #expect(catalog.options.map(\.id) == ["gpt-7", "gpt-7-mini"])
        #expect(catalog.isLive)
    }

    @Test("A failed fetch leaves the list untouched")
    func failedFetchKeepsPreviousList() async {
        let catalog = OpenAIModelCatalog(client: StubOpenAICatalogClient(.failure(.networkUnavailable)))

        await catalog.refresh(apiKey: "sk-test")

        #expect(catalog.options == OpenAIModelOption.builtInOptions)
        #expect(!catalog.isLive)
    }

    @Test("A fresh cache short-circuits the next refresh")
    func honorsTimeToLive() async {
        let client = StubOpenAICatalogClient(.success([liveOption("gpt-7")]))
        var now = Date(timeIntervalSince1970: 1_000_000)
        let catalog = OpenAIModelCatalog(client: client, timeToLive: 3600, now: { now })

        await catalog.refreshIfNeeded(apiKey: "sk-test")
        now = now.addingTimeInterval(60)
        await catalog.refreshIfNeeded(apiKey: "sk-test")
        #expect(await client.recordedCallCount() == 1)

        now = now.addingTimeInterval(3600)
        await catalog.refreshIfNeeded(apiKey: "sk-test")
        #expect(await client.recordedCallCount() == 2)
    }

    // MARK: - Selection

    @Test("A model newer than this binary survives when the list isn't live")
    func keepsUnknownSelectionWhenNotLive() {
        let catalog = OpenAIModelCatalog(client: StubOpenAICatalogClient(.success([])))
        #expect(catalog.resolvedSelection(for: "gpt-9") == "gpt-9")
    }

    @Test("A retired selection falls back to the default model when the live list has it")
    func retiredSelectionPrefersDefault() async {
        // The live list is newest-first, so "the first entry" would
        // be the most expensive flagship — not a safe replacement.
        let catalog = OpenAIModelCatalog(
            client: StubOpenAICatalogClient(.success([
                liveOption("gpt-6-astra"),
                liveOption(OpenAIModel.default.rawValue)
            ]))
        )

        await catalog.refresh(apiKey: "sk-test")

        #expect(catalog.resolvedSelection(for: "gpt-4-retired") == OpenAIModel.default.rawValue)
    }

    @Test("A retired selection falls back to the first live entry when the default is absent")
    func retiredSelectionFallsBackToFirst() async {
        let catalog = OpenAIModelCatalog(client: StubOpenAICatalogClient(.success([liveOption("gpt-7")])))

        await catalog.refresh(apiKey: "sk-test")

        #expect(catalog.resolvedSelection(for: "gpt-4-retired") == "gpt-7")
    }

    @Test("An unknown identifier still renders a readable name")
    func displayNameFallsBackToDerivedName() {
        let catalog = OpenAIModelCatalog(client: StubOpenAICatalogClient(.success([])))
        #expect(catalog.displayName(for: "gpt-9-nova") == "GPT-9 Nova")
    }
}
