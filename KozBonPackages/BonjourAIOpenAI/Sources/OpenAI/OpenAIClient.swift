//
//  OpenAIClient.swift
//  BonjourAIOpenAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourAICore
import BonjourCore

// MARK: - OpenAIClientProtocol

/// Abstraction over OpenAI's streaming Responses API.
///
/// Production uses ``OpenAIClient``; tests substitute
/// ``MockOpenAIClient`` to drive deterministic event sequences
/// without touching the network — the same contract
/// ``GeminiClientProtocol`` offers.
public protocol OpenAIClientProtocol: Sendable {

    /// Sends the request and yields incremental assistant text.
    ///
    /// - Parameters:
    ///   - request: The fully-formed request body.
    ///   - apiKey: The OpenAI API key. Passed per call rather than
    ///     captured at init so one client instance can serve
    ///     different users.
    /// - Returns: A stream of text fragments. It terminates normally
    ///   on `response.completed` or when the connection closes;
    ///   cancelling the iterating `Task` cancels the underlying
    ///   `URLSessionDataTask`; API errors surface as
    ///   ``AICloudError`` cases.
    func streamMessage(
        request: OpenAIResponseRequest,
        apiKey: String
    ) -> AsyncThrowingStream<String, Error>
}

// MARK: - OpenAIClient

/// `URLSession`-backed implementation of ``OpenAIClientProtocol``.
///
/// Reads the SSE stream via `URLSession.bytes(for:)`, decodes each
/// `data: {...}` frame into an ``OpenAIStreamEvent``, and yields the
/// text deltas through an `AsyncThrowingStream`.
public final class OpenAIClient: OpenAIClientProtocol {

    // MARK: - Properties

    private let configuration: OpenAIConfiguration
    private let urlSession: URLSession
    private let logger = Logger(subsystem: "com.kozinga.KozBon", category: "OpenAIClient")

    // MARK: - Init

    public init(
        configuration: OpenAIConfiguration = OpenAIConfiguration(),
        urlSession: URLSession = .shared
    ) {
        self.configuration = configuration
        self.urlSession = urlSession
    }

    // MARK: - OpenAIClientProtocol

