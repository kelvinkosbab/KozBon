//
//  AnthropicBonjourChatSessionTests.swift
//  BonjourAICloud
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourAI
import BonjourModels
@testable import BonjourAICloud

// MARK: - AnthropicBonjourChatSessionTests

@Suite("AnthropicBonjourChatSession")
@MainActor
struct AnthropicBonjourChatSessionTests {

    // MARK: - Helpers

    /// Builds a session with the given mock client and (optionally)
    /// a seeded credentials store. Tests that need to assert on
    /// request shape pass the same mock back in.
    private func makeSession(
        client: MockAnthropicClient,
        seededKey: String? = "sk-ant-test-key-1234"
    ) -> AnthropicBonjourChatSession {
        let store = InMemoryAICloudCredentialsStore(
            seed: seededKey.map { [.anthropic: $0] } ?? [:]
        )
        return AnthropicBonjourChatSession(
            client: client,
            credentialsStore: store
        )
    }

    private func makeContext() -> BonjourChatPromptBuilder.ChatContext {
        BonjourChatPromptBuilder.ChatContext(
            discoveredServices: [],
            publishedServices: [],
            serviceTypeLibrary: [],
            lastScanTime: nil,
            isScanning: false
        )
    }

    // MARK: - Streaming Happy Path

    @Test("Streamed chunks accumulate into the assistant message")
    func streamsAssistantTokens() async throws {
        let client = MockAnthropicClient(chunks: ["Hello", ", ", "world!"])
        let session = makeSession(client: client)
        session.appendUserMessage("hi")

        await session.send("hi", context: makeContext())

        #expect(session.messages.count == 2)
        #expect(session.messages[0].role == .user)
        #expect(session.messages[0].content == "hi")
        #expect(session.messages[1].role == .assistant)
        #expect(session.messages[1].content == "Hello, world!")
        #expect(!session.isGenerating)
        #expect(session.error == nil)
    }

    @Test("`appendUserMessage` ignores whitespace-only input")
    func appendIgnoresWhitespace() {
        let client = MockAnthropicClient()
        let session = makeSession(client: client)
        session.appendUserMessage("   \n   ")
        #expect(session.messages.isEmpty)
    }

    // MARK: - Conversation History

    @Test("Multiple sends build a multi-turn history")
    func buildsMultiTurnHistory() async throws {
        let client = MockAnthropicClient(chunks: ["Reply 1"])
        let session = makeSession(client: client)

        session.appendUserMessage("first")
        await session.send("first", context: makeContext())

        // The next send needs a fresh client (or chunks would
        // exhaust). Same client is fine since `chunks` is `let`
        // — every call yields the same sequence in this mock.
        session.appendUserMessage("second")
        await session.send("second", context: makeContext())

        // Three rendered messages: user1, asst1, user2... wait,
        // the final asst is in messages too: user, asst, user, asst.
        #expect(session.messages.count == 4)

        // Two recorded API calls:
        let recorded = client.recordedRequests
        #expect(recorded.count == 2)

        // First call sent one user message; second call sent
        // user1 / asst1 / user2.
        #expect(recorded[0].request.messages.count == 1)
        #expect(recorded[0].request.messages[0].role == .user)
        #expect(recorded[1].request.messages.count == 3)
        #expect(recorded[1].request.messages.map(\.role) == [.user, .assistant, .user])
    }

    // MARK: - System Block + Caching

    @Test("Every request carries a single cached system block")
    func sendsCachedSystemBlock() async throws {
        let client = MockAnthropicClient(chunks: ["ok"])
        let session = makeSession(client: client)

        session.appendUserMessage("hello")
        await session.send("hello", context: makeContext())

        let request = try #require(client.recordedRequests.first?.request)
        #expect(request.system.count == 1)
        #expect(request.system[0].cacheControl == .ephemeral)
        #expect(request.system[0].text.isEmpty == false)
    }

