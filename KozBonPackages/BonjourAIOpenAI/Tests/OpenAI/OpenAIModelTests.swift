//
//  OpenAIModelTests.swift
//  BonjourAIOpenAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourAICore
import BonjourStorage
@testable import BonjourAIOpenAI

// MARK: - OpenAIModelTests

@Suite("OpenAIModel")
struct OpenAIModelTests {

    @Test("The default agrees with the provider's and the storage layer's defaults")
    func defaultMatchesProviderDefault() {
        // Three modules each name the default; nothing but this test
        // stops them drifting apart.
        #expect(OpenAIModel.default.rawValue == AICloudProvider.openai.defaultModelIdentifier)
        #expect(OpenAIModel.default.rawValue == UserPreferences.defaultAIOpenAIModelRawValue)
    }

    @Test("An unknown or missing identifier resolves to the default")
    func resolvesUnknownToDefault() {
        #expect(OpenAIModel.resolved(rawValue: nil) == .default)
        #expect(OpenAIModel.resolved(rawValue: "") == .default)
        #expect(OpenAIModel.resolved(rawValue: "gpt-99") == .default)
        #expect(OpenAIModel.resolved(rawValue: "gpt-5.4-nano") == .nano)
    }

    @Test("Every case has a distinct display name and description")
    func displayStringsAreDistinct() {
        let names = Set(OpenAIModel.allCases.map(\.displayName))
        let descriptions = Set(OpenAIModel.allCases.map(\.shortDescription))
        #expect(names.count == OpenAIModel.allCases.count)
        #expect(descriptions.count == OpenAIModel.allCases.count)
    }

    @Test("Built-in options mirror the enum and are all flagged built-in")
    func builtInOptionsMirrorTheEnum() {
        let options = OpenAIModelOption.builtInOptions
        #expect(options.map(\.id) == OpenAIModel.allCases.map(\.rawValue))
        let allBuiltIn = options.allSatisfy(\.isBuiltIn)
        #expect(allBuiltIn)
    }

    @Test(
        "Display names are derived from identifiers",
        arguments: [
            ("gpt-5.4-mini", "GPT-5.4 Mini"),
            ("gpt-6-astra", "GPT-6 Astra"),
            ("gpt-4.1", "GPT-4.1"),
            ("o4-mini", "o4-mini"),
            ("gpt", "gpt")
        ]
    )
    func derivesDisplayName(identifier: String, expected: String) {
        #expect(OpenAIModelOption.displayName(forIdentifier: identifier) == expected)
    }
}

// MARK: - OpenAIConfigurationTests

@Suite("OpenAIConfiguration")
struct OpenAIConfigurationTests {

    @Test("The default base URL literal is well-formed")
    func defaultBaseURLIsValid() {
        // Tripwire for the `URL(string:)` fallback — a malformed
        // literal would silently become `/dev/null`.
        #expect(OpenAIConfiguration.defaultBaseURL.absoluteString == OpenAIConfiguration.defaultBaseURLString)
        #expect(!OpenAIConfiguration.defaultBaseURL.isFileURL)
    }

    @Test("Defaults are applied when nothing is passed")
    func appliesDefaults() {
        let configuration = OpenAIConfiguration()
        #expect(configuration.model == .default)
        #expect(configuration.apiVersion == "v1")
    }
}
