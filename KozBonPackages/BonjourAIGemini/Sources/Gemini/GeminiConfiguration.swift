//
//  GeminiConfiguration.swift
//  BonjourAIGemini
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourAICore

// MARK: - GeminiConfiguration

/// Static configuration for calls to the Gemini Developer API.
///
/// Bundles what doesn't change between requests inside one chat
/// session — base URL, API version path segment, selected model,
/// and the output-token cap. Per-request payloads are built by the
/// client at send time.
///
/// A value type, so a session captures a snapshot at creation and
/// stays immune to later preference changes — matching
/// ``AnthropicConfiguration`` and the Apple Foundation Models side,
/// where `LanguageModelSession` snapshots its instructions at init.
public struct GeminiConfiguration: Sendable, Equatable {

    // MARK: - Constants

    /// The Gemini Developer API host.
    ///
    /// Deliberately the Developer API rather than Vertex AI:
    /// Vertex authenticates with service-account OAuth, which the
    /// paste-an-API-key sheet in Settings can't express.
    ///
    /// Built with `URL(string:)` and a deterministic fallback for
    /// the same reason ``AnthropicConfiguration`` does;
    /// `GeminiConfigurationTests.defaultBaseURLIsValid` is the
    /// tripwire if the literal is ever malformed.
    public static let defaultBaseURLString = "https://generativelanguage.googleapis.com"
    public static let defaultBaseURL: URL = URL(string: defaultBaseURLString)
        ?? URL(fileURLWithPath: "/dev/null")

    /// The API version path segment KozBon ships with.
    ///
    /// Pinned so a future version that changes the streaming
    /// response shape doesn't silently break the chat surface.
    /// Bumping requires re-verifying the streaming decoder.
    public static let defaultAPIVersion = "v1beta"

    /// Default maximum output tokens per response. Matches the
    /// Anthropic side so answers feel the same length whichever
    /// backend a user picks.
    public static let defaultMaxResponseTokens = 1024

    // MARK: - Properties

    /// The base URL the client builds request paths onto. Override
    /// in tests with a `URLProtocol`-stubbed value to avoid live
    /// network hits.
    public let baseURL: URL

    /// The API version path segment (e.g. `v1beta`).
    public let apiVersion: String

    /// The model the session uses.
    public let model: GeminiModel

    /// Maximum number of output tokens for each response.
    public let maxResponseTokens: Int

    // MARK: - Init

    public init(
        baseURL: URL = GeminiConfiguration.defaultBaseURL,
        apiVersion: String = GeminiConfiguration.defaultAPIVersion,
        model: GeminiModel = .default,
        maxResponseTokens: Int = GeminiConfiguration.defaultMaxResponseTokens
    ) {
        self.baseURL = baseURL
        self.apiVersion = apiVersion
        self.model = model
        self.maxResponseTokens = maxResponseTokens
    }
}
