//
//  StubURLProtocol.swift
//  BonjourAIGitHub
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Synchronization

// MARK: - StubURLProtocol

/// Lightweight `URLProtocol` stub for testing
/// ``GitHubModelsClient`` without touching the network.
///
/// Tests register a handler closure via ``handler`` and the
/// `URLSession` configured with this protocol class routes every
/// request through it. The handler can return canned body bytes
/// (which `GitHubModelsClient` will parse as SSE) and an HTTP
/// status code; the stub fakes a `HTTPURLResponse` with those
/// headers.
final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    // We *do* need @unchecked Sendable here because URLProtocol
    // itself isn't Sendable and inherits NSObject. The class-level
    // suppression is gated to test-only code and is the canonical
    // pattern for URLProtocol stubs. Mirrors the equivalent
    // helper in BonjourAIAnthropic/Tests.

    // MARK: - Handler

    /// What the stub should return for an incoming request.
    enum Response: Sendable {
        /// Send back canned body bytes with the given status code.
        /// Optional extra response headers (e.g. `Retry-After`)
        /// are merged into the synthesized `HTTPURLResponse`.
        case success(statusCode: Int, body: Data, headers: [String: String] = [:])
        /// Fail the request before it sees a response.
        case failure(Error)
    }

    nonisolated(unsafe) static var handler: (@Sendable (URLRequest) -> Response)?

    // MARK: - URLProtocol

    // swiftlint:disable:next static_over_final_class
    override class func canInit(with request: URLRequest) -> Bool { true }
    // swiftlint:disable:next static_over_final_class
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = StubURLProtocol.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }

        switch handler(request) {
        case .success(let statusCode, let body, let headers):
            guard let url = request.url else {
                client?.urlProtocol(self, didFailWithError: URLError(.badURL))
                return
            }
            // GitHub Models' streaming endpoint sets
            // `Content-Type: text/event-stream`; the stub mirrors
            // that so `URLSession.bytes(for:)` parses the response
            // line-by-line as the real session would.
            var responseHeaders = ["Content-Type": "text/event-stream"]
            for (key, value) in headers {
                responseHeaders[key] = value
            }
            let response = HTTPURLResponse(
                url: url,
                statusCode: statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: responseHeaders
            ) ?? HTTPURLResponse()
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: body)
            client?.urlProtocolDidFinishLoading(self)

        case .failure(let error):
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {
        // No-op — the body is delivered synchronously in startLoading.
    }
}

// MARK: - CapturedRequest

/// Mutex-guarded box for capturing a single request from a
/// `@Sendable` handler closure.
final class CapturedRequest: Sendable {

    private let storage = Mutex<URLRequest?>(nil)

    func set(_ request: URLRequest) {
        storage.withLock { $0 = request }
    }

    var value: URLRequest? {
        storage.withLock { $0 }
    }
}
