//
//  BonjourChatViewModelMergeTests.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourCore
import BonjourModels
@testable import BonjourUI

// MARK: - BonjourChatViewModelMergeTests

/// Pins the contract of
/// `BonjourChatViewModel.mergeDiscoveredServices(cached:fresh:)`.
///
/// The merge sits between the chat's 3-second one-shot scan and
/// the Discover tab's continuously-accumulating snapshot — the
/// production fix for "What services are on my network?" answers
/// only listing a couple of devices. Each cached entry survives in
/// its original position, gets overlaid with the fresh-state copy
/// where the same `BonjourService.id` shows up in both arrays,
/// and any fresh-only services append at the end.
@Suite("BonjourChatViewModel · Discovered services merge")
@MainActor
struct BonjourChatViewModelMergeTests {

    // MARK: - Helpers

    /// Builds a `BonjourService` test fixture identical in shape
    /// to the ones the `BonjourChatPromptBuilder` context tests
    /// use. The `(name, type, port)` tuple determines the
    /// underlying `NetService.hashValue`, which `BonjourService`
    /// caches as its stable `id` at init time — so two services
    /// built with the same `(name, type, port)` deliberately have
    /// the same `id`, which is how the "overlapping ids" tests
    /// below construct a "fresh-state copy of the same service".
    private func makeService(
        name: String,
        type: String = "http",
        port: Int32 = 8080
    ) -> BonjourService {
        let serviceType = BonjourServiceType(
            name: type.uppercased(),
            type: type,
            transportLayer: .tcp
        )
        let net = NetService(
            domain: "local.",
            type: serviceType.fullType,
            name: name,
            port: port
        )
        return BonjourService(service: net, serviceType: serviceType)
    }

    // MARK: - Empty Inputs

    @Test("Empty cached + empty fresh produces an empty array")
    func emptyInputsProduceEmpty() {
        let result = BonjourChatViewModel.mergeDiscoveredServices(
            cached: [],
            fresh: []
        )
        #expect(result.isEmpty)
    }

    // MARK: - Single-Side Inputs

    @Test("Cached-only with empty fresh: order preserved verbatim")
    func cachedOnlyPreservesOrder() {
        let a = makeService(name: "A")
        let b = makeService(name: "B")
        let c = makeService(name: "C")

        let result = BonjourChatViewModel.mergeDiscoveredServices(
            cached: [a, b, c],
            fresh: []
        )

        #expect(result.map(\.id) == [a.id, b.id, c.id])
        // Object identity confirms no fresh copies sneaked in.
        #expect(result[0] === a)
        #expect(result[1] === b)
        #expect(result[2] === c)
    }

    @Test("Empty cached with fresh-only: order preserved verbatim")
    func freshOnlyPreservesOrder() {
        let a = makeService(name: "A")
        let b = makeService(name: "B")

        let result = BonjourChatViewModel.mergeDiscoveredServices(
            cached: [],
            fresh: [a, b]
        )

        #expect(result.map(\.id) == [a.id, b.id])
        #expect(result[0] === a)
        #expect(result[1] === b)
    }

    // MARK: - Disjoint Sets

    @Test("Disjoint cached and fresh ids: cached first, then fresh appended")
    func disjointAppendsFreshAtEnd() {
        let cachedA = makeService(name: "CachedA")
        let cachedB = makeService(name: "CachedB")
        let freshC = makeService(name: "FreshC")
        let freshD = makeService(name: "FreshD")

        let result = BonjourChatViewModel.mergeDiscoveredServices(
            cached: [cachedA, cachedB],
            fresh: [freshC, freshD]
        )

        #expect(result.count == 4)
        #expect(result.map(\.id) == [cachedA.id, cachedB.id, freshC.id, freshD.id])
    }

    // MARK: - Overlapping Ids

    @Test("Overlapping id: fresh copy wins, cached position preserved")
    func overlapPrefersFreshAtCachedPosition() {
        let cachedA = makeService(name: "A")
        let cachedB = makeService(name: "B")
        // `freshA` deliberately uses the same (name, type, port)
        // as `cachedA` so the underlying NetService hashes to the
        // same value and the two BonjourServices share an `id`.
        let freshA = makeService(name: "A")

        // Sanity: same id, different class instance.
        #expect(cachedA.id == freshA.id)
        #expect(cachedA !== freshA)

        let result = BonjourChatViewModel.mergeDiscoveredServices(
            cached: [cachedA, cachedB],
            fresh: [freshA]
        )

        // Cached position (index 0) preserved.
        #expect(result.count == 2)
        #expect(result.map(\.id) == [cachedA.id, cachedB.id])
        // But it's the *fresh* instance that lands there.
        #expect(result[0] === freshA)
        #expect(result[0] !== cachedA)
        // The non-overlapping cached entry survives verbatim.
        #expect(result[1] === cachedB)
    }

    @Test("Multiple overlapping ids: every fresh copy wins")
    func multipleOverlapsAllPreferFresh() {
        let cachedA = makeService(name: "A")
        let cachedB = makeService(name: "B")
        let cachedC = makeService(name: "C")
        let freshA = makeService(name: "A")
        let freshC = makeService(name: "C")

        let result = BonjourChatViewModel.mergeDiscoveredServices(
            cached: [cachedA, cachedB, cachedC],
            fresh: [freshA, freshC]
        )

        #expect(result.count == 3)
        #expect(result[0] === freshA)
        #expect(result[1] === cachedB)
        #expect(result[2] === freshC)
    }

    // MARK: - Fresh-Only Tail After Overlap

    @Test("Mixed overlap + fresh-only: overlap at cached positions, fresh-only appended")
    func mixedOverlapAndFreshOnlyAppendsTail() {
        let cachedA = makeService(name: "A")
        let cachedB = makeService(name: "B")
        let freshA = makeService(name: "A")      // overlaps cachedA
        let freshNew = makeService(name: "New")  // fresh-only

        let result = BonjourChatViewModel.mergeDiscoveredServices(
            cached: [cachedA, cachedB],
            fresh: [freshA, freshNew]
        )

        #expect(result.count == 3)
        #expect(result[0] === freshA)
        #expect(result[1] === cachedB)
        #expect(result[2] === freshNew)
    }

    // MARK: - Fresh Duplicates

    @Test("Fresh-only duplicate ids collapse to a single entry")
    func freshDuplicatesAreDeduplicated() {
        let freshA1 = makeService(name: "A")
        let freshA2 = makeService(name: "A")

        // Sanity: duplicates share an id.
        #expect(freshA1.id == freshA2.id)

        let result = BonjourChatViewModel.mergeDiscoveredServices(
            cached: [],
            fresh: [freshA1, freshA2]
        )

        #expect(result.count == 1)
    }

    @Test("Cached duplicate ids collapse to a single entry")
    func cachedDuplicatesAreDeduplicated() {
        let cachedA1 = makeService(name: "A")
        let cachedA2 = makeService(name: "A")

        let result = BonjourChatViewModel.mergeDiscoveredServices(
            cached: [cachedA1, cachedA2],
            fresh: []
        )

        #expect(result.count == 1)
        // The first cached entry survives (insert(.inserted) is
        // true only on first sight).
        #expect(result[0] === cachedA1)
    }
}