    @Test("Selected model identifier reaches the API request")
    func sendsSelectedModel() async throws {
        let client = MockAnthropicClient(chunks: ["ok"])
        let session = makeSession(client: client)
        session.selectedModel = .opus

        session.appendUserMessage("hello")
        await session.send("hello", context: makeContext())

        let request = try #require(client.recordedRequests.first?.request)
        #expect(request.model == AnthropicModel.opus.rawValue)
    }

    // MARK: - API Key

    @Test("Missing API key surfaces `.missingCredentials` and short-circuits the request")
    func missingKeyShortCircuits() async {
        let client = MockAnthropicClient(chunks: ["should not be sent"])
        let session = makeSession(client: client, seededKey: nil)

        session.appendUserMessage("hello")
        await session.send("hello", context: makeContext())

        #expect(session.error != nil)
        // The user bubble is in messages; the assistant
        // placeholder is not (the request never started).
        #expect(session.messages.count == 1)
        #expect(session.messages[0].role == .user)
        #expect(client.recordedRequests.isEmpty)
    }

    @Test("API key reaches the request as the x-api-key value")
    func apiKeyForwardedToRequest() async throws {
        let client = MockAnthropicClient(chunks: ["ok"])
        let session = makeSession(client: client, seededKey: "sk-ant-routing-test")

        session.appendUserMessage("hi")
        await session.send("hi", context: makeContext())

        let recorded = try #require(client.recordedRequests.first)
        #expect(recorded.apiKey == "sk-ant-routing-test")
    }

    // MARK: - Error Handling

    @Test("Stream errors surface on `session.error` and drop the placeholder")
    func streamErrorRollsBack() async throws {
        let client = MockAnthropicClient(
            chunks: [],
            error: AICloudError.invalidCredentials(provider: .anthropic)
        )
        let session = makeSession(client: client)

        session.appendUserMessage("hi")
        await session.send("hi", context: makeContext())

        #expect(session.error != nil)
        // Only the user message remains; the empty assistant
        // placeholder was removed.
        #expect(session.messages.count == 1)
        #expect(session.messages[0].role == .user)
    }

    // MARK: - Reset / Restore

    @Test("`reset` clears messages, conversation history, and error state")
    func resetClearsAll() async throws {
        let client = MockAnthropicClient(chunks: ["ok"])
        let session = makeSession(client: client)

        session.appendUserMessage("hi")
        await session.send("hi", context: makeContext())

        #expect(session.messages.count == 2)
        session.reset()

        #expect(session.messages.isEmpty)
        #expect(session.error == nil)
    }

    @Test("`restore` replaces visible history without seeding the API turn list")
    func restoreReplacesVisibleHistory() async throws {
        let client = MockAnthropicClient(chunks: ["ok"])
        let session = makeSession(client: client)

        // First send populates conversation + visible history.
        session.appendUserMessage("first")
        await session.send("first", context: makeContext())
        let recordedBefore = client.recordedRequests.count

        session.restore(messages: [
            BonjourChatMessage(role: .user, content: "restored"),
            BonjourChatMessage(role: .assistant, content: "you-said-restored")
        ])

        #expect(session.messages.count == 2)
        // No new API call from `restore`.
        #expect(client.recordedRequests.count == recordedBefore)

        // The next user send starts fresh on the Anthropic side
        // — restored messages are NOT in `conversationHistory`.
        session.appendUserMessage("next")
        await session.send("next", context: makeContext())

        let lastRequest = try #require(client.recordedRequests.last?.request)
        #expect(lastRequest.messages.count == 1)
        #expect(lastRequest.messages[0].content.contains("next"))
    }

    // MARK: - Local Rejection

    @Test("`appendLocalRejection` adds two messages without an API call")
    func localRejectionDoesNotCallAPI() {
        let client = MockAnthropicClient()
        let session = makeSession(client: client)

        session.appendLocalRejection(
            userMessage: "what's the weather?",
            refusalText: "Off-topic — I can only help with Bonjour services."
        )

        #expect(session.messages.count == 2)
        #expect(session.messages[0].role == .user)
        #expect(session.messages[1].role == .assistant)
        #expect(client.recordedRequests.isEmpty)
    }
}