    public func streamMessage(
        request: OpenAIResponseRequest,
        apiKey: String
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task { [self] in
                do {
                    try await runStream(request: request, apiKey: apiKey, continuation: continuation)
                } catch is CancellationError {
                    continuation.finish(throwing: AICloudError.cancelled)
                } catch let urlError as URLError {
                    // Typed so the chat surface can offer Retry
                    // instead of making the user re-type.
                    logger.error(
                        """
                        Network error reaching OpenAI — \
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
        request: OpenAIResponseRequest,
        apiKey: String,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        let urlRequest = try makeURLRequest(body: request, apiKey: apiKey)

        let (bytes, response) = try await urlSession.bytes(for: urlRequest)

        // Errors come back as a plain JSON body, not SSE, so the
        // bytes have to be drained to surface them.
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode != 200 {
            let errorBody = try await readAll(bytes)
            throw mapHTTPError(statusCode: httpResponse.statusCode, body: errorBody, response: httpResponse)
        }

        var yieldedText = false
        for try await line in bytes.lines {
            try Task.checkCancellation()

            // `event:` lines repeat the `type` field inside each
            // `data:` payload, so only the payloads are read.
            guard line.hasPrefix("data:") else { continue }
            let payload = String(line.dropFirst("data:".count))

            guard let event = try OpenAIStreamEvent.decode(payload: payload) else {
                continue
            }
            if try handle(event, yieldedText: &yieldedText, continuation: continuation) {
                return
            }
        }

        continuation.finish()
    }

    /// Acts on one decoded event.
    ///
    /// - Returns: `true` once the stream has been finished.
    private func handle(
        _ event: OpenAIStreamEvent,
        yieldedText: inout Bool,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) throws -> Bool {
        switch event {
        case .textDelta(let text):
            guard !text.isEmpty else { return false }
            yieldedText = true
            continuation.yield(text)
            return false
        case .completed:
            continuation.finish()
            return true
        case .incomplete(let reason):
            try finishIncomplete(reason: reason, yieldedText: yieldedText, continuation: continuation)
            return true
        case .failed(let message):
            logger.error("OpenAI response failed: \(message ?? "<no message>")")
            throw AICloudError.serverError(provider: .openai, message: message)
        case .error(let message, let code):
            logger.error("OpenAI inline error (\(code ?? "unknown")): \(message)")
            throw AICloudError.serverError(provider: .openai, message: message)
        case .other(let type):
            logger.debug("OpenAI stream event (no-op): \(type)")
            return false
        }
    }

    /// Ends a stream the API marked incomplete.
    ///
    /// With text already shown, the partial answer is still the
    /// best one available, so the stream finishes normally. With
    /// none — a reasoning model that spent its whole budget
    /// thinking — finishing normally would make the chat surface
    /// silently roll the turn back, so it throws instead.
    private func finishIncomplete(
        reason: String?,
        yieldedText: Bool,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) throws {
        logger.error("OpenAI stopped early: \(reason ?? "unknown")")
        guard yieldedText else {
            throw AICloudError.serverError(
                provider: .openai,
                message: "The response ended before any text was generated (\(reason ?? "incomplete"))."
            )
        }
        continuation.finish()
    }

    // MARK: - Request Construction

    private func makeURLRequest(
        body: OpenAIResponseRequest,
        apiKey: String
    ) throws -> URLRequest {
        let url = configuration.baseURL
            .appendingPathComponent(configuration.apiVersion)
            .appendingPathComponent("responses")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        // A session picks its model long after this client was
        // built; the configuration's model is only the fallback
        // for a request that doesn't name one.
        let resolvedBody = body.model.isEmpty
            ? OpenAIResponseRequest(
                model: configuration.model.rawValue,
                instructions: body.instructions,
                input: body.input,
                maxOutputTokens: body.maxOutputTokens,
                reasoning: body.reasoning
            )
            : body

        do {
            request.httpBody = try JSONEncoder().encode(resolvedBody)
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
        let detail = OpenAIErrorBody.parse(body)
        logger.error("OpenAI API error \(statusCode) (\(detail.code ?? "no code")): \(detail.message ?? "<no message>")")

        switch statusCode {
        case 401:
            return .invalidCredentials(provider: .openai)
        case 403:
            // Unsupported region, or a project key without access
            // to the endpoint.
            return .permissionDenied(provider: .openai, message: detail.message)
        case 429:
            // OpenAI uses 429 for two unrelated problems. An
            // exhausted balance won't clear by waiting, so it gets
            // the billing remediation instead of "try again later".
            if detail.code == "insufficient_quota" {
                return .creditBalanceTooLow(provider: .openai, message: detail.message)
            }
            let retry = response.value(forHTTPHeaderField: "Retry-After")
                .flatMap { TimeInterval($0) }
            return .rateLimited(provider: .openai, retryAfterSeconds: retry)
        case 503:
            return .serviceOverloaded(provider: .openai, message: detail.message)
        case 500...599:
            return .serverError(provider: .openai, message: detail.message)
        case 400...499:
            return mapClientError(detail)
        default:
            return .unexpectedStatus(provider: .openai, statusCode: statusCode)
        }
    }

    /// The 4xx cases separated by error code rather than status.
    private func mapClientError(_ detail: OpenAIErrorBody) -> AICloudError {
        let lowered = detail.message?.lowercased() ?? ""
        if detail.code == "context_length_exceeded" || lowered.contains("context length") {
            return .contextWindowExceeded(provider: .openai, message: detail.message)
        }
        return .invalidRequest(provider: .openai, message: detail.message)
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

// MARK: - OpenAIErrorBody

/// The `{"error": {"message": …, "code": …}}` envelope OpenAI returns
/// on every non-2xx response.
struct OpenAIErrorBody: Equatable {
    let message: String?
    let code: String?

    static func parse(_ body: String) -> OpenAIErrorBody {
        guard let data = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let error = json["error"] as? [String: Any] else {
            return OpenAIErrorBody(message: nil, code: nil)
        }
        return OpenAIErrorBody(
            message: error["message"] as? String,
            code: error["code"] as? String
        )
    }
}
