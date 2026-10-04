//
//  OpenAIModelCatalogClient.swift
//  BonjourAIOpenAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourAICore
import BonjourCore

// MARK: - OpenAIModelCatalogClientProtocol

/// Fetches the models the caller's API key can use.
///
/// Split from ``OpenAIClientProtocol`` for the same reason the
/// Gemini pair is split: streaming a conversation and doing one
/// small JSON GET have nothing in common at the transport layer.
public protocol OpenAIModelCatalogClientProtocol: Sendable {

    /// Lists available chat models, newest first.
    ///
    /// - Parameter apiKey: The user's OpenAI API key.
    /// - Throws: ``AICloudError`` for HTTP and transport failures.
    func listModels(apiKey: String) async throws -> [OpenAIModelOption]
}

// MARK: - OpenAIModelCatalogClient

/// `URLSession`-backed implementation of
/// ``OpenAIModelCatalogClientProtocol``, calling `GET /v1/models`.
public struct OpenAIModelCatalogClient: OpenAIModelCatalogClientProtocol {

    // MARK: - Properties

    private let configuration: OpenAIConfiguration
    private let urlSession: URLSession
    private let logger: Loggable = Logger(category: "OpenAIModelCatalogClient")

    // MARK: - Init

    public init(
        configuration: OpenAIConfiguration = OpenAIConfiguration(),
        urlSession: URLSession = .shared
    ) {
        self.configuration = configuration
        self.urlSession = urlSession
    }

    // MARK: - List Models

    public func listModels(apiKey: String) async throws -> [OpenAIModelOption] {
        let request = makeURLRequest(apiKey: apiKey)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await urlSession.data(for: request)
        } catch is CancellationError {
            throw AICloudError.cancelled
        } catch {
            throw AICloudError.networkUnavailable
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AICloudError.serverError(provider: .openai, message: nil)
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            logger.error("Model list failed with \(httpResponse.statusCode)")
            throw Self.mapHTTPError(
                statusCode: httpResponse.statusCode,
                body: String(data: data, encoding: .utf8) ?? ""
            )
        }

        do {
            let decoded = try JSONDecoder().decode(ModelListResponse.self, from: data)
            return decoded.data
                .filter { Self.isChatModel($0.id) }
                .sorted { ($0.created ?? 0) > ($1.created ?? 0) }
                .map { entry in
                    OpenAIModelOption(
                        id: entry.id,
                        displayName: OpenAIModelOption.displayName(forIdentifier: entry.id),
                        isBuiltIn: false
                    )
                }
        } catch {
            throw AICloudError.decodingFailure(
                message: "Failed to decode model list: \(error.localizedDescription)"
            )
        }
    }

    // MARK: - Filtering

    /// Whether `identifier` names a model that can hold a text
    /// conversation through the Responses API.
    ///
    /// Gemini's catalog advertises each model's capabilities; this
    /// one doesn't — `/v1/models` returns only identifiers, mixing
    /// chat models with embedding, speech, image, moderation, and
    /// realtime ones. So the filter is by name: the `gpt-` and
    /// `o`-series families, minus the specialized variants that
    /// reject a plain text request or need tools KozBon doesn't
    /// provide. Dated snapshots (`gpt-5.4-2026-03-05`) duplicate
    /// their alias and are dropped to keep the picker short.
    static func isChatModel(_ identifier: String) -> Bool {
        let id = identifier.lowercased()

        let isOSeries = id.first == "o" && id.dropFirst().first?.isNumber == true
        guard id.hasPrefix("gpt-") || isOSeries else { return false }
        guard !id.hasPrefix("gpt-3.5") else { return false }

        let excluded = [
            "embedding", "tts", "whisper", "transcribe", "audio", "realtime",
            "image", "dall-e", "moderation", "search", "instruct", "codex",
            "computer-use", "deep-research"
        ]
        guard !excluded.contains(where: id.contains) else { return false }

        return id.range(of: #"-\d{4}(-\d{2}-\d{2})?$"#, options: .regularExpression) == nil
    }

    // MARK: - Private

    private func makeURLRequest(apiKey: String) -> URLRequest {
        let url = configuration.baseURL
            .appendingPathComponent(configuration.apiVersion)
            .appendingPathComponent("models")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        return request
    }

    /// Maps the handful of statuses a plain listing realistically
    /// returns — no streaming, no overload, no context window.
    private static func mapHTTPError(statusCode: Int, body: String) -> AICloudError {
        let detail = OpenAIErrorBody.parse(body)
        switch statusCode {
        case 401:
            return .invalidCredentials(provider: .openai)
        case 403:
            return .permissionDenied(provider: .openai, message: detail.message)
        case 429:
            return .rateLimited(provider: .openai, retryAfterSeconds: nil)
        default:
            return .serverError(provider: .openai, message: detail.message)
        }
    }
}

// MARK: - Response DTOs

/// Only the fields KozBon needs; `JSONDecoder` ignores the rest.
private struct ModelListResponse: Decodable {
    let data: [ModelListEntry]
}

/// One row of ``ModelListResponse``.
private struct ModelListEntry: Decodable {
    let id: String
    /// Unix timestamp, used to sort newest first — the endpoint's
    /// own order is unspecified.
    let created: Int?
}
