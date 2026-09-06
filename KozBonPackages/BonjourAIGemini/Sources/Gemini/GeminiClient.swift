//
//  GeminiClient.swift
//  BonjourAIGemini
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourAICore
import BonjourCore

// MARK: - GeminiClientProtocol

/// Abstraction over the streaming Gemini `generateContent` API.
///
/// Production uses ``GeminiClient``; tests substitute
/// ``MockGeminiClient`` to drive deterministic event sequences
/// without touching the network. Both expose the same
/// `AsyncThrowingStream<String, Error>` shape, so the consumer
/// (chat session, explainer) doesn't need to know which is wired
/// up — the same contract ``AnthropicClientProtocol`` offers.
public protocol GeminiClientProtocol: Sendable {

    /// Sends the request and yields incremental assistant text.
    ///
    /// - Parameters:
    ///   - request: The fully-formed request body.
    ///   - apiKey: The Google AI Studio API key. Passed per call
    ///     rather than captured at init so one client instance can
    ///     serve different users.
    /// - Returns: A stream of text fragments. It terminates
    ///   normally when the candidate reports a finish reason or the
    ///   connection closes; cancelling the iterating `Task` cancels
    ///   the underlying `URLSessionDataTask`; API errors surface as
    ///   ``AICloudError`` cases.
    func streamMessage(
        request: GeminiGenerateRequest,
        apiKey: String
    ) -> AsyncThrowingStream<String, Error>
}

// MARK: - GeminiClient

/// `URLSession`-backed implementation of ``GeminiClientProtocol``.
///
/// Reads the SSE stream via `URLSession.bytes(for:)`, decodes each
/// `data: {...}` frame into a ``GeminiStreamEvent``, and yields the
/// text payloads through an `AsyncThrowingStream`.
public final class GeminiClient: GeminiClientProtocol {

    // MARK: - Properties

    private let configuration: GeminiConfiguration
    private let urlSession: URLSession
    private let logger = Logger(subsystem: "com.kozinga.KozBon", category: "GeminiClient")

    // MARK: - Init

    public init(
        configuration: GeminiConfiguration = GeminiConfiguration(),
        urlSession: URLSession = .shared
    ) {
        self.configuration = configuration
        self.urlSession = urlSession
    }

    // MARK: - GeminiClientProtocol

