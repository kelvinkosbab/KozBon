//
//  GeminiModelCatalogTests.swift
//  BonjourAIGemini
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourAICore
@testable import BonjourAIGemini

// MARK: - Stub Client

/// Records calls and replays a canned outcome so every tier of the
/// catalog can be exercised without a network.
private actor StubGeminiCatalogClient: GeminiModelCatalogClientProtocol {

    enum Outcome: Sendable {
        case success([GeminiModelOption])
        case failure(AICloudError)
    }

    private let outcome: Outcome
    private(set) var callCount = 0

    init(_ outcome: Outcome) {
        self.outcome = outcome
    }

    func listModels(apiKey: String) async throws -> [GeminiModelOption] {
        callCount += 1
        switch outcome {
        case .success(let options): return options
        case .failure(let error):   throw error
        }
    }

    func recordedCallCount() async -> Int { callCount }
}

private func liveOption(_ id: String, _ name: String) -> GeminiModelOption {
    GeminiModelOption(id: id, displayName: name, isBuiltIn: false)
}

// MARK: - GeminiModelCatalogTests

/// Pins the same three-tier resolution the Claude picker relies
/// on: a live fetch wins, a stale-but-present list survives a
/// failure, and the compiled-in list is the offline floor.
@Suite("GeminiModelCatalog")
@MainActor
struct GeminiModelCatalogTests {

    // MARK: - Offline Floor

    @Test("A fresh catalog starts on the compiled-in list so the picker is never empty")
    func startsWithBuiltInOptions() {
        let catalog = GeminiModelCatalog(client: StubGeminiCatalogClient(.success([])))
        #expect(catalog.options == GeminiModelOption.builtInOptions)
        #expect(!catalog.isLive)
    }

    @Test("With no key configured, nothing is fetched")
    func skipsFetchWithoutKey() async {
        let client = StubGeminiCatalogClient(.success([liveOption("gemini-3.0", "Gemini 3.0")]))
        let catalog = GeminiModelCatalog(client: client)

        await catalog.refresh(apiKey: nil)
        await catalog.refresh(apiKey: "")

        #expect(await client.recordedCallCount() == 0)
        #expect(!catalog.isLive)
    }

    // MARK: - Live Fetch

    @Test("A successful fetch replaces the list and marks it live")
    func successfulFetchReplacesOptions() async {
        let client = StubGeminiCatalogClient(.success([
            liveOption("gemini-3.0-pro", "Gemini 3.0 Pro"),
            liveOption("gemini-3.0-flash", "Gemini 3.0 Flash"),
        ]))
        let catalog = GeminiModelCatalog(client: client)

        await catalog.refresh(apiKey: "AIzaTEST")

        #expect(catalog.options.map(\.id) == ["gemini-3.0-pro", "gemini-3.0-flash"])
        #expect(catalog.isLive)
    }

    @Test("An empty response keeps the previous list rather than emptying the picker")
    func emptyResponseKeepsPreviousList() async {
        let catalog = GeminiModelCatalog(client: StubGeminiCatalogClient(.success([])))

        await catalog.refresh(apiKey: "AIzaTEST")

        #expect(catalog.options == GeminiModelOption.builtInOptions)
        #expect(!catalog.isLive)
    }

    @Test("A failed fetch leaves the list untouched")
    func failedFetchKeepsPreviousList() async {
        let catalog = GeminiModelCatalog(
            client: StubGeminiCatalogClient(.failure(.networkUnavailable))
        )

        await catalog.refresh(apiKey: "AIzaTEST")

        #expect(catalog.options == GeminiModelOption.builtInOptions)
        #expect(!catalog.isLive)
    }

    // MARK: - Caching

    @Test("A fresh cache short-circuits the next refresh")
    func honorsTimeToLive() async {
        let client = StubGeminiCatalogClient(.success([liveOption("gemini-3.0", "Gemini 3.0")]))
        var now = Date(timeIntervalSince1970: 1_000_000)
        let catalog = GeminiModelCatalog(client: client, timeToLive: 3600, now: { now })

        await catalog.refreshIfNeeded(apiKey: "AIzaTEST")
        #expect(await client.recordedCallCount() == 1)

        // Well inside the TTL — opening Settings again costs
        // nothing.
        now = now.addingTimeInterval(60)
        await catalog.refreshIfNeeded(apiKey: "AIzaTEST")
        #expect(await client.recordedCallCount() == 1)

        // Past it, so a newly-released model shows up the same day.
        now = now.addingTimeInterval(3600)
        await catalog.refreshIfNeeded(apiKey: "AIzaTEST")
        #expect(await client.recordedCallCount() == 2)
    }

    // MARK: - Selection

    @Test("A model newer than this binary survives when the list isn't live")
    func keepsUnknownSelectionWhenNotLive() {
        // This is the bug the whole design exists to avoid: falling
        // back to the compiled-in list would discard a perfectly
        // valid new model just because the app predates it.
        let catalog = GeminiModelCatalog(client: StubGeminiCatalogClient(.success([])))
        #expect(catalog.resolvedSelection(for: "gemini-4.0-ultra") == "gemini-4.0-ultra")
    }

    @Test("A live list that omits the selection replaces it")
    func replacesRetiredSelectionWhenLive() async {
        let client = StubGeminiCatalogClient(.success([liveOption("gemini-3.0", "Gemini 3.0")]))
        let catalog = GeminiModelCatalog(client: client)

        await catalog.refresh(apiKey: "AIzaTEST")

        // Authoritative evidence the old model is gone.
        #expect(catalog.resolvedSelection(for: "gemini-1.0-retired") == "gemini-3.0")
    }

    @Test("A selection present in the live list is left alone")
    func keepsPresentSelection() async {
        let client = StubGeminiCatalogClient(.success([
            liveOption("gemini-3.0-pro", "Gemini 3.0 Pro"),
            liveOption("gemini-3.0-flash", "Gemini 3.0 Flash"),
        ]))
        let catalog = GeminiModelCatalog(client: client)

        await catalog.refresh(apiKey: "AIzaTEST")

        #expect(catalog.resolvedSelection(for: "gemini-3.0-flash") == "gemini-3.0-flash")
    }

    @Test("An unknown identifier still renders as itself rather than blank")
    func displayNameFallsBackToIdentifier() {
        let catalog = GeminiModelCatalog(client: StubGeminiCatalogClient(.success([])))
        #expect(catalog.displayName(for: "gemini-4.0-ultra") == "gemini-4.0-ultra")
    }
}
