//
//  AnthropicClient.swift
//  BonjourAICloud
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import OSLog

// MARK: - AnthropicClientProtocol

/// Abstraction over the streaming Anthropic Messages API.
///
/// Production uses ``AnthropicClient``; tests substitute
/// ``MockAnthropicClient`` to drive deterministic event
/// sequences without touching the network. Both implementations
/// expose the same `AsyncThrowingStream<String, Error>` shape —
/// the consumer (chat session, explainer) doesn't need to know
/// which is wired up.
public protocol AnthropicClientProtocol: Sendable {

    /// Sends the message request and yields incremental
    /// assistant text as it arrives.
    ///
    /// - Parameters:
    ///   - request: The fully-formed request body, including the
    ///     cached system block and the message history.
    ///   - apiKey: The Anthropic API key. Passed per call rather
    ///     than captured at init so a single client instance can
    ///     serve different users (preview seeds, future
    ///     multi-account support).
    /// - Returns: A stream of text fragments. The stream
    ///   terminates normally on `message_stop`; cancellation of
    ///   the iterating `Task` cancels the underlying
    ///   `URLSessionDataTask`; errors from the API surface as
    ///   ``AICloudError`` cases.
    func streamMessage(
        request: AnthropicMessageRequest,
        apiKey: String
    ) -> AsyncThrowingStream<String, Error>
}

// MARK: - AnthropicClient

/// `URLSession`-backed implementation of
/// ``AnthropicClientProtocol``.
///
/// Reads Anthropic's Server-Sent Events stream via
/// `URLSession.bytes(for:)`, decodes each `data: {...}` frame
/// into an ``AnthropicStreamEvent``, and yields the text-delta
/// payloads through an `AsyncThrowingStream`. The implementation
/// is `Sendable` (URLSession is Sendable, configuration is a
/// value type, logger is a value-type wrapper).
public final class AnthropicClient: AnthropicClientProtocol {

    // MARK: - Properties

    /// Static configuration captured at init — base URL, API
    /// version, model identifier, max response tokens.
    private let configuration: AnthropicConfiguration

    /// The session used for all requests. Defaults to `.shared`
    /// in production; tests inject a session backed by a
    /// `URLProtocol` stub to return canned SSE responses without
    /// touching the network.
    private let urlSession: URLSession

    private let logger = Logger(subsystem: "com.kozinga.KozBon", category: "AnthropicClient")

    // MARK: - Init

    public init(
        configuration: AnthropicConfiguration = AnthropicConfiguration(),
        urlSession: URLSession = .shared
    ) {
        self.configuration = configuration
        self.urlSession = urlSession
    }

    // MARK: - AnthropicClientProtocol

