//
//  InsightsButtonStateTests.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Testing
import BonjourAIApple
import BonjourAICore
@testable import BonjourUI

// MARK: - InsightsButtonStateTests

@Suite("InsightsButtonState")
struct InsightsButtonStateTests {

    private func resolve(
        aiAnalysisEnabled: Bool = true,
        backend: AIBackend,
        availability: AppleIntelligenceSupport.AvailabilityState = .available,
        hasAPIKey: Bool = false,
        canOpenSettings: Bool = true
    ) -> InsightsButtonState {
        InsightsButtonState.resolve(
            aiAnalysisEnabled: aiAnalysisEnabled,
            backend: backend,
            appleIntelligenceAvailability: availability,
            hasAPIKey: hasAPIKey,
            canOpenAppleIntelligenceSettings: canOpenSettings
        )
    }

    @Test("Hidden for every backend when AI analysis is off", arguments: AIBackend.allCases)
    func hiddenWhenAIDisabled(backend: AIBackend) {
        #expect(resolve(aiAnalysisEnabled: false, backend: backend, hasAPIKey: true) == .hidden)
    }

    @Test("Apple Intelligence shows Insights when available")
    func appleAvailable() {
        #expect(resolve(backend: .appleIntelligence) == .explain(.appleIntelligence))
    }

    @Test("Apple Intelligence hides on ineligible devices")
    func appleIneligible() {
        #expect(resolve(backend: .appleIntelligence, availability: .deviceNotEligible) == .hidden)
    }

    @Test(
        "Apple Intelligence offers the enable CTA when it can recover",
        arguments: [
            AppleIntelligenceSupport.AvailabilityState.appleIntelligenceDisabled,
            .modelNotReady,
            .otherUnavailable
        ]
    )
    func appleEnableCTA(availability: AppleIntelligenceSupport.AvailabilityState) {
        #expect(resolve(backend: .appleIntelligence, availability: availability) == .enableAppleIntelligence)
    }

    @Test("Enable CTA hides where Settings can't be opened")
    func appleEnableCTAHiddenWithoutSettingsLink() {
        #expect(
            resolve(backend: .appleIntelligence, availability: .appleIntelligenceDisabled, canOpenSettings: false)
                == .hidden
        )
    }

    @Test("Cloud backends show Insights with a key", arguments: [AIBackend.anthropic, .gemini, .openai])
    func cloudWithKey(backend: AIBackend) {
        #expect(resolve(backend: backend, availability: .deviceNotEligible, hasAPIKey: true) == .explain(backend))
    }

    @Test("Cloud backends offer sign-in without a key", arguments: [AIBackend.anthropic, .gemini, .openai])
    func cloudWithoutKey(backend: AIBackend) throws {
        let provider = try #require(backend.cloudProvider)
        #expect(resolve(backend: backend) == .signIn(backend, provider))
    }
}
