//
//  BonjourServiceExplainerFactoryTests.swift
//  BonjourAIApple
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourAIApple
@testable import BonjourAICore

// MARK: - BonjourServiceExplainerFactoryTests

/// Mirror of `BonjourChatSessionFactoryTests` for the Insights
/// explainer factory. The factory is stateless and its only
/// branch lives inside `makeForCurrentEnvironment` — we verify
/// the protocol conformance and the build-env outcome.
@Suite("BonjourServiceExplainerFactory")
@MainActor
struct BonjourServiceExplainerFactoryTests {

    // MARK: - Protocol Conformance

    @Test("Concrete factory satisfies `BonjourServiceExplainerFactoryProtocol`")
    func factoryConformsToProtocol() {
        let factory: any BonjourServiceExplainerFactoryProtocol = BonjourServiceExplainerFactory()
        _ = factory
    }

    // MARK: - makeForCurrentEnvironment

    @Test("`makeForCurrentEnvironment` returns an explainer in environments that have one")
    func makeReturnsExplainerOnSupportedEnvironments() {
        let factory = BonjourServiceExplainerFactory()
        let explainer = factory.makeForCurrentEnvironment()
        #if targetEnvironment(simulator)
        // Simulator branch → SimulatorBonjourServiceExplainer.
        #expect(explainer != nil)
        #elseif canImport(FoundationModels)
        if #available(iOS 26, macOS 26, visionOS 26, *) {
            // Real BonjourServiceExplainer.
            #expect(explainer != nil)
        } else {
            #expect(explainer == nil)
        }
        #else
        // Older SDKs without FoundationModels → nil; the Insights
        // menu item drops the action silently.
        #expect(explainer == nil)
        #endif
    }
}
