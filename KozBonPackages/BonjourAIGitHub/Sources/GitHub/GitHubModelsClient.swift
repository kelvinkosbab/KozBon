//
//  GitHubModelsClient.swift
//  BonjourAIGitHub
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import OSLog
import BonjourAICore

// MARK: - GitHubModelsClientProtocol

/// Abstraction over the streaming GitHub Models API.
///
/// Production uses ``GitHubModelsClient``; tests substitute
/// ``MockGitHubModelsClient`` to drive deterministic event
/// sequences without touching the network. Both implementations
/// expose the same `AsyncThrowingStream<String, Error>` shape —
/// the consumer (chat session, explainer) doesn't need to know
/// which is wired up.
public protocol GitHubModelsClientProtocol: Sendable {

    /// Sends the chat-completions request and yields incremental
    /// assistant text as it arrives.
    ///
    /// - Parameters:
    ///   - request: The fully-formed request body, including the
    ///     leading system message and the conversation history.
    ///   - apiKey: The GitHub Personal Access Token. Passed per
    ///     call rather than captured at init so a single client
    ///     instance can serve different users (preview seeds,
    ///     future multi-account support).
    /// - Returns: A stream of text fragments. The stream
    ///   terminates normally on `[DONE]` or end-of-stream;
    ///   cancellation of the iterating `Task` cancels the
    ///   underlying `URLSessionDataTask`; errors from the API
    ///   surface as ``AICloudError`` cases.
    func streamChat(
        request: GitHubMessageRequest,
        apiKey: String
    ) -> AsyncThrowingStream<String, Error>
}

// MARK: - GitHubModelsClient

/// `URLSession`-backed implementation of
/// ``GitHubModelsClientProtocol``.
///
/// Reads GitHub Models' OpenAI-compatible Server-Sent Events
/// stream via `URLSession.bytes(for:)`, decodes each
/// `data: {...}` frame into a ``GitHubStreamEvent``, and yields
/// the text-delta payloads through an `AsyncThrowingStream`. The
/// implementation is `Sendable` (URLSession is Sendable,
/// configuration is a value type, logger is a value-type wrapper).
public final class GitHubModelsClient: GitHubModelsClientProtocol {

    // MARK: - Properties

    /// Static configuration captured at init — base URL, model
    /// identifier, max response tokens.
    private let configuration: GitHubConfiguration

    /// The session used for all requests. Defaults to `.shared`
    /// in production; tests inject a session backed by a
    /// `URLProtocol` stub to return canned SSE responses without
    /// touching the network.
    private let urlSession: URLSession

    private let logger = Logger(subsystem: "com.kozinga.KozBon", category: "GitHubModelsClient")

    // MARK: - Init

    public init(
        configuration: GitHubConfiguration = GitHubConfiguration(),
        urlSession: URLSession = .shared
    ) {
        self.configuration = configuration
        self.urlSession = urlSession
    }

    // MARK: - GitHubModelsClientProtocol

    public func streamChat(
        request: GitHubMessageRequest,
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
                    // user being offline. Surface as the typed
                    // ``.networkUnavailable`` so the chat banner
                    // can attach a Retry button.
                    logger.error(
                        """
                        Network error reaching GitHub Models — \
                        code: \(urlError.code.rawValue, privacy: .public), \
                        description: \(urlError.localizedDescription, privacy: .public)
                        """
                    )
                    continuation.finish(throwing: AICloudError.networkUnavailable)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            // Cancelling the outer stream cancels the underlying
            // URLSession task too — without this, a user
            // navigating away from the chat surface leaves the
            // model generating into the void and blocks the
            // session for the next turn.
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    // MARK: - Streaming Implementation

    private func runStream(
        request: GitHubMessageRequest,
        apiKey: String,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        let urlRequest = try makeURLRequest(body: request, apiKey: apiKey)

        let (bytes, response) = try await urlSession.bytes(for: urlRequest)

        // Validate the HTTP response before reading any bytes.
        // Errors land in the response body as JSON, not SSE — we
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

            // SSE frames are `data: <json>\n\n`. We only care
            // about `data:` lines; everything else (comments,
            // blank separators) we skip.
            guard line.hasPrefix("data:") else { continue }

            let payload = String(line.dropFirst("data:".count))

            guard let event = try GitHubStreamEvent.decode(payload: payload) else {
                // `[DONE]` sentinel — end of stream.
                continuation.finish()
                return
            }

            switch event {
            case .textDelta(let text):
                continuation.yield(text)
            case .error(let message, let type):
                logger.error("GitHub Models inline error (\(type ?? "unknown")): \(message)")
                throw AICloudError.serverError(provider: .github, message: message)
            case .other:
                // Empty delta or unrecognized shape — keep
                // iterating.
                continue
            }
        }

        // Reached end-of-stream without a `[DONE]` sentinel —
        // accept it as a normal terminator.
        continuation.finish()
    }

