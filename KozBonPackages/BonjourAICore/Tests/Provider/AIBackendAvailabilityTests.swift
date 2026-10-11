//
//  AIBackendAvailabilityTests.swift
//  BonjourAICore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Testing
@testable import BonjourAICore

// MARK: - AIBackendAvailabilityTests

@Suite("AIBackendAvailability")
@MainActor
struct AIBackendAvailabilityTests {

    @Test("The China mainland storefront withholds OpenAI and nothing else")
    func chinaWithholdsOnlyOpenAI() {
        let availability = AIBackendAvailability(storefrontCountryCode: "CHN")
        #expect(!availability.isOffered(.openai))
        #expect(availability.offeredBackends == [.appleIntelligence, .anthropic, .gemini])
    }

    @Test("Other storefronts offer every backend", arguments: ["USA", "HKG", "TWN", "JPN"])
    func otherStorefrontsOfferEverything(countryCode: String) {
        let availability = AIBackendAvailability(storefrontCountryCode: countryCode)
        #expect(availability.offeredBackends == AIBackend.allCases)
    }

    @Test("An unknown storefront offers every backend")
    func unknownStorefrontOffersEverything() {
        #expect(AIBackendAvailability().offeredBackends == AIBackend.allCases)
    }

    @Test("The country code match ignores case")
    func countryCodeIsCaseInsensitive() {
        #expect(!AIBackendAvailability.isOffered(.openai, inStorefront: "chn"))
    }

    @Test("Updating the storefront changes what's offered")
    func updateChangesOfferedBackends() {
        let availability = AIBackendAvailability(storefrontCountryCode: "USA")
        availability.update(storefrontCountryCode: "CHN")
        #expect(availability.storefrontCountryCode == "CHN")
        #expect(!availability.isOffered(.openai))
    }
}
