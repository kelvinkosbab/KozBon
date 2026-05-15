//
//  MockGitHubModelsClientTests.swift
//  BonjourAIGitHub
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourAICore
@testable import BonjourAIGitHub

// MARK: - MockGitHubModelsClientTests

@Suite("MockGitHubModelsClient")
struct MockGitHubModelsClientTests {

    // MARK: - Helpers

    private func makeRequest() -> GitHubMessageRequest {
        GitHubMessageRequest(
            model: "gpt-4o",
            messages: [
                GitHubMessage(role: .system, content: "Test system"),
                GitHubMessage(role: .user, content: "Hello")
            ],
            maxTokens: 100
        )
    }

    // MARK: - Yielding Chunks

    @Test("Yields supplied chunks in order")
    func yieldsChunksInOrder() async throws {
        let client = MockGitHubModelsClient(chunks: ["Hello", ", ", "world", "!"])

        var collected: [String] = []
        for try await chunk in client.streamChat(request: makeRequest(), apiKey: "ghp_test") {
            collected.append(chunk)
        }

        #expect(collected == ["Hello", ", ", "world", "!"])
    }

    @Test("Empty chunks list produces a stream that immediately finishes")
    func emptyChunksFinishesImmediately() async throws {
        let client = MockGitHubModelsClient()

        var collected: [String] = []
        for try await chunk in client.streamChat(request: makeRequest(), apiKey: "ghp_test") {
            collected.append(chunk)
        }

        #expect(collected.isEmpty)
    }

    // MARK: - Errors

    @Test("Errors emit after yielding all chunks")
    func errorsAfterChunks() async throws {
        let injectedError = AICloudError.serverError(provider: .github, message: "boom")
        let client = MockGitHubModelsClient(
            chunks: ["partial"],
            error: injectedError
        )

        var collected: [String] = []
        var thrownError: Error?

        do {
            for try await chunk in client.streamChat(request: makeRequest(), apiKey: "ghp_test") {
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

    @Test("Records every send call with the request and PAT")
    func recordsRequests() async throws {
        let client = MockGitHubModelsClient(chunks: ["x"])

        for try await _ in client.streamChat(request: makeRequest(), apiKey: "ghp_one") {}
        for try await _ in client.streamChat(request: makeRequest(), apiKey: "ghp_two") {}

        let recorded = client.recordedRequests
        #expect(recorded.count == 2)
        #expect(recorded[0].apiKey == "ghp_one")
        #expect(recorded[1].apiKey == "ghp_two")
        #expect(recorded[0].request == makeRequest())
    }
}