    // MARK: - Request Construction

    private func makeURLRequest(
        body: GitHubMessageRequest,
        apiKey: String
    ) throws -> URLRequest {
        let endpoint = configuration.baseURL.appendingPathComponent("chat/completions")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

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
        logger.error(
            "GitHub Models API error \(statusCode): \(message ?? "<no message>", privacy: .public)"
        )
        switch statusCode {
        case 401:
            // 401 = bad token. Mirror Anthropic's split between
            // 401 / 403 so the chat surface can offer
            // re-sign-in vs plan-management remediations.
            return .invalidCredentials(provider: .github)
        case 403:
            // 403 = valid token, but the account doesn't have
            // permission for the requested resource (model not
            // in tier, GitHub-Models access disabled on the
            // account, etc.).
            return .permissionDenied(provider: .github, message: message)
        case 429:
            // `Retry-After` may be seconds or an HTTP date; parse
            // numerically and fall back to nil otherwise. GitHub
            // Models uses 429 for both free-tier quota exhaustion
            // and per-minute rate limits — both surface here.
            let retry = response.value(forHTTPHeaderField: "Retry-After")
                .flatMap { TimeInterval($0) }
            return .rateLimited(provider: .github, retryAfterSeconds: retry)
        case 500...599:
            return .serverError(provider: .github, message: message)
        case 400...499:
            // Carve out context-window-exceeded 400s. GitHub
            // Models / OpenAI return messages like
            // "This model's maximum context length is N tokens..."
            // or "context length exceeded". The detection
            // substrings below cover the common wordings while
            // staying tight enough that unrelated 400s don't
            // false-positive.
            if let lowered = message?.lowercased() {
                if lowered.contains("context length")
                    || lowered.contains("maximum context")
                    || lowered.contains("tokens > ")
                    || lowered.contains("too long") {
                    return .contextWindowExceeded(provider: .github, message: message)
                }
            }
            return .invalidRequest(provider: .github, message: message)
        default:
            return .unexpectedStatus(provider: .github, statusCode: statusCode)
        }
    }

    private func extractErrorMessage(from body: String) -> String? {
        // OpenAI / GitHub Models error body shape:
        // `{"error": {"message": "...", "type": "..."}}`
        guard let data = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let error = json["error"] as? [String: Any],
              let message = error["message"] as? String else {
            return nil
        }
        return message
    }

    /// Drains the byte stream into a `String` for non-streaming
    /// error responses. Bounded by the response itself — error
    /// bodies are small JSON objects, well under any reasonable
    /// cap.
    private func readAll(_ bytes: URLSession.AsyncBytes) async throws -> String {
        var accumulator = Data()
        for try await byte in bytes {
            accumulator.append(byte)
            // Defensive cap so a misbehaving error body can't
            // exhaust memory. 64 KB is far more than the API
            // emits for errors.
            if accumulator.count > 64_000 {
                break
            }
        }
        return String(data: accumulator, encoding: .utf8) ?? ""
    }
}
