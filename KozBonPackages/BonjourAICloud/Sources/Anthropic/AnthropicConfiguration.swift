//
//  AnthropicConfiguration.swift
//  BonjourAICloud
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - AnthropicConfiguration

/// Static configuration for calls to Anthropic's API.
///
/// Bundles the values that don't change between requests within a
/// single chat session — the base URL, the API version header,
/// the selected model, and the maximum response token count.
/// Per-request payloads (the user prompt, the system instructions
/// block, prompt-cache markers) are built by the client at send
/// time.
///
/// Held as a value type so a session can capture a snapshot at
/// creation and remain immune to subsequent preference changes
/// (matching the Apple Foundation Models side, where
/// `LanguageModelSession` snapshots its instructions at init).
public struct AnthropicConfiguration: Sendable, Equatable {

    // MARK: - Constants

    /// Anthropic's base API URL. Hard-coded — Anthropic offers no
    /// regional endpoints and no enterprise self-hosted variant
    /// the consumer SDK would reach.
    ///
    /// Built via `URL(string:)` rather than the `URL(staticString:)`
    /// initializer (which would let us avoid the optional) because
    /// the latter is iOS 17+ and not strictly necessary here — the
    /// expression is constant, evaluated once at module load, and
    /// `defaultBaseURLString` provides a deterministic fallback.
    /// `AnthropicConfigurationTests.defaultBaseURLIsValid` is a
    /// tripwire that fails if the string is ever malformed.
    public static let defaultBaseURLString = "https://api.anthropic.com"
    public static let defaultBaseURL: URL = URL(string: defaultBaseURLString)
        ?? URL(fileURLWithPath: "/dev/null")

    /// The `anthropic-version` header value KozBon ships with.
    ///
    /// Pinned to a specific date so a future API version that
    /// breaks the streaming response shape doesn't silently break
    /// the chat surface. Bumping requires re-verifying the
    /// streaming decoder.
    public static let defaultAPIVersion = "2023-06-01"

    /// Default maximum tokens per response.
    ///
    /// Sized to be generous for Chat (multi-paragraph answers)
    /// while still capping run-away generation. The Insights
    /// surface clamps this further when constructing its session.
    public static let defaultMaxResponseTokens = 1024

    // MARK: - Properties

    /// The base URL the client appends `/v1/messages` to. Override
    /// in tests with `URL(string: "https://127.0.0.1:0")` (or a
    /// `URLProtocol`-stubbed value) to avoid live network hits.
    public let baseURL: URL

    /// The `anthropic-version` request header value.
    public let apiVersion: String

    /// The model the session uses.
    public let model: AnthropicModel

    /// Maximum number of output tokens for each response.
    public let maxResponseTokens: Int

    // MARK: - Init

    /// Creates a configuration. Every parameter defaults to a
    /// sensible production value so call sites that just want the
    /// defaults can write `AnthropicConfiguration()`.
    public init(
        baseURL: URL = AnthropicConfiguration.defaultBaseURL,
        apiVersion: String = AnthropicConfiguration.defaultAPIVersion,
        model: AnthropicModel = .default,
        maxResponseTokens: Int = AnthropicConfiguration.defaultMaxResponseTokens
    ) {
        self.baseURL = baseURL
        self.apiVersion = apiVersion
        self.model = model
        self.maxResponseTokens = maxResponseTokens
    }
}
