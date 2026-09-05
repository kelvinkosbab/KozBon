//
//  AnthropicModelCatalogTests.swift
//  BonjourAIAnthropic
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourAICore
@testable import BonjourAIAnthropic

// MARK: - Stub Client

/// Records calls and replays a canned outcome so every tier of the
/// catalog can be exercised without a network.
private actor StubCatalogClient: AnthropicModelCatalogClientProtocol {

    enum Outcome: Sendable {
        case success([AnthropicModelOption])
        case failure(AICloudError)
    }

    private let outcome: Outcome
    private(set) var callCount = 0
    private(set) var lastAPIKey: String?

    init(_ outcome: Outcome) {
        self.outcome = outcome
    }

    func listModels(apiKey: String) async throws -> [AnthropicModelOption] {
        callCount += 1
        lastAPIKey = apiKey
        switch outcome {
        case .success(let options): return options
        case .failure(let error):   throw error
        }
    }

    func recordedCallCount() async -> Int { callCount }
    func recordedAPIKey() async -> String? { lastAPIKey }
}

private func liveOption(_ id: String, _ name: String) -> AnthropicModelOption {
    AnthropicModelOption(id: id, displayName: name, isBuiltIn: false)
}

// MARK: - AnthropicModelCatalogTests

/// Pins the three-tier resolution the Settings picker depends on:
/// a live fetch wins, a stale-but-present list is kept on failure,
/// and the compiled-in list is the offline floor.
@Suite("AnthropicModelCatalog")
@MainActor
struct AnthropicModelCatalogTests {

    // MARK: - Fallback Tier

    @Test("Before any fetch, the catalog serves the built-in fallback list")
    func startsWithBuiltInOptions() {
        let catalog = AnthropicModelCatalog(client: StubCatalogClient(.success([])))
        #expect(catalog.options == AnthropicModelOption.builtInOptions)
        #expect(!catalog.isLive)
        let allBuiltIn = catalog.options.allSatisfy { $0.isBuiltIn }
        #expect(allBuiltIn)
    }

    @Test("A nil or empty API key skips the network entirely")
    func missingKeySkipsFetch() async {
        let client = StubCatalogClient(.success([liveOption("claude-opus-5", "Claude Opus 5")]))
        let catalog = AnthropicModelCatalog(client: client)

        await catalog.refresh(apiKey: nil)
        await catalog.refresh(apiKey: "")

        let callCount = await client.recordedCallCount()
        #expect(callCount == 0)
        #expect(!catalog.isLive)
        #expect(catalog.options == AnthropicModelOption.builtInOptions)
    }

    // MARK: - Live Tier

    @Test("A successful fetch replaces the list and marks it live")
    func successfulFetchReplacesOptions() async {
        let fetched = [
            liveOption("claude-opus-5", "Claude Opus 5"),
            liveOption("claude-sonnet-5", "Claude Sonnet 5")
        ]
        let client = StubCatalogClient(.success(fetched))
        let catalog = AnthropicModelCatalog(client: client)

        await catalog.refresh(apiKey: "sk-test")

        #expect(catalog.options == fetched)
        #expect(catalog.isLive)
        #expect(catalog.lastRefreshDate != nil)
        let sentKey = await client.recordedAPIKey()
        #expect(sentKey == "sk-test")
    }

    @Test("A failed fetch keeps the previous list rather than emptying the picker")
    func failedFetchKeepsPreviousOptions() async {
        let client = StubCatalogClient(.failure(.networkUnavailable))
        let catalog = AnthropicModelCatalog(client: client)

        await catalog.refresh(apiKey: "sk-test")

        #expect(catalog.options == AnthropicModelOption.builtInOptions)
        #expect(!catalog.isLive)
    }

    @Test("An empty response is ignored — an empty picker is worse than a stale one")
    func emptyResponseIsIgnored() async {
        let client = StubCatalogClient(.success([]))
        let catalog = AnthropicModelCatalog(client: client)

        await catalog.refresh(apiKey: "sk-test")

        #expect(catalog.options == AnthropicModelOption.builtInOptions)
        #expect(!catalog.isLive)
    }

