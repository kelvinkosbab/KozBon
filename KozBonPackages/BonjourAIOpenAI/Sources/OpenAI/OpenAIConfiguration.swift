//
//  OpenAIConfiguration.swift
//  BonjourAIOpenAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourAICore

// MARK: - OpenAIConfiguration

/// Static configuration for calls to the OpenAI API.
///
/// Bundles what doesn't change between requests inside one chat
/// session — base URL, API version path segment, and the default
/// model. Per-request payloads are built by the client at send
/// time.
///
/// A value type, so a session captures a snapshot at creation and
/// stays immune to later preference changes — matching
/// ``AnthropicConfiguration`` and ``GeminiConfiguration``.
public struct OpenAIConfiguration: Sendable, Equatable {

    // MARK: - Constants

    /// The OpenAI API host.
    ///
    /// Built with `URL(string:)` and a deterministic fallback for
    /// the same reason ``AnthropicConfiguration`` does;
    /// `OpenAIConfigurationTests.defaultBaseURLIsValid` is the
    /// tripwire if the literal is ever malformed.
    public static let defaultBaseURLString = "https://api.openai.com"
    public static let defaultBaseURL: URL = URL(string: defaultBaseURLString)
        ?? URL(fileURLWithPath: "/dev/null")

    /// The API version path segment KozBon ships with.
    public static let defaultAPIVersion = "v1"

    // MARK: - Properties

    /// The base URL the client builds request paths onto. Override
    /// in tests with a `URLProtocol`-stubbed value to avoid live
    /// network hits.
    public let baseURL: URL

    /// The API version path segment (e.g. `v1`).
    public let apiVersion: String

    /// The model used when a request doesn't name one.
    public let model: OpenAIModel

    // MARK: - Init

    public init(
        baseURL: URL = OpenAIConfiguration.defaultBaseURL,
        apiVersion: String = OpenAIConfiguration.defaultAPIVersion,
        model: OpenAIModel = .default
    ) {
        self.baseURL = baseURL
        self.apiVersion = apiVersion
        self.model = model
    }
}
