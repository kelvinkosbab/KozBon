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

    @Test func defaultInitIsAvailable() {
        let mock = MockBonjourServiceExplainer()
        #expect(mock.isAvailable)
        #expect(mock.explanation.isEmpty)
        #expect(!mock.isGenerating)
        #expect(mock.error == nil)
        #expect(mock.explainCallCount == 0)
    }

    @Test func initWithUnavailable() {
        let mock = MockBonjourServiceExplainer(isAvailable: false)
        #expect(!mock.isAvailable)
    }

    @Test func initWithCustomExplanation() {
        let mock = MockBonjourServiceExplainer(cannedExplanation: "Custom response")
        #expect(mock.cannedExplanation == "Custom response")
    }

    // MARK: - Explain

    @Test func explainSetsCannedExplanation() async {
        let mock = MockBonjourServiceExplainer(cannedExplanation: "Test explanation")
        let service = makeService()
        await mock.explain(service: service)
        #expect(mock.explanation == "Test explanation")
        #expect(mock.explainCallCount == 1)
        #expect(!mock.isGenerating)
        #expect(mock.error == nil)
    }

    @Test func explainIncrementsCallCount() async {
        let mock = MockBonjourServiceExplainer()
        let service = makeService()
        await mock.explain(service: service)
        await mock.explain(service: service)
        #expect(mock.explainCallCount == 2)
    }

    @Test func explainResetsState() async {
        let mock = MockBonjourServiceExplainer(cannedExplanation: "First")
        let service = makeService()
        await mock.explain(service: service)
        #expect(mock.explanation == "First")

        mock.cannedExplanation = "Second"
        await mock.explain(service: service)
        #expect(mock.explanation == "Second")
    }

    // MARK: - Expertise Level

    @Test func defaultExpertiseLevelIsBasic() {
        let mock = MockBonjourServiceExplainer()
        #expect(mock.expertiseLevel == .basic)
    }

    @Test func expertiseLevelCanBeChanged() {
        let mock = MockBonjourServiceExplainer()
        mock.expertiseLevel = .technical
        #expect(mock.expertiseLevel == .technical)
    }
}