    public func streamMessage(
        request: GeminiGenerateRequest,
        apiKey: String
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task { [self] in
                do {
                    try await runStream(request: request, apiKey: apiKey, continuation: continuation)
                } catch is CancellationError {
                    continuation.finish(throwing: AICloudError.cancelled)
                } catch let urlError as URLError {
                    // DNS failures, TLS rejections, lost
                    // connectivity, offline. The typed case lets the
                    // chat surface attach a Retry button instead of
                    // making the user re-type their message.
                    logger.error(
                        """
                        Network error reaching Gemini — \
                        code: \(urlError.code.rawValue), \
                        description: \(urlError.localizedDescription)
                        """
                    )
                    continuation.finish(throwing: AICloudError.networkUnavailable)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            // Cancelling the outer stream cancels the URLSession
            // task — otherwise navigating away from chat leaves the
            // model generating into the void.
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    // MARK: - Streaming Implementation

    private func runStream(
        request: GeminiGenerateRequest,
        apiKey: String,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        let urlRequest = try makeURLRequest(body: request, apiKey: apiKey)

        let (bytes, response) = try await urlSession.bytes(for: urlRequest)

        // Validate before reading the stream: errors come back as a
        // plain JSON body, not SSE, so the bytes have to be drained
        // to surface them.
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode != 200 {
            let errorBody = try await readAll(bytes)
            throw mapHTTPError(statusCode: httpResponse.statusCode, body: errorBody, response: httpResponse)
        }

        for try await line in bytes.lines {
            try Task.checkCancellation()

            guard line.hasPrefix("data:") else { continue }
            let payload = String(line.dropFirst("data:".count))

            guard let event = try GeminiStreamEvent.decode(payload: payload) else {
                continue
            }

            switch event {
            case .textDelta(let text):
                continuation.yield(text)
            case .finished(let reason):
                // Anything other than STOP means the answer was cut
                // short — worth a log line, but the partial text
                // already yielded is still the best answer we have,
                // so finish normally rather than throwing it away.
                if reason != "STOP" {
                    logger.error("Gemini stopped early: \(reason)")
                }
                continuation.finish()
                return
            case .error(let message, let status):
                logger.error("Gemini inline error (\(status ?? "unknown")): \(message)")
                throw AICloudError.serverError(provider: .gemini, message: message)
            case .other(let reason):
                logger.debug("Gemini stream frame (no-op): \(reason)")
            }
        }

        // End-of-stream without a finish reason is normal here —
        // Gemini closes the connection to signal completion.
        continuation.finish()
    }

    // MARK: - Request Construction

    private func makeURLRequest(
        body: GeminiGenerateRequest,
        apiKey: String
    ) throws -> URLRequest {
        // The model travels in the path, and `alt=sse` is what makes
        // the response real SSE rather than a streamed JSON array.
        // The request's model wins over the configuration's: a chat
        // session picks its model long after this client was built.
        let modelIdentifier = body.model.isEmpty
            ? configuration.model.rawValue
            : body.model
        let endpoint = configuration.baseURL
            .appendingPathComponent(configuration.apiVersion)
            .appendingPathComponent("models")
            .appendingPathComponent("\(modelIdentifier):streamGenerateContent")

        guard var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
            throw AICloudError.invalidRequest(provider: .gemini, message: "Could not build the request URL.")
        }
        components.queryItems = [URLQueryItem(name: "alt", value: "sse")]

        guard let url = components.url else {
            throw AICloudError.invalidRequest(provider: .gemini, message: "Could not build the request URL.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        // The header form, never the `?key=` query parameter the
        // Gemini docs also accept: query strings land in logs,
        // proxies, and crash reports, and this is a user credential.
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            throw AICloudError.decodingFailure(message: "Failed to encode request: \(error.localizedDescription)")
        }
        return request
    }

    // MARK: - Error Mapping

    private func mapHTTPError(
        statusCode: Int,
        body: String,
        response: HTTPURLResponse
    ) -> AICloudError {
        let message = extractErrorMessage(from: body)
        logger.error("Gemini API error \(statusCode): \(message ?? "<no message>")")

        switch statusCode {
        case 401:
            return .invalidCredentials(provider: .gemini)
        case 403:
            // Google returns 403 both for a key that's invalid or
            // disabled and for one lacking permission. The message
            // is what separates them, and "API key not valid" is
            // Google's stable wording for the credential case —
            // routing it to `.invalidCredentials` gets the user the
            // "re-enter your key" remediation instead of a dead-end
            // "check your plan".
            if let lowered = message?.lowercased(),
               lowered.contains("api key not valid") || lowered.contains("api key expired") {
                return .invalidCredentials(provider: .gemini)
            }
            return .permissionDenied(provider: .gemini, message: message)
        case 429:
            let retry = response.value(forHTTPHeaderField: "Retry-After")
                .flatMap { TimeInterval($0) }
            return .rateLimited(provider: .gemini, retryAfterSeconds: retry)
        case 503:
            // Google's "model is overloaded" status. Split from
            // generic 5xx so the chat surface can say the outage is
            // wide rather than something the user did.
            return .serviceOverloaded(provider: .gemini, message: message)
        case 500...599:
            return .serverError(provider: .gemini, message: message)
        case 400...499:
            if let lowered = message?.lowercased() {
                // Google phrases the over-long-prompt 400 in terms
                // of the token limit; these phrases cover the
                // wordings without being loose enough to catch an
                // unrelated 400.
                if lowered.contains("token count")
                    || lowered.contains("input token")
                    || lowered.contains("context length")
                    || lowered.contains("exceeds the maximum") {
                    return .contextWindowExceeded(provider: .gemini, message: message)
                }
                // Free-tier exhaustion and billing problems arrive
                // as 400s mentioning billing, where the remediation
                // is Google's console rather than anything in-app.
                if lowered.contains("billing") || lowered.contains("quota") {
                    return .creditBalanceTooLow(provider: .gemini, message: message)
                }
            }
            return .invalidRequest(provider: .gemini, message: message)
        default:
            return .unexpectedStatus(provider: .gemini, statusCode: statusCode)
        }
    }

    private func extractErrorMessage(from body: String) -> String? {
        // `{"error": {"code": 400, "message": "...", "status": "..."}}`
        guard let data = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        // Google sometimes wraps the object in a single-element
        // array when the request was batched.
        if let error = json["error"] as? [String: Any] {
            return error["message"] as? String
        }
        return nil
    }

    /// Drains the byte stream for non-streaming error responses,
    /// capped so a misbehaving body can't exhaust memory.
    private func readAll(_ bytes: URLSession.AsyncBytes) async throws -> String {
        var accumulator = Data()
        for try await byte in bytes {
            accumulator.append(byte)
            if accumulator.count > 64_000 {
                break
            }
        }
        return String(data: accumulator, encoding: .utf8) ?? ""
    }
}
