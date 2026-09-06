//
//  GeminiModelTests.swift
//  BonjourAIGemini
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourAICore
@testable import BonjourAIGemini

// MARK: - GeminiModelTests

@Suite("GeminiModel")
struct GeminiModelTests {

    @Test("The default agrees with the provider's default identifier")
    func defaultMatchesProviderDefault() {
        // These live in different modules — `AICloudProvider` has
        // to name a default without importing every provider — so
        // nothing but this test stops them drifting apart.
        #expect(GeminiModel.default.rawValue == AICloudProvider.gemini.defaultModelIdentifier)
    }

    @Test("An unknown or missing identifier resolves to the default")
    func resolvesUnknownToDefault() {
        #expect(GeminiModel.resolved(rawValue: nil) == .default)
        #expect(GeminiModel.resolved(rawValue: "") == .default)
        #expect(GeminiModel.resolved(rawValue: "gemini-9.9-imaginary") == .default)
    }

    @Test("A known identifier round-trips")
    func resolvesKnownIdentifier() {
        #expect(GeminiModel.resolved(rawValue: "gemini-2.5-pro") == .pro)
    }

    @Test("Raw values carry no `models/` prefix, which the path builder adds itself")
    func rawValuesAreBareIdentifiers() {
        let prefixed = GeminiModel.allCases.filter { $0.rawValue.hasPrefix("models/") }
        #expect(prefixed.isEmpty)
    }

    @Test("Every case has a distinct display name and description")
    func displayStringsAreDistinct() {
        let names = Set(GeminiModel.allCases.map(\.displayName))
        let descriptions = Set(GeminiModel.allCases.map(\.shortDescription))
        #expect(names.count == GeminiModel.allCases.count)
        #expect(descriptions.count == GeminiModel.allCases.count)
    }

    @Test("Built-in options mirror the enum and are all flagged built-in")
    func builtInOptionsMirrorTheEnum() {
        let options = GeminiModelOption.builtInOptions
        #expect(options.map(\.id) == GeminiModel.allCases.map(\.rawValue))
        let allBuiltIn = options.allSatisfy(\.isBuiltIn)
        #expect(allBuiltIn)
    }
}

// MARK: - GeminiConfigurationTests

@Suite("GeminiConfiguration")
struct GeminiConfigurationTests {

    @Test("The default base URL literal is well-formed")
    func defaultBaseURLIsValid() {
        // Tripwire for the `URL(string:)` fallback — a malformed
        // literal would silently become `/dev/null`.
        #expect(GeminiConfiguration.defaultBaseURL.absoluteString
                == GeminiConfiguration.defaultBaseURLString)
        #expect(!GeminiConfiguration.defaultBaseURL.isFileURL)
    }

    @Test("It targets the Developer API, not Vertex")
    func targetsDeveloperAPI() {
        // Vertex needs service-account OAuth, which the
        // paste-an-API-key sheet can't express.
        #expect(GeminiConfiguration.defaultBaseURLString.contains("generativelanguage.googleapis.com"))
    }

    @Test("Defaults are applied when nothing is passed")
    func appliesDefaults() {
        let configuration = GeminiConfiguration()
        #expect(configuration.model == .default)
        #expect(configuration.apiVersion == GeminiConfiguration.defaultAPIVersion)
        #expect(configuration.maxResponseTokens == GeminiConfiguration.defaultMaxResponseTokens)
    }
}
