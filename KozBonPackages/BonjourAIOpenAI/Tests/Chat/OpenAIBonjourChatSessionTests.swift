//
//  OpenAIBonjourChatSessionTests.swift
//  BonjourAIOpenAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourAICore
import BonjourCore
import BonjourModels
@testable import BonjourAIOpenAI

// MARK: - OpenAIBonjourChatSessionTests

/// Covers the behaviors the chat surface depends on being identical
/// across backends: streaming into a placeholder, multi-turn
/// history, rollback on failure, and the credential gate.
@Suite("OpenAIBonjourChatSession")
@MainActor
struct OpenAIBonjourChatSessionTests {

    // MARK: - Helpers

    private func makeSession(
        client: MockOpenAIClient,
        seededKey: String? = "sk-proj-test"
    ) -> OpenAIBonjourChatSession {
        let store = InMemoryAICloudCredentialsStore(
            seed: seededKey.map { [.openai: $0] } ?? [:]
        )
        return OpenAIBonjourChatSession(client: client, credentialsStore: store)
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

    // MARK: - Streaming

    @Test("Streamed chunks accumulate into one assistant message")
    func streamsIntoAssistantMessage() async {
        let session = makeSession(client: MockOpenAIClient(chunks: ["Hel", "lo", "!"]))

        session.appendUserMessage("hi")
        await session.send("hi", context: makeContext())

        #expect(session.messages.count == 2)
        #expect(session.messages.last?.content == "Hello!")
        #expect(session.error == nil)
        #expect(!session.isGenerating)
    }

    @Test("The request carries the selected model, instructions, key, and a reasoning setting")
    func sendsModelAndInstructions() async {
        let client = MockOpenAIClient(chunks: ["ok"])
        let session = makeSession(client: client)
        session.selectedModel = "gpt-6-astra"

        await session.send("hi", context: makeContext())

        let recorded = client.recordedRequests.first
        #expect(recorded?.request.model == "gpt-6-astra")
        #expect(recorded?.request.instructions?.isEmpty == false)
        #expect(recorded?.request.reasoning == OpenAIReasoning(effort: "low"))
        #expect(recorded?.apiKey == "sk-proj-test")
    }

    @Test("The second turn replays the first, so the model keeps context")
    func sendsMultiTurnHistory() async {
        let client = MockOpenAIClient(chunks: ["one"])
        let session = makeSession(client: client)

        await session.send("first", context: makeContext())
        await session.send("second", context: makeContext())

        let second = client.recordedRequests.last?.request
        #expect(second?.input.map(\.role) == [.user, .assistant, .user])
    }

    // MARK: - Credentials

    @Test("With no key stored, nothing is sent and the error explains why")
    func requiresAnAPIKey() async {
        let client = MockOpenAIClient(chunks: ["never"])
        let session = makeSession(client: client, seededKey: nil)

        await session.send("hi", context: makeContext())

        #expect(client.recordedRequests.isEmpty)
        #expect(session.error != nil)
    }

    // MARK: - Failure Handling

    @Test("A stream failure rolls the turn back so a retry doesn't double the history")
    func rollsBackOnFailure() async {
        let client = MockOpenAIClient(error: AICloudError.serverError(provider: .openai, message: "boom"))
        let session = makeSession(client: client)

        session.appendUserMessage("hi")
        await session.send("hi", context: makeContext())

        #expect(session.messages.count == 1)
        #expect(session.messages.first?.role == .user)
        #expect(session.error != nil)
    }

    @Test(
        "Each remediable failure offers the matching action",
        arguments: [
            (AICloudError.invalidCredentials(provider: .openai), ChatErrorAction.Kind.openSignIn),
            (AICloudError.contextWindowExceeded(provider: .openai, message: nil), .clearChat),
            (AICloudError.networkUnavailable, .retry)
        ]
    )
    func offersRemediation(error: AICloudError, expected: ChatErrorAction.Kind) async {
        let session = makeSession(client: MockOpenAIClient(error: error))
        await session.send("hi", context: makeContext())
        #expect(session.errorAction?.kind == expected)
    }

    @Test("An exhausted balance links to OpenAI's billing page")
    func billingFailureLinksToBilling() async throws {
        let session = makeSession(
            client: MockOpenAIClient(error: AICloudError.creditBalanceTooLow(provider: .openai, message: nil))
        )
        await session.send("hi", context: makeContext())

        let action = try #require(session.errorAction)
        guard case .openURL(let url) = action.kind else {
            Issue.record("Expected an openURL action, got \(action.kind)")
            return
        }
        #expect(url.host == "platform.openai.com")
    }

    // MARK: - Reset

    @Test("Reset clears the transcript and the replayed history")
    func resetClearsEverything() async {
        let client = MockOpenAIClient(chunks: ["hi"])
        let session = makeSession(client: client)
        await session.send("first", context: makeContext())

        session.reset()
        await session.send("second", context: makeContext())

        #expect(client.recordedRequests.last?.request.input.count == 1)
        #expect(session.messages.count == 1)
    }
}