    // MARK: - Caching / TTL

    @Test("`refreshIfNeeded` fetches once while the cache is fresh")
    func refreshIfNeededHonorsTTL() async {
        let client = StubCatalogClient(.success([liveOption("claude-opus-5", "Claude Opus 5")]))
        var clock = Date(timeIntervalSince1970: 1_000_000)
        let catalog = AnthropicModelCatalog(
            client: client,
            timeToLive: 3600,
            now: { clock }
        )

        await catalog.refreshIfNeeded(apiKey: "sk-test")
        // Still inside the TTL — must not hit the network again.
        clock.addTimeInterval(60)
        await catalog.refreshIfNeeded(apiKey: "sk-test")

        let callCount = await client.recordedCallCount()
        #expect(callCount == 1)
    }

    @Test("`refreshIfNeeded` fetches again once the TTL lapses")
    func refreshIfNeededRefetchesAfterTTL() async {
        let client = StubCatalogClient(.success([liveOption("claude-opus-5", "Claude Opus 5")]))
        var clock = Date(timeIntervalSince1970: 1_000_000)
        let catalog = AnthropicModelCatalog(
            client: client,
            timeToLive: 3600,
            now: { clock }
        )

        await catalog.refreshIfNeeded(apiKey: "sk-test")
        clock.addTimeInterval(3601)
        await catalog.refreshIfNeeded(apiKey: "sk-test")

        let callCount = await client.recordedCallCount()
        #expect(callCount == 2)
    }

    // MARK: - Selection Resolution

    @Test("A selection present in the list is returned unchanged")
    func knownSelectionIsPreserved() {
        let catalog = AnthropicModelCatalog(client: StubCatalogClient(.success([])))
        let builtIn = AnthropicModel.opus.rawValue
        #expect(catalog.resolvedSelection(for: builtIn) == builtIn)
    }

    @Test("An unknown selection is PRESERVED while the list is only the built-in fallback")
    func unknownSelectionSurvivesWithoutLiveList() {
        // The core regression guard: offline, this binary has never
        // heard of `claude-opus-5`, but it may well be a valid model
        // the user picked while online. Reassigning here would be
        // the old enum bug in a new place.
        let catalog = AnthropicModelCatalog(client: StubCatalogClient(.success([])))
        #expect(!catalog.isLive)
        #expect(catalog.resolvedSelection(for: "claude-opus-5") == "claude-opus-5")
    }

    @Test("An unknown selection is replaced only once a live list proves it is gone")
    func unknownSelectionReplacedWithLiveList() async {
        let fetched = [
            liveOption("claude-opus-5", "Claude Opus 5"),
            liveOption("claude-sonnet-5", "Claude Sonnet 5")
        ]
        let catalog = AnthropicModelCatalog(client: StubCatalogClient(.success(fetched)))
        await catalog.refresh(apiKey: "sk-test")

        #expect(catalog.isLive)
        // Authoritative evidence the retired model is gone — now
        // (and only now) fall forward to the newest entry.
        #expect(catalog.resolvedSelection(for: "claude-retired-1") == "claude-opus-5")
        #expect(catalog.resolvedSelection(for: "claude-sonnet-5") == "claude-sonnet-5")
    }

    // MARK: - Display Names

    @Test("`displayName` uses the catalog entry, falling back to the raw identifier")
    func displayNameResolution() async {
        let catalog = AnthropicModelCatalog(
            client: StubCatalogClient(.success([liveOption("claude-opus-5", "Claude Opus 5")]))
        )
        await catalog.refresh(apiKey: "sk-test")

        #expect(catalog.displayName(for: "claude-opus-5") == "Claude Opus 5")
        // Unknown identifiers still render something meaningful.
        #expect(catalog.displayName(for: "claude-mystery") == "claude-mystery")
    }
}
