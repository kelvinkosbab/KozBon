//
//  MockOpenAIClient.swift
//  BonjourAIOpenAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Synchronization
import BonjourAICore

// MARK: - MockOpenAIClient

/// Deterministic stand-in for ``OpenAIClient`` in tests and
/// previews.
///
/// Yields the supplied ``chunks`` in order, then either finishes
/// the stream normally or throws the supplied ``error``. Every call
/// is recorded into ``recordedRequests`` so tests can assert against
/// what the session would have sent.
///
/// `Sendable` without `@unchecked`: configuration is `let`-bound,
/// and the recorded state is guarded by a `Mutex`.
public final class MockOpenAIClient: OpenAIClientProtocol, Sendable {

    // MARK: - Configuration (immutable)

    /// Text chunks the stream will yield, in order.
    public let chunks: [String]

    /// Optional error to throw after yielding all chunks. When
    /// `nil`, the stream finishes normally.
    public let error: (any Error & Sendable)?

    /// Delay between yielded chunks, for previews that want the
    /// stream to feel like a real network response.
    public let perChunkDelay: Duration

    // MARK: - Recorded State

    /// A single recorded send call.
    public struct Recorded: Sendable, Equatable {
        public let request: OpenAIResponseRequest
        public let apiKey: String
    }

    private let recordedStorage = Mutex<[Recorded]>([])

    /// Every request the mock observed, in send order.
    public var recordedRequests: [Recorded] {
        recordedStorage.withLock { $0 }
    }

    // MARK: - Init

    public init(
        chunks: [String] = [],
        error: (any Error & Sendable)? = nil,
        perChunkDelay: Duration = .zero
    ) {
        self.chunks = chunks
        self.error = error
        self.perChunkDelay = perChunkDelay
    }

    // MARK: - OpenAIClientProtocol

    public func streamMessage(
        request: OpenAIResponseRequest,
        apiKey: String
    ) -> AsyncThrowingStream<String, Error> {
        recordedStorage.withLock { $0.append(Recorded(request: request, apiKey: apiKey)) }

        let chunks = self.chunks
        let error = self.error
        let delay = self.perChunkDelay

        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    for chunk in chunks {
                        try Task.checkCancellation()
                        if delay > .zero {
                            try await Task.sleep(for: delay)
                        }
                        continuation.yield(chunk)
                    }
                    if let error {
                        continuation.finish(throwing: error)
                    } else {
                        continuation.finish()
                    }
                } catch is CancellationError {
                    continuation.finish(throwing: AICloudError.cancelled)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}
