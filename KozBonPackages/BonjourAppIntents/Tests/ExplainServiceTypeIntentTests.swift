//
//  ExplainServiceTypeIntentTests.swift
//  BonjourAppIntents
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Testing
import BonjourAI
@testable import BonjourAppIntents

// MARK: - ExplainServiceTypeIntentTests

@Suite("ExplainServiceTypeIntent")
@MainActor
struct ExplainServiceTypeIntentTests {

    /// The built-in types only; the full lookup also reads Core Data,
    /// which `swift test` can't load.
    private let library = BonjourServiceType.serviceTypeLibrary

    @Test("The explanation is brief and spoken without Markdown")
    func explains() async {
        let explainer = MockBonjourServiceExplainer(cannedExplanation: "## HTTP\n**Web** pages.")
        let bridge = AppIntentsBridge()
        bridge.makeExplainer = { explainer }

        let text = await ExplainServiceTypeIntent.explanation(fullType: "_http._tcp", bridge: bridge, serviceTypes: library)

        #expect(text == "HTTP Web pages.")
        #expect(explainer.responseLength == .brief)
    }

    @Test("No explainer, or an unavailable one, gives nothing")
    func unavailable() async {
        let bridge = AppIntentsBridge()
        #expect(await ExplainServiceTypeIntent.explanation(fullType: "_http._tcp", bridge: bridge, serviceTypes: library) == nil)

        bridge.makeExplainer = { MockBonjourServiceExplainer(isAvailable: false) }
        #expect(await ExplainServiceTypeIntent.explanation(fullType: "_http._tcp", bridge: bridge, serviceTypes: library) == nil)
    }

    @Test("An unknown type gives nothing")
    func unknownType() async {
        let bridge = AppIntentsBridge()
        bridge.makeExplainer = { MockBonjourServiceExplainer() }
        #expect(await ExplainServiceTypeIntent.explanation(fullType: "_nope._tcp", bridge: bridge, serviceTypes: library) == nil)
    }
}
