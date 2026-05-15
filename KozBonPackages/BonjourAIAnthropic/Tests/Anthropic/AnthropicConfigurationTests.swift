//
//  AnthropicConfigurationTests.swift
//  BonjourAIAnthropic
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourAIAnthropic

// MARK: - AnthropicConfigurationTests

@Suite("AnthropicConfiguration")
struct AnthropicConfigurationTests {

    @Test("Default initializer uses production values")
    func defaultInitProductionValues() {
        let config = AnthropicConfiguration()
        #expect(config.baseURL == AnthropicConfiguration.defaultBaseURL)
        #expect(config.apiVersion == AnthropicConfiguration.defaultAPIVersion)
        #expect(config.model == .default)
        #expect(config.maxResponseTokens == AnthropicConfiguration.defaultMaxResponseTokens)
    }

    @Test("Overrides are honored")
    func overridesRespected() throws {
        let customURL = try #require(URL(string: "https://example.test"))
        let config = AnthropicConfiguration(
            baseURL: customURL,
            apiVersion: "2099-01-01",
            model: .opus,
            maxResponseTokens: 4096
        )

        #expect(config.baseURL == customURL)
        #expect(config.apiVersion == "2099-01-01")
        #expect(config.model == .opus)
        #expect(config.maxResponseTokens == 4096)
    }

    @Test("`defaultBaseURL` resolves to the documented Anthropic endpoint")
    func defaultBaseURLIsValid() {
        // Tripwire — if the string in `defaultBaseURLString` is
        // ever malformed (typo on a future bump), the fallback in
        // `defaultBaseURL` would silently produce a `/dev/null`
        // URL and live traffic would fail mysteriously. This test
        // catches the malformation at build time instead.
        #expect(AnthropicConfiguration.defaultBaseURL.absoluteString ==
                AnthropicConfiguration.defaultBaseURLString)
        #expect(AnthropicConfiguration.defaultBaseURL.scheme == "https")
        #expect(AnthropicConfiguration.defaultBaseURL.host() == "api.anthropic.com")
    }

    @Test("Default API version is pinned to a stable value")
    func defaultAPIVersionIsPinned() {
        // ADR 0005 requires that the API version header is pinned
        // so a future Anthropic version bump doesn't silently break
        // the streaming decoder. Lock the default here as a tripwire
        // — when this test fails the developer is forced to consider
        // whether the streaming decoder still works against the new
        // version.
        #expect(AnthropicConfiguration.defaultAPIVersion == "2023-06-01")
    }

    @Test("Default max response tokens is a sane upper bound")
    func defaultMaxResponseTokensSane() {
        #expect(AnthropicConfiguration.defaultMaxResponseTokens > 0)
        #expect(AnthropicConfiguration.defaultMaxResponseTokens <= 4096)
    }
}
