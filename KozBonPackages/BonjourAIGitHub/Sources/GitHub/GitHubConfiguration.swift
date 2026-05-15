//
//  GitHubConfiguration.swift
//  BonjourAIGitHub
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourAICore

// MARK: - GitHubConfiguration

/// Static configuration for calls to the GitHub Models API.
///
/// Bundles the values that don't change between requests within a
/// single chat session — the base URL, the model identifier, and
/// the maximum response token count. Per-request payloads (the
/// user prompt, the system message, the conversation history) are
/// built by the client at send time.
///
/// Held as a value type so a session can capture a snapshot at
/// creation and remain immune to subsequent preference changes
/// (matching the Apple Foundation Models side, where
/// `LanguageModelSession` snapshots its instructions at init).
public struct GitHubConfiguration: Sendable, Equatable {

    // MARK: - Constants

    /// GitHub Models' OpenAI-compatible inference endpoint.
    /// Hard-coded — GitHub doesn't expose a regional or
    /// self-hosted variant the consumer SDK would reach.
    ///
    /// Built via `URL(string:)` rather than the iOS 17+
    /// `URL(staticString:)` initializer (which would let us avoid
    /// the optional) because the expression is constant, evaluated
    /// once at module load, and `defaultBaseURLString` provides a
    /// deterministic fallback. `GitHubConfigurationTests` includes
    /// a tripwire that fails if the string is ever malformed.
    public static let defaultBaseURLString = "https://models.inference.ai.azure.com"
    public static let defaultBaseURL: URL = URL(string: defaultBaseURLString)
        ?? URL(fileURLWithPath: "/dev/null")

    /// Hardcoded model identifier. GitHub Models exposes several
    /// providers (GPT-4o, Mistral, Phi, …) but the brief pins this
    /// to `gpt-4o` — there is no in-app model picker for the
    /// GitHub backend in v1.
    public static let defaultModel = "gpt-4o"

    /// Default maximum tokens per response. Sized to match the
    /// Anthropic side so multi-paragraph chat answers fit while
    /// still capping run-away generation.
    public static let defaultMaxResponseTokens = 1024

    // MARK: - Properties

    /// The base URL the client appends `/chat/completions` to.
    /// Override in tests with a `URLProtocol`-stubbed value to
    /// avoid live network hits.
    public let baseURL: URL

    /// The model identifier this session sends to.
    public let model: String

    /// Maximum number of output tokens for each response.
    public let maxResponseTokens: Int

    // MARK: - Init

    /// Creates a configuration. Every parameter defaults to a
    /// sensible production value so call sites that just want the
    /// defaults can write `GitHubConfiguration()`.
    public init(
        baseURL: URL = GitHubConfiguration.defaultBaseURL,
        model: String = GitHubConfiguration.defaultModel,
        maxResponseTokens: Int = GitHubConfiguration.defaultMaxResponseTokens
    ) {
        self.baseURL = baseURL
        self.model = model
        self.maxResponseTokens = maxResponseTokens
    }
}
