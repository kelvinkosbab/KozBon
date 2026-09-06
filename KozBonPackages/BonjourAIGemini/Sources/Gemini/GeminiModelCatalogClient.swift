//
//  GeminiModelCatalogClient.swift
//  BonjourAIGemini
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourAICore
import BonjourCore

// MARK: - GeminiModelCatalogClientProtocol

/// Fetches the models the caller's API key can use.
///
/// Split from ``GeminiClientProtocol`` for the same reason the
/// Anthropic pair is split: streaming a conversation and doing one
/// small JSON GET have nothing in common at the transport layer,
/// and keeping them apart means ``MockGeminiClient`` call sites
/// don't grow a method they never exercise.
public protocol GeminiModelCatalogClientProtocol: Sendable {

    /// Lists available models.
    ///
    /// - Parameter apiKey: The user's Google AI Studio API key.
    /// - Returns: The models that support text generation, in the
    ///   order the API returned them.
    /// - Throws: ``AICloudError`` for HTTP and transport failures.
    func listModels(apiKey: String) async throws -> [GeminiModelOption]
}

// MARK: - GeminiModelCatalogClient

/// `URLSession`-backed implementation of
/// ``GeminiModelCatalogClientProtocol``.
///
/// Calls `GET {base}/{version}/models` with the same
/// `x-goog-api-key` header the generate endpoint uses, so a key
/// that can chat can always list models. Listing isn't
/// token-billed, which is why refreshing on Settings appearance is
/// reasonable.
public struct GeminiModelCatalogClient: GeminiModelCatalogClientProtocol {

    // MARK: - Response DTOs

    /// Only the fields KozBon needs; `JSONDecoder` ignores the
    /// rest (token limits, supported parameters, version strings)
    /// so the DTO stays stable as Google adds fields.
    private struct ModelListResponse: Decodable {
        let models: [Model]

        struct Model: Decodable {
            /// Fully-qualified, e.g. `models/gemini-2.5-flash`.
            let name: String
            let displayName: String?
            let supportedGenerationMethods: [String]?
        }
    }

    // MARK: - Properties

    private let configuration: GeminiConfiguration
    private let urlSession: URLSession
    private let logger: Loggable = Logger(category: "GeminiModelCatalogClient")

    /// Page size. Google's cap is 1000 and the default is 50 —
    /// which the Gemini lineup already exceeds once every
    /// embedding and preview variant is counted, so this is set
    /// high enough that a single request covers the list and no
    /// pagination loop is needed.
    private let pageSize = 200

    // MARK: - Init

    public init(
        configuration: GeminiConfiguration = GeminiConfiguration(),
        urlSession: URLSession = .shared
    ) {
        self.configuration = configuration
        self.urlSession = urlSession
    }

    // MARK: - List Models

    public func listModels(apiKey: String) async throws -> [GeminiModelOption] {
        let request = try makeURLRequest(apiKey: apiKey)

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
            throw AICloudError.serverError(provider: .gemini, message: nil)
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            logger.error("Model list failed with \(httpResponse.statusCode)")
            throw Self.mapHTTPError(statusCode: httpResponse.statusCode, body: body)
        }

        do {
            let decoded = try JSONDecoder().decode(ModelListResponse.self, from: data)
            return decoded.models.compactMap(Self.makeOption)
        } catch {
            throw AICloudError.decodingFailure(
                message: "Failed to decode model list: \(error.localizedDescription)"
            )
        }
    }

    // MARK: - Private

    /// Converts one API entry, dropping the models KozBon can't
    /// talk to.
    ///
    /// The endpoint returns the whole lineup — embedding models,
    /// image and TTS variants, retrieval helpers — and offering
    /// any of them in a chat picker would produce a request the
    /// API rejects. `generateContent` support is the filter that
    /// keeps the list to models that can actually hold a
    /// conversation.
    private static func makeOption(from model: ModelListResponse.Model) -> GeminiModelOption? {
        guard let methods = model.supportedGenerationMethods,
              methods.contains("generateContent") else {
            return nil
        }
        // Names arrive fully-qualified; preferences and the request
        // path both want the bare identifier.
        let identifier = model.name.hasPrefix("models/")
            ? String(model.name.dropFirst("models/".count))
            : model.name
        guard !identifier.isEmpty else { return nil }

        return GeminiModelOption(
            id: identifier,
            displayName: model.displayName ?? identifier,
            isBuiltIn: false
        )
    }

    private func makeURLRequest(apiKey: String) throws -> URLRequest {
        var components = URLComponents(
            url: configuration.baseURL
                .appendingPathComponent(configuration.apiVersion)
                .appendingPathComponent("models"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [URLQueryItem(name: "pageSize", value: "\(pageSize)")]

        guard let url = components?.url else {
            throw AICloudError.invalidRequest(
                provider: .gemini,
                message: "Could not build the model-list URL."
            )
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        // Header, not `?key=` — see `GeminiClient.makeURLRequest`.
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        return request
    }

    /// Maps the handful of statuses a plain listing realistically
    /// returns — no streaming, no overload, no context window.
    private static func mapHTTPError(statusCode: Int, body: String) -> AICloudError {
        switch statusCode {
        case 401:
            return .invalidCredentials(provider: .gemini)
        case 403:
            // Google uses 403 for a bad key as well as for a
            // permission problem; the messages client explains the
            // split. Listing has no plan-tier dimension, so a 403
            // here is overwhelmingly a bad key.
            return .invalidCredentials(provider: .gemini)
        case 429:
            return .rateLimited(provider: .gemini, retryAfterSeconds: nil)
        default:
            return .serverError(provider: .gemini, message: body.isEmpty ? nil : body)
        }
    }
}
