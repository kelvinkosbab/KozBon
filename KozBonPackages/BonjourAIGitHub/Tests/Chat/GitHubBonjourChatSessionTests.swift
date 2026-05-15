//
//  GitHubBonjourChatSessionTests.swift
//  BonjourAIGitHub
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourAI
import BonjourCore
import BonjourModels
import BonjourAICore
@testable import BonjourAIGitHub

// MARK: - GitHubBonjourChatSessionTests

@Suite("GitHubBonjourChatSession")
@MainActor
struct GitHubBonjourChatSessionTests {

    // MARK: - Helpers

    private func makeSession(
        client: MockGitHubModelsClient,
        seededKey: String? = "ghp_test_token_1234"
    ) -> GitHubBonjourChatSession {
        let store = InMemoryAICloudCredentialsStore(
            seed: seededKey.map { [.github: $0] } ?? [:]
        )
        return GitHubBonjourChatSession(
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

    /// Builds a `BonjourService` instance for context-flow tests.
    private func makeService(name: String, type: String, port: Int32 = 8080) -> BonjourService {
        let serviceType = BonjourServiceType(name: type.uppercased(), type: type, transportLayer: .tcp)
        return BonjourService(
            service: NetService(domain: "local.", type: serviceType.fullType, name: name, port: port),
            serviceType: serviceType
        )
    }

    // MARK: - Streaming Happy Path

    @Test("Streamed chunks accumulate into the assistant message")
    func streamsAssistantTokens() async throws {
        let client = MockGitHubModelsClient(chunks: ["Hello", ", ", "world!"])
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
        let client = MockGitHubModelsClient()
        let session = makeSession(client: client)
        session.appendUserMessage("   \n   ")
        #expect(session.messages.isEmpty)
    }

    // MARK: - Conversation History

    @Test("Multiple sends build a multi-turn history with a leading system message")
    func buildsMultiTurnHistory() async throws {
        let client = MockGitHubModelsClient(chunks: ["Reply 1"])
        let session = makeSession(client: client)

        session.appendUserMessage("first")
        await session.send("first", context: makeContext())

        session.appendUserMessage("second")
        await session.send("second", context: makeContext())

        #expect(session.messages.count == 4)

        let recorded = client.recordedRequests
        #expect(recorded.count == 2)

        // First call: system + user1 = 2 messages.
        #expect(recorded[0].request.messages.count == 2)
        #expect(recorded[0].request.messages[0].role == .system)
        #expect(recorded[0].request.messages[1].role == .user)

        // Second call: system + user1 + asst1 + user2 = 4 messages.
        #expect(recorded[1].request.messages.count == 4)
        #expect(recorded[1].request.messages.map(\.role) == [.system, .user, .assistant, .user])
    }

    // MARK: - System Message Shape

    @Test("Every request carries a single system message as the leading entry")
    func sendsLeadingSystemMessage() async throws {
        let client = MockGitHubModelsClient(chunks: ["ok"])
        let session = makeSession(client: client)

        session.appendUserMessage("hello")
        await session.send("hello", context: makeContext())

        let request = try #require(client.recordedRequests.first?.request)
        #expect(request.messages.first?.role == .system)
        #expect(request.messages.first?.content.isEmpty == false)
    }

    @Test("Hardcoded `gpt-4o` model identifier reaches the API request")
    func sendsHardcodedModel() async throws {
        let client = MockGitHubModelsClient(chunks: ["ok"])
        let session = makeSession(client: client)

        session.appendUserMessage("hello")
        await session.send("hello", context: makeContext())

        let request = try #require(client.recordedRequests.first?.request)
        #expect(request.model == "gpt-4o")
    }

    // MARK: - PAT

    @Test("Missing PAT surfaces `.missingCredentials` and short-circuits the request")
    func missingKeyShortCircuits() async {
        let client = MockGitHubModelsClient(chunks: ["should not be sent"])
        let session = makeSession(client: client, seededKey: nil)

        session.appendUserMessage("hello")
        await session.send("hello", context: makeContext())

        #expect(session.error != nil)
        #expect(session.messages.count == 1)
        #expect(session.messages[0].role == .user)
        #expect(client.recordedRequests.isEmpty)
    }

    @Test("PAT reaches the request as the Authorization value")
    func patForwardedToRequest() async throws {
        let client = MockGitHubModelsClient(chunks: ["ok"])
        let session = makeSession(client: client, seededKey: "ghp_routing_test")

        session.appendUserMessage("hi")
        await session.send("hi", context: makeContext())

        let recorded = try #require(client.recordedRequests.first)
        #expect(recorded.apiKey == "ghp_routing_test")
    }

    // MARK: - Error Handling

    @Test("Stream errors surface on `session.error` and drop the placeholder")
    func streamErrorRollsBack() async throws {
        let client = MockGitHubModelsClient(
            chunks: [],
            error: AICloudError.invalidCredentials(provider: .github)
        )
        let session = makeSession(client: client)

        session.appendUserMessage("hi")
        await session.send("hi", context: makeContext())

        #expect(session.error != nil)
        #expect(session.messages.count == 1)
        #expect(session.messages[0].role == .user)
    }

    // MARK: - Clear Error

    @Test("`clearError` resets both `error` and `errorAction` without touching the conversation")
    func clearErrorResetsBannerStateOnly() async throws {
        let client = MockGitHubModelsClient(
            chunks: [],
            error: AICloudError.networkUnavailable
        )
        let session = makeSession(client: client)

        session.appendUserMessage("hi")
        await session.send("hi", context: makeContext())
        #expect(session.error != nil)
        #expect(session.errorAction != nil)
        let messageCount = session.messages.count

        session.clearError()

        #expect(session.error == nil)
        #expect(session.errorAction == nil)
        #expect(session.messages.count == messageCount)
    }

    // MARK: - Reset / Restore

    @Test("`reset` clears messages, conversation history, and error state")
    func resetClearsAll() async throws {
        let client = MockGitHubModelsClient(chunks: ["ok"])
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
        let client = MockGitHubModelsClient(chunks: ["ok"])
        let session = makeSession(client: client)

        session.appendUserMessage("first")
        await session.send("first", context: makeContext())
        let recordedBefore = client.recordedRequests.count

        session.restore(messages: [
            BonjourChatMessage(role: .user, content: "restored"),
            BonjourChatMessage(role: .assistant, content: "you-said-restored")
        ])

        #expect(session.messages.count == 2)
        #expect(client.recordedRequests.count == recordedBefore)

        // Next send starts fresh on the GitHub side — restored
        // messages are NOT in `conversationHistory`. The leading
        // system message is still there, so the count is 2
        // (system + user).
        session.appendUserMessage("next")
        await session.send("next", context: makeContext())

        let lastRequest = try #require(client.recordedRequests.last?.request)
        #expect(lastRequest.messages.count == 2)
        #expect(lastRequest.messages[0].role == .system)
        #expect(lastRequest.messages[1].role == .user)
        #expect(lastRequest.messages[1].content.contains("next"))
    }

    // MARK: - Local Rejection

    @Test("`appendLocalRejection` adds two messages without an API call")
    func localRejectionDoesNotCallAPI() {
        let client = MockGitHubModelsClient()
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

    // MARK: - Context Flow

    @Test("First-turn request embeds the discovered services in the user message")
    func firstTurnIncludesDiscoveredServicesInRequest() async throws {
        let client = MockGitHubModelsClient(chunks: ["ok"])
        let session = makeSession(client: client)

        let context = BonjourChatPromptBuilder.ChatContext(
            discoveredServices: [
                makeService(name: "Living Room Apple TV", type: "airplay"),
                makeService(name: "Office Printer", type: "ipp", port: 631)
            ],
            publishedServices: [],
            serviceTypeLibrary: [],
            lastScanTime: Date(),
            isScanning: false
        )

        session.appendUserMessage("What services are on my network?")
        await session.send("What services are on my network?", context: context)

        let request = try #require(client.recordedRequests.first?.request)
        // The user message is the last message in the request
        // (system comes first).
        let userMessageContent = try #require(request.messages.last?.content)

        #expect(
            userMessageContent.contains("<context>"),
            "first-turn request must include the <context> wrapper"
        )
        #expect(userMessageContent.contains("</context>"))
        #expect(userMessageContent.contains("Living Room Apple TV"))
        #expect(userMessageContent.contains("Office Printer"))
        #expect(userMessageContent.contains("What services are on my network?"))
    }

    @Test("Subsequent turns with the same context skip the context block to save tokens")
    func subsequentTurnsSkipUnchangedContextBlock() async throws {
        let client = MockGitHubModelsClient(chunks: ["ok"])
        let session = makeSession(client: client)

        let context = BonjourChatPromptBuilder.ChatContext(
            discoveredServices: [makeService(name: "AirPort", type: "http")],
            publishedServices: [],
            serviceTypeLibrary: [],
            lastScanTime: Date(),
            isScanning: false
        )

        session.appendUserMessage("first")
        await session.send("first", context: context)

        session.appendUserMessage("second")
        await session.send("second", context: context)

        let recorded = client.recordedRequests
        #expect(recorded.count == 2)

        // First turn's user message is the last in the request
        // body (system leads); it carries the context wrapper.
        let firstTurnUserContent = try #require(recorded[0].request.messages.last?.content)
        #expect(firstTurnUserContent.contains("<context>"))
        #expect(firstTurnUserContent.contains("AirPort"))

        // Second turn's user message is similarly the last
        // entry. The context wrapper should NOT re-prepend.
        let secondTurnUserContent = try #require(recorded[1].request.messages.last?.content)
        #expect(
            !secondTurnUserContent.contains("<context>"),
            "subsequent turn must NOT re-prepend the context block when it hasn't changed"
        )
        #expect(secondTurnUserContent.contains("second"))
    }

    @Test("A changed context (e.g., after a fresh scan) is re-injected on the next turn")
    func changedContextIsReinjected() async throws {
        let client = MockGitHubModelsClient(chunks: ["ok"])
        let session = makeSession(client: client)

        let firstContext = BonjourChatPromptBuilder.ChatContext(
            discoveredServices: [makeService(name: "Initial Device", type: "http")],
            publishedServices: [],
            serviceTypeLibrary: [],
            lastScanTime: Date(),
            isScanning: false
        )

        let updatedContext = BonjourChatPromptBuilder.ChatContext(
            discoveredServices: [
                makeService(name: "Initial Device", type: "http"),
                makeService(name: "Newly Discovered Speaker", type: "raop")
            ],
            publishedServices: [],
            serviceTypeLibrary: [],
            lastScanTime: Date(),
            isScanning: false
        )

        session.appendUserMessage("first")
        await session.send("first", context: firstContext)

        session.appendUserMessage("second")
        await session.send("second", context: updatedContext)

        let recorded = client.recordedRequests
        let secondTurnLastMessage = try #require(recorded[1].request.messages.last?.content)

        #expect(secondTurnLastMessage.contains("<context>"))
        #expect(secondTurnLastMessage.contains("Newly Discovered Speaker"))
    }
}
