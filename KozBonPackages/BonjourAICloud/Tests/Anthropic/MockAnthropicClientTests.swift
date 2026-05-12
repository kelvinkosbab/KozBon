//
//  MockAnthropicClientTests.swift
//  BonjourAICloud
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourAICloud

// MARK: - MockAnthropicClientTests

@Suite("MockAnthropicClient")
struct MockAnthropicClientTests {

    // MARK: - Helpers

    private func makeRequest() -> AnthropicMessageRequest {
        AnthropicMessageRequest(
            model: "claude-haiku-4-5",
            maxTokens: 100,
            system: [AnthropicSystemBlock(text: "Test system")],
            messages: [AnthropicMessage(role: .user, content: "Hello")]
        )
    }

    // MARK: - Yielding Chunks

    @Test("Yields supplied chunks in order")
    func yieldsChunksInOrder() async throws {
        let client = MockAnthropicClient(chunks: ["Hello", ", ", "world", "!"])

        var collected: [String] = []
        for try await chunk in client.streamMessage(request: makeRequest(), apiKey: "key") {
            collected.append(chunk)
        }

        #expect(collected == ["Hello", ", ", "world", "!"])
    }

    @Test("Empty chunks list produces a stream that immediately finishes")
    func emptyChunksFinishesImmediately() async throws {
        let client = MockAnthropicClient()

        var collected: [String] = []
        for try await chunk in client.streamMessage(request: makeRequest(), apiKey: "key") {
            collected.append(chunk)
        }

        #expect(collected.isEmpty)
    }

    // MARK: - Errors

    @Test("Errors emit after yielding all chunks")
    func errorsAfterChunks() async throws {
        let injectedError = AICloudError.serverError(provider: .anthropic, message: "boom")
        let client = MockAnthropicClient(
            chunks: ["partial"],
            error: injectedError
        )

        var collected: [String] = []
        var thrownError: Error?

        do {
            for try await chunk in client.streamMessage(request: makeRequest(), apiKey: "key") {
                collected.append(chunk)
            }
        } catch {
            thrownError = error
        }

        #expect(collected == ["partial"])
        let caught = try #require(thrownError as? AICloudError)
        #expect(caught == injectedError)
    }

    // MARK: - Recorded Requests

    @Test("Records every send call with the request and API key")
    func recordsRequests() async throws {
        let client = MockAnthropicClient(chunks: ["x"])

        for try await _ in client.streamMessage(request: makeRequest(), apiKey: "sk-ant-test-1") {}
        for try await _ in client.streamMessage(request: makeRequest(), apiKey: "sk-ant-test-2") {}

        let recorded = client.recordedRequests
        #expect(recorded.count == 2)
        #expect(recorded[0].apiKey == "sk-ant-test-1")
        #expect(recorded[1].apiKey == "sk-ant-test-2")
        #expect(recorded[0].request == makeRequest())
    }
}
