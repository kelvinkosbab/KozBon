//
//  AnthropicBonjourChatSessionTests.swift
//  BonjourAICloud
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourAI
import BonjourCore
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

    /// Builds a `BonjourService` instance for context-flow tests.
    /// Mirrors the helper in `BonjourServiceTests` so the wire
    /// format matches what the production view model actually
    /// hands to the session.
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

    // MARK: - Clear Error

    @Test("`clearError` resets both `error` and `errorAction` without touching the conversation")
    func clearErrorResetsBannerStateOnly() async throws {
        // Set up the failure-with-action state by stubbing the
        // client to throw `.creditBalanceTooLow`. That's the one
        // case in the mapper that populates `errorAction`, so it's
        // the only path that exercises the override.
        let client = MockAnthropicClient(
            chunks: [],
            error: AICloudError.creditBalanceTooLow(
                provider: .anthropic,
                message: "Your credit balance is too low"
            )
        )
        let session = makeSession(client: client)

        // First send fails — banner state lands populated.
        session.appendUserMessage("hi")
        await session.send("hi", context: makeContext())
        #expect(session.error != nil)
        #expect(session.errorAction != nil)
        let messageCount = session.messages.count

        // `clearError` wipes both halves of the banner state.
        session.clearError()

        #expect(session.error == nil)
        #expect(session.errorAction == nil)
        // The conversation is untouched — the user's bubble from
        // the failed turn stays in `messages` so the chat history
        // is coherent for the follow-up send.
        #expect(session.messages.count == messageCount)
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

    // MARK: - Context Flow
    //
    // The recommended-prompt path runs a fresh `BonjourOneShotScanner`
    // pass on suggestion taps that look like "what's on my network?",
    // then hands the discovered services to the session via
    // `ChatContext`. These tests prove the context content actually
    // shows up in Claude's request body — without them, a future
    // refactor that accidentally drops the context prepend (e.g.,
    // skipping `BonjourChatPromptBuilder.userTurn(...)`) would still
    // pass the existing "empty context" happy-path tests.

    @Test("First-turn request embeds the discovered services in the user message")
    func firstTurnIncludesDiscoveredServicesInRequest() async throws {
        let client = MockAnthropicClient(chunks: ["ok"])
        let session = makeSession(client: client)

        // Two services with distinctive names so the assertion
        // can pinpoint each one in the rendered prompt without
        // ambiguity. `serviceTypeLibrary` stays empty here —
        // `BonjourServiceType.fetchAll()` would pull from the
        // Core Data custom-types store, which can't load under
        // `swift test` (only under `xcodebuild test`).
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
        let userMessageContent = try #require(request.messages.first?.content)

        // Wrapping tags from `BonjourChatPromptBuilder.contextPreamble`.
        // If these are missing, the user-turn composer skipped the
        // context block — the bug we're guarding against.
        #expect(
            userMessageContent.contains("<context>"),
            "first-turn request must include the <context> wrapper"
        )
        #expect(userMessageContent.contains("</context>"))

        // Both service names from the supplied context block.
        // Asserting on names (not type identifiers) confirms
        // `contextBlock` enumerates the real, user-provided
        // services rather than emitting a stub.
        #expect(userMessageContent.contains("Living Room Apple TV"))
        #expect(userMessageContent.contains("Office Printer"))

        // And the user's actual question follows the context.
        #expect(userMessageContent.contains("What services are on my network?"))
    }

    @Test("Subsequent turns with the same context skip the context block to save tokens")
    func subsequentTurnsSkipUnchangedContextBlock() async throws {
        let client = MockAnthropicClient(chunks: ["ok"])
        let session = makeSession(client: client)

        let context = BonjourChatPromptBuilder.ChatContext(
            discoveredServices: [makeService(name: "AirPort", type: "http")],
            publishedServices: [],
            serviceTypeLibrary: [],
            lastScanTime: Date(),
            isScanning: false
        )

        // Two sends with identical context. The first should
        // include the context block; the second should NOT —
        // re-injecting the same block on every turn would waste
        // tokens (and break prompt-cache reuse for long
        // conversations).
        session.appendUserMessage("first")
        await session.send("first", context: context)

        session.appendUserMessage("second")
        await session.send("second", context: context)

        let recorded = client.recordedRequests
        #expect(recorded.count == 2)

        let firstTurnContent = recorded[0].request.messages[0].content
        #expect(firstTurnContent.contains("<context>"))
        #expect(firstTurnContent.contains("AirPort"))

        // The second turn's user message — the LAST entry in the
        // second request's history — should be the question
        // alone, no context wrapper. (Earlier history entries
        // still contain the first turn's context, since they
        // replay verbatim.)
        let secondRequest = recorded[1].request
        let lastMessageInSecondTurn = try #require(secondRequest.messages.last?.content)
        #expect(
            !lastMessageInSecondTurn.contains("<context>"),
            "subsequent turn must NOT re-prepend the context block when it hasn't changed"
        )
        #expect(lastMessageInSecondTurn.contains("second"))
    }

    @Test("A changed context (e.g., after a fresh scan) is re-injected on the next turn")
    func changedContextIsReinjected() async throws {
        let client = MockAnthropicClient(chunks: ["ok"])
        let session = makeSession(client: client)

        let firstContext = BonjourChatPromptBuilder.ChatContext(
            discoveredServices: [makeService(name: "Initial Device", type: "http")],
            publishedServices: [],
            serviceTypeLibrary: [],
            lastScanTime: Date(),
            isScanning: false
        )

        // Same shape, different services — simulates a fresh
        // scan turning up new devices between turns.
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

        // The newly-discovered service must appear in the
        // re-injected context block on the second turn.
        #expect(secondTurnLastMessage.contains("<context>"))
        #expect(secondTurnLastMessage.contains("Newly Discovered Speaker"))
    }

    @Test("Published services from the context reach Claude's user message")
    func publishedServicesReachRequest() async throws {
        let client = MockAnthropicClient(chunks: ["ok"])
        let session = makeSession(client: client)

        let context = BonjourChatPromptBuilder.ChatContext(
            discoveredServices: [],
            publishedServices: [makeService(name: "My Broadcast", type: "http")],
            serviceTypeLibrary: [],
            lastScanTime: Date(),
            isScanning: false
        )

        session.appendUserMessage("What am I broadcasting?")
        await session.send("What am I broadcasting?", context: context)

        let request = try #require(client.recordedRequests.first?.request)
        #expect(request.messages.first?.content.contains("My Broadcast") == true)
    }
}
