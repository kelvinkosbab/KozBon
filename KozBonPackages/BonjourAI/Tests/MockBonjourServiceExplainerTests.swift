//
//  MockBonjourServiceExplainerTests.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourCore
import BonjourModels
@testable import BonjourAI

// MARK: - MockBonjourServiceExplainerTests

@Suite("MockBonjourServiceExplainer")
@MainActor
struct MockBonjourServiceExplainerTests {

    // MARK: - Helpers

    private func makeService() -> BonjourService {
        let serviceType = BonjourServiceType(
            name: "HTTP",
            type: "http",
            transportLayer: .tcp
        )
        return BonjourService(
            service: NetService(
                domain: "local.",
                type: serviceType.fullType,
                name: "Test Device",
                port: 8080
            ),
            serviceType: serviceType
        )
    }

    // MARK: - Initial State

    @Test("Default-initialized explainer is available, idle, and has zero recorded calls")
    func defaultInitIsAvailable() {
        let mock = MockBonjourServiceExplainer()
        #expect(mock.isAvailable)
        #expect(mock.explanation.isEmpty)
        #expect(!mock.isGenerating)
        #expect(mock.error == nil)
        #expect(mock.explainCallCount == 0)
    }

    @Test("`isAvailable: false` constructor flag lets tests simulate the no-AI-on-device path")
    func initWithUnavailable() {
        let mock = MockBonjourServiceExplainer(isAvailable: false)
        #expect(!mock.isAvailable)
    }

    @Test("`cannedExplanation:` constructor parameter is stored verbatim for later replay")
    func initWithCustomExplanation() {
        let mock = MockBonjourServiceExplainer(cannedExplanation: "Custom response")
        #expect(mock.cannedExplanation == "Custom response")
    }

    // MARK: - Explain

    @Test("`explain(service:)` writes the canned explanation, bumps the counter, and clears flags/error")
    func explainSetsCannedExplanation() async {
        let mock = MockBonjourServiceExplainer(cannedExplanation: "Test explanation")
        let service = makeService()
        await mock.explain(service: service)
        #expect(mock.explanation == "Test explanation")
        #expect(mock.explainCallCount == 1)
        #expect(!mock.isGenerating)
        #expect(mock.error == nil)
    }

    @Test("Each `explain(service:)` call increments `explainCallCount`")
    func explainIncrementsCallCount() async {
        let mock = MockBonjourServiceExplainer()
        let service = makeService()
        await mock.explain(service: service)
        await mock.explain(service: service)
        #expect(mock.explainCallCount == 2)
    }

    @Test("Mutating `cannedExplanation` mid-test changes what subsequent `explain` calls return")
    func explainResetsState() async {
        let mock = MockBonjourServiceExplainer(cannedExplanation: "First")
        let service = makeService()
        await mock.explain(service: service)
        #expect(mock.explanation == "First")

        mock.cannedExplanation = "Second"
        await mock.explain(service: service)
        #expect(mock.explanation == "Second")
    }

    // MARK: - Expertise Level

    @Test("Default `expertiseLevel` is `.basic`, matching the Preferences default for first-launch users")
    func defaultExpertiseLevelIsBasic() {
        let mock = MockBonjourServiceExplainer()
        #expect(mock.expertiseLevel == .basic)
    }

    @Test("`expertiseLevel` is mutable so tests can simulate user changes from Preferences")
    func expertiseLevelCanBeChanged() {
        let mock = MockBonjourServiceExplainer()
        mock.expertiseLevel = .technical
        #expect(mock.expertiseLevel == .technical)
    }

    // MARK: - Explain Service Type

    @Test("`explain(serviceType:)` writes the canned explanation and bumps the counter")
    func explainServiceTypeSetsExplanation() async {
        let mock = MockBonjourServiceExplainer(cannedExplanation: "Type explanation")
        let serviceType = BonjourServiceType(
            name: "HTTP", type: "http", transportLayer: .tcp
        )
        await mock.explain(serviceType: serviceType)
        #expect(mock.explanation == "Type explanation")
        #expect(mock.explainCallCount == 1)
        #expect(!mock.isGenerating)
    }

    @Test("Each `explain(serviceType:)` call increments `explainCallCount`")
    func explainServiceTypeIncrementsCallCount() async {
        let mock = MockBonjourServiceExplainer()
        let serviceType = BonjourServiceType(
            name: "HTTP", type: "http", transportLayer: .tcp
        )
        await mock.explain(serviceType: serviceType)
        await mock.explain(serviceType: serviceType)
        #expect(mock.explainCallCount == 2)
    }

    @Test("Both `explain` overloads share `explainCallCount` — total reflects either entry point")
    func mixedExplainCallsShareCallCount() async {
        let mock = MockBonjourServiceExplainer()
        let service = makeService()
        let serviceType = BonjourServiceType(
            name: "HTTP", type: "http", transportLayer: .tcp
        )
        await mock.explain(service: service)
        await mock.explain(serviceType: serviceType)
        #expect(mock.explainCallCount == 2)
    }

    // MARK: - isPublished Parameter

    @Test("`explain(service:isPublished: true)` works the same as the default-published path")
    func explainServiceWithIsPublishedWorks() async {
        let mock = MockBonjourServiceExplainer(cannedExplanation: "Published explanation")
        let service = makeService()
        await mock.explain(service: service, isPublished: true)
        #expect(mock.explanation == "Published explanation")
        #expect(mock.explainCallCount == 1)
    }

    @Test("`explain(service:)` defaults `isPublished` to false (the discovered framing)")
    func explainServiceDefaultIsPublishedIsFalse() async {
        let mock = MockBonjourServiceExplainer(cannedExplanation: "Discovered explanation")
        let service = makeService()
        await mock.explain(service: service)
        #expect(mock.explanation == "Discovered explanation")
    }

    // MARK: - Availability

    @Test("Default-initialized mock advertises itself as available so the Insights flow renders")
    func availableByDefault() {
        let mock = MockBonjourServiceExplainer()
        #expect(mock.isAvailable)
    }

    @Test("Mock honors `isAvailable: false` so tests can exercise the unavailable UI branch")
    func unavailableWhenConfigured() {
        let mock = MockBonjourServiceExplainer(isAvailable: false)
        #expect(!mock.isAvailable)
    }
}
