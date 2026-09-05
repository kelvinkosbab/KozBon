//
//  AnthropicModelCatalogClient.swift
//  BonjourAIAnthropic
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourAICore
import BonjourCore

// MARK: - AnthropicModelCatalogClientProtocol

/// Fetches the models the caller's API key can use.
///
/// Split from ``AnthropicClientProtocol`` because the two have
/// nothing in common at the transport layer: that one streams
/// Server-Sent Events for a conversation, this one does a single
/// small JSON GET. Keeping them separate also means the many
/// existing `MockAnthropicClient` call sites don't have to grow a
/// method they never exercise.
public protocol AnthropicModelCatalogClientProtocol: Sendable {

    /// Lists available models, newest first.
    ///
    /// - Parameter apiKey: The user's Anthropic API key.
    /// - Returns: The available models in the order the API
    ///   returned them (Anthropic documents newest-first).
    /// - Throws: ``AICloudError`` for HTTP and transport failures.
    func listModels(apiKey: String) async throws -> [AnthropicModelOption]
}

// MARK: - AnthropicModelCatalogClient

/// `URLSession`-backed implementation of
/// ``AnthropicModelCatalogClientProtocol``.
///
/// Calls `GET {base}/v1/models` with the same `x-api-key` +
/// `anthropic-version` headers the messages endpoint uses, so a
/// key that can chat can always list models. Listing is not
/// token-billed, which is why refreshing on Settings appearance
/// is reasonable.
public struct AnthropicModelCatalogClient: AnthropicModelCatalogClientProtocol {

    // MARK: - Response DTOs

    /// Only the fields KozBon needs. The endpoint also returns
    /// `capabilities`, `max_tokens`, and pagination cursors;
    /// decoding just these keeps the DTO stable as Anthropic adds
    /// fields (`JSONDecoder` ignores unknown keys).
    private struct ModelListResponse: Decodable {
        let data: [Model]

        struct Model: Decodable {
            let id: String
            let displayName: String

            enum CodingKeys: String, CodingKey {
                case id
                case displayName = "display_name"
            }
        }
    }

    // MARK: - Properties

    private let configuration: AnthropicConfiguration
    private let urlSession: URLSession
    private let logger: Loggable = Logger(category: "AnthropicModelCatalogClient")

    /// Page size. The API caps at 1000 and defaults to 20; 100 is
    /// far more Claude models than have ever existed at once, so
    /// a single request always covers the full lineup and no
    /// pagination loop is needed.
    private let pageLimit = 100

    // MARK: - Init

    public init(
        configuration: AnthropicConfiguration = AnthropicConfiguration(),
        urlSession: URLSession = .shared
    ) {
        self.configuration = configuration
        self.urlSession = urlSession
    }

    // MARK: - List Models

    public func listModels(apiKey: String) async throws -> [AnthropicModelOption] {
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
            throw AICloudError.serverError(provider: .anthropic, message: nil)
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            logger.error(
                "Model list failed with \(httpResponse.statusCode)"
            )
            throw Self.mapHTTPError(statusCode: httpResponse.statusCode, body: body)
        }

        do {
            let decoded = try JSONDecoder().decode(ModelListResponse.self, from: data)
            return decoded.data.map {
                AnthropicModelOption(id: $0.id, displayName: $0.displayName, isBuiltIn: false)
            }
        } catch {
            throw AICloudError.decodingFailure(
                message: "Failed to decode model list: \(error.localizedDescription)"
            )
        }
    }

    // MARK: - Private

    private func makeURLRequest(apiKey: String) throws -> URLRequest {
        var components = URLComponents(
            url: configuration.baseURL.appendingPathComponent("v1/models"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [URLQueryItem(name: "limit", value: "\(pageLimit)")]

        guard let url = components?.url else {
            throw AICloudError.invalidRequest(
                provider: .anthropic,
                message: "Could not build the model-list URL."
            )
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(configuration.apiVersion, forHTTPHeaderField: "anthropic-version")
        return request
    }

    /// Maps the handful of statuses this endpoint realistically
    /// returns. Narrower than the messages client's mapping —
    /// there's no streaming, no overload, and no context-window
    /// case to consider for a plain listing.
    private static func mapHTTPError(statusCode: Int, body: String) -> AICloudError {
        switch statusCode {
        case 401:
            return .invalidCredentials(provider: .anthropic)
        case 403:
            return .permissionDenied(provider: .anthropic, message: nil)
        case 429:
            return .rateLimited(provider: .anthropic, retryAfterSeconds: nil)
        default:
            return .serverError(provider: .anthropic, message: body.isEmpty ? nil : body)
        }
    }
}
