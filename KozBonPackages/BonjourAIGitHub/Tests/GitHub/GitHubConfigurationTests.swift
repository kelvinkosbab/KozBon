//
//  GitHubConfigurationTests.swift
//  BonjourAIGitHub
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourAIGitHub

// MARK: - GitHubConfigurationTests

@Suite("GitHubConfiguration")
struct GitHubConfigurationTests {

    @Test("Default initializer uses production values")
    func defaultInitProductionValues() {
        let config = GitHubConfiguration()
        #expect(config.baseURL == GitHubConfiguration.defaultBaseURL)
        #expect(config.model == GitHubConfiguration.defaultModel)
        #expect(config.maxResponseTokens == GitHubConfiguration.defaultMaxResponseTokens)
    }

    @Test("Overrides are honored")
    func overridesRespected() throws {
        let customURL = try #require(URL(string: "https://example.test"))
        let config = GitHubConfiguration(
            baseURL: customURL,
            model: "gpt-4o-mini",
            maxResponseTokens: 4096
        )

        #expect(config.baseURL == customURL)
        #expect(config.model == "gpt-4o-mini")
        #expect(config.maxResponseTokens == 4096)
    }

    @Test("`defaultBaseURL` resolves to the documented GitHub Models endpoint")
    func defaultBaseURLIsValid() {
        // Tripwire — if the string in `defaultBaseURLString` is
        // ever malformed (typo on a future bump), the fallback in
        // `defaultBaseURL` would silently produce a `/dev/null`
        // URL and live traffic would fail mysteriously.
        #expect(GitHubConfiguration.defaultBaseURL.absoluteString ==
                GitHubConfiguration.defaultBaseURLString)
        #expect(GitHubConfiguration.defaultBaseURL.scheme == "https")
        #expect(GitHubConfiguration.defaultBaseURL.host() == "models.inference.ai.azure.com")
    }

    @Test("Default model is `gpt-4o`")
    func defaultModelIsGPT4o() {
        // The brief pins this — v1 of the GitHub backend offers no
        // model picker. If a future bump introduces selection,
        // this test should be removed alongside the new picker.
        #expect(GitHubConfiguration.defaultModel == "gpt-4o")
    }

    @Test("Default max response tokens is a sane upper bound")
    func defaultMaxResponseTokensSane() {
        #expect(GitHubConfiguration.defaultMaxResponseTokens > 0)
        #expect(GitHubConfiguration.defaultMaxResponseTokens <= 4096)
    }
}