    public func streamMessage(
        request: AnthropicMessageRequest,
        apiKey: String
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task { [self] in
                do {
                    try await runStream(request: request, apiKey: apiKey, continuation: continuation)
                } catch is CancellationError {
                    continuation.finish(throwing: AICloudError.cancelled)
                } catch let urlError as URLError {
                    // URLSession surfaces these for DNS failures,
                    // TLS rejections, lost connectivity, and the
                    // user being offline. Surfacing them as the
                    // typed ``.networkUnavailable`` case lets the
                    // chat surface attach a Retry button — the
                    // user doesn't have to re-type their message
                    // when their connection blips.
                    logger.error(
                        """
                        Network error reaching Anthropic — \
                        code: \(urlError.code.rawValue, privacy: .public), \
                        description: \(urlError.localizedDescription, privacy: .public)
                        """
                    )
                    continuation.finish(throwing: AICloudError.networkUnavailable)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            // Cancelling the outer stream cancels the
            // underlying URLSession task too — without this, a
            // user navigating away from the chat surface leaves
            // the model generating into the void and blocks the
            // session for the next turn.
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    // MARK: - Streaming Implementation

    private func runStream(
        request: AnthropicMessageRequest,
        apiKey: String,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        let urlRequest = try makeURLRequest(body: request, apiKey: apiKey)

        let (bytes, response) = try await urlSession.bytes(for: urlRequest)

        // Validate the HTTP response before reading any bytes.
        // Errors live in the response body as JSON, not SSE — we
        // need to drain the rest of the byte stream to surface
        // them.
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode != 200 {
            let errorBody = try await readAll(bytes)
            throw mapHTTPError(statusCode: httpResponse.statusCode, body: errorBody, response: httpResponse)
        }

        // Successful response — iterate the SSE stream.
        for try await line in bytes.lines {
            try Task.checkCancellation()

            // SSE frames are `event: <type>\n data: <json>\n\n`.
            // We only care about `data:` lines; everything else
            // (event type names, blank separators, comments) we
            // skip. Some servers omit the explicit `event:` line
            // entirely, putting all info into `data:` — which
            // works because our decoder reads `type` out of the
            // JSON payload regardless.
            guard line.hasPrefix("data:") else { continue }

            let payload = String(line.dropFirst("data:".count))

            guard let event = try AnthropicStreamEvent.decode(payload: payload) else {
                continue
            }

            switch event {
            case .textDelta(let text):
                continuation.yield(text)
            case .messageStop:
                continuation.finish()
                return
            case .error(let message, let type):
                logger.error("Anthropic inline error (\(type ?? "unknown")): \(message)")
                throw AICloudError.serverError(provider: .anthropic, message: message)
            case .other(let type):
                logger.debug("Anthropic stream event (no-op): \(type)")
            }
        }

        // Reached end-of-stream without a `message_stop` event —
        // Anthropic sometimes does this after `[DONE]` so we
        // accept it as a normal terminator.
        continuation.finish()
    }

    // MARK: - Request Construction

    private func makeURLRequest(
        body: AnthropicMessageRequest,
        apiKey: String
    ) throws -> URLRequest {
        let endpoint = configuration.baseURL.appendingPathComponent("v1/messages")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(configuration.apiVersion, forHTTPHeaderField: "anthropic-version")

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
        // Log the raw status + message at error level — the
        // user-facing description above is the same content but
        // the explicit log entry makes per-environment
        // diagnostics easier when a status code recurs.
        logger.error(
            "Anthropic API error \(statusCode): \(message ?? "<no message>", privacy: .public)"
        )
        switch statusCode {
        case 401:
            // 401 = bad key. The user needs a fresh one. Split
            // from 403 so the user-facing remediation can differ:
            // 401 → "re-enter your API key"; 403 → "check your
            // plan".
            return .invalidCredentials(provider: .anthropic)
        case 403:
            // 403 = valid key, but the account doesn't have
            // permission for the requested resource — typically
            // a model the account's plan tier doesn't include.
            return .permissionDenied(provider: .anthropic, message: message)
        case 429:
            // `Retry-After` may be seconds or an HTTP date; parse
            // numerically and fall back to nil if it's not a number.
            let retry = response.value(forHTTPHeaderField: "Retry-After")
                .flatMap { TimeInterval($0) }
            return .rateLimited(provider: .anthropic, retryAfterSeconds: retry)
        case 529:
            // Anthropic-specific overloaded status. Split from
            // generic 5xx so the chat surface can offer a
            // status-page link — the user can confirm the
            // outage is wide rather than something they did.
            return .serviceOverloaded(provider: .anthropic, message: message)
        case 500...599:
            return .serverError(provider: .anthropic, message: message)
        case 400...499:
            // Carve out the "credit balance is too low" 400 as
            // a separate case — the user-facing remediation is
            // different (open Anthropic's billing console, not
            // fix anything in the app) and the chat surface
            // renders an actionable banner with a deep link.
            // Anthropic's exact wording is "Your credit balance
            // is too low to access the Anthropic API."; match
            // case-insensitively on the distinctive phrase so
            // minor copy changes don't break detection.
            if let lowered = message?.lowercased() {
                if lowered.contains("credit balance") {
                    return .creditBalanceTooLow(provider: .anthropic, message: message)
                }
                // Carve out context-window-exceeded 400s. Anthropic
                // returns messages like "prompt is too long: N
                // tokens > max" or "input length exceeds maximum
                // context length" depending on the failure mode.
                // The detection phrases below cover both wordings
                // while staying tight enough that an unrelated
                // 400 mentioning "long" won't false-positive.
                if lowered.contains("prompt is too long")
                    || lowered.contains("input length")
                    || lowered.contains("context length")
                    || lowered.contains("context window") {
                    return .contextWindowExceeded(provider: .anthropic, message: message)
                }
            }
            // Other 4xx: model not found, max_tokens exceeds…,
            // etc. Surface the provider's actual error string
            // so users see what's wrong instead of a bare
            // status code.
            return .invalidRequest(provider: .anthropic, message: message)
        default:
            return .unexpectedStatus(provider: .anthropic, statusCode: statusCode)
        }
    }

    private func extractErrorMessage(from body: String) -> String? {
        // Anthropic error body shape:
        // {"type": "error", "error": {"type": "...", "message": "..."}}
        guard let data = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let error = json["error"] as? [String: Any],
              let message = error["message"] as? String else {
            return nil
        }
        return message
    }

    /// Drains the byte stream into a `String` for non-streaming
    /// error responses. Bounded by the response itself — Anthropic
    /// error bodies are small JSON objects, well under any
    /// reasonable cap.
    private func readAll(_ bytes: URLSession.AsyncBytes) async throws -> String {
        var accumulator = Data()
        for try await byte in bytes {
            accumulator.append(byte)
            // Defensive cap so a misbehaving error body can't
            // exhaust memory. 64 KB is far more than Anthropic
            // emits for errors today.
            if accumulator.count > 64_000 {
                break
            }
        }
        return String(data: accumulator, encoding: .utf8) ?? ""
    }
}
