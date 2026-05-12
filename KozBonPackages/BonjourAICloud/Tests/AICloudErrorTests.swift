//
//  AICloudErrorTests.swift
//  BonjourAICloud
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourAICloud

// MARK: - AICloudErrorTests

@Suite("AICloudError")
struct AICloudErrorTests {

    @Test("Every case has a non-empty `errorDescription`")
    func allCasesHaveDescriptions() {
        let cases: [AICloudError] = [
            .missingCredentials(provider: .anthropic),
            .invalidCredentials(provider: .anthropic),
            .rateLimited(provider: .anthropic, retryAfterSeconds: nil),
            .rateLimited(provider: .anthropic, retryAfterSeconds: 30),
            .serverError(provider: .anthropic, message: nil),
            .serverError(provider: .anthropic, message: "overloaded"),
            .networkUnavailable,
            .decodingFailure(message: "missing 'content' field"),
            .keychainFailure(status: -25_300),
            .cancelled,
            .unexpectedStatus(provider: .anthropic, statusCode: 418)
        ]

        for error in cases {
            #expect(error.errorDescription?.isEmpty == false, "no description for \(error)")
        }
    }

    @Test("Equatable conformance distinguishes provider context")
    func equatablePerCase() {
        #expect(AICloudError.cancelled == AICloudError.cancelled)
        #expect(AICloudError.networkUnavailable != AICloudError.cancelled)
        #expect(
            AICloudError.missingCredentials(provider: .anthropic) ==
            AICloudError.missingCredentials(provider: .anthropic)
        )
    }

    @Test("Rate-limit description includes the retry interval when present")
    func rateLimitDescriptionIncludesRetry() {
        let withRetry = AICloudError.rateLimited(provider: .anthropic, retryAfterSeconds: 30)
        let withoutRetry = AICloudError.rateLimited(provider: .anthropic, retryAfterSeconds: nil)

        #expect(withRetry.errorDescription?.contains("30") == true)
        #expect(withoutRetry.errorDescription?.contains("Retry after") == false)
    }
}
