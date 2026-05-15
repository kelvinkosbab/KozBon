//
//  AICloudErrorTests.swift
//  BonjourAICore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourAICore

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
            .invalidRequest(provider: .anthropic, message: nil),
            .invalidRequest(provider: .anthropic, message: "model not found"),
            .creditBalanceTooLow(provider: .anthropic, message: nil),
            .creditBalanceTooLow(provider: .anthropic, message: "Your credit balance is too low"),
            .permissionDenied(provider: .anthropic, message: nil),
            .permissionDenied(provider: .anthropic, message: "Plan does not include this model"),
            .contextWindowExceeded(provider: .anthropic, message: nil),
            .contextWindowExceeded(provider: .anthropic, message: "prompt is too long"),
            .serviceOverloaded(provider: .anthropic, message: nil),
            .serviceOverloaded(provider: .anthropic, message: "Service overloaded"),
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

    @Test("`invalidRequest` surfaces the provider's API error message")
    func invalidRequestSurfacesMessage() {
        // The whole point of this case existing — a 400 from
        // Anthropic carries a specific reason ("model not
        // found", "max_tokens exceeds…") and users need to see
        // it to act on it. The previous `.unexpectedStatus`
        // routing logged only the status code.
        let withMessage = AICloudError.invalidRequest(
            provider: .anthropic,
            message: "model: claude-opus-4-5 not found"
        )
        let withoutMessage = AICloudError.invalidRequest(provider: .anthropic, message: nil)

        #expect(withMessage.errorDescription?.contains("model: claude-opus-4-5 not found") == true)
        #expect(withoutMessage.errorDescription?.contains("rejected the request") == true)
    }

    @Test("`permissionDenied` surfaces the provider's plan-tier message")
    func permissionDeniedSurfacesMessage() {
        // 403 carries a per-account explanation like "Your plan
        // does not include access to claude-opus-4-1". Carved
        // out from `.invalidCredentials` so the chat banner can
        // route to plans management instead of the sign-in
        // sheet (the key is fine; the account's permission set
        // isn't).
        let withMessage = AICloudError.permissionDenied(
            provider: .anthropic,
            message: "Plan does not include claude-opus-4-1"
        )
        let withoutMessage = AICloudError.permissionDenied(provider: .anthropic, message: nil)

        #expect(withMessage.errorDescription?.contains("Plan does not include claude-opus-4-1") == true)
        #expect(withoutMessage.errorDescription?.contains("denied access") == true)
    }

    @Test("`contextWindowExceeded` surfaces the model's length-limit message")
    func contextWindowExceededSurfacesMessage() {
        // Carved out from `.invalidRequest` so the chat banner
        // can attach a Clear-chat action — the user-facing fix
        // is in-app (truncate the history), not at the provider
        // console.
        let withMessage = AICloudError.contextWindowExceeded(
            provider: .anthropic,
            message: "prompt is too long: 200000 tokens > 199998 maximum"
        )
        let withoutMessage = AICloudError.contextWindowExceeded(provider: .anthropic, message: nil)

        #expect(withMessage.errorDescription?.contains("prompt is too long") == true)
        #expect(withoutMessage.errorDescription?.contains("context window") == true)
    }

    @Test("`serviceOverloaded` surfaces the overload message")
    func serviceOverloadedSurfacesMessage() {
        // Carved out from `.serverError` so the chat banner can
        // offer a status-page link — distinct from a generic 5xx
        // where there's no further recourse.
        let withMessage = AICloudError.serviceOverloaded(
            provider: .anthropic,
            message: "Service is currently overloaded"
        )
        let withoutMessage = AICloudError.serviceOverloaded(provider: .anthropic, message: nil)

        #expect(withMessage.errorDescription?.contains("Service is currently overloaded") == true)
        #expect(withoutMessage.errorDescription?.contains("overloaded") == true)
    }

    @Test("`creditBalanceTooLow` surfaces the provider's billing message")
    func creditBalanceTooLowSurfacesMessage() {
        // Carved out from `.invalidRequest` so the chat surface
        // can attach a billing-console deep link to this exact
        // failure mode. The API message ("Your credit balance is
        // too low…") flows through unchanged so users see what
        // Anthropic actually said.
        let withMessage = AICloudError.creditBalanceTooLow(
            provider: .anthropic,
            message: "Your credit balance is too low to access the Anthropic API."
        )
        let withoutMessage = AICloudError.creditBalanceTooLow(
            provider: .anthropic,
            message: nil
        )

        #expect(withMessage.errorDescription?.contains("Your credit balance is too low") == true)
        #expect(withoutMessage.errorDescription?.contains("credit balance is too low") == true)
    }
}
