//
//  GeminiBonjourChatSessionTests.swift
//  BonjourAIGemini
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourAICore
import BonjourCore
import BonjourModels
@testable import BonjourAIGemini

// MARK: - GeminiBonjourChatSessionTests

/// Covers the behaviors the chat surface depends on being
/// identical across backends: streaming into a placeholder,
/// multi-turn history, rollback on failure, and the credential
/// gate.
@Suite("GeminiBonjourChatSession")
@MainActor
struct GeminiBonjourChatSessionTests {

    // MARK: - Helpers

    private func makeSession(
        client: MockGeminiClient,
        seededKey: String? = "AIzaTestKey1234"
    ) -> GeminiBonjourChatSession {
        let store = InMemoryAICloudCredentialsStore(
            seed: seededKey.map { [.gemini: $0] } ?? [:]
        )
        return GeminiBonjourChatSession(client: client, credentialsStore: store)
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
        let client = MockGeminiClient(chunks: ["Hel", "lo", "!"])
        let session = makeSession(client: client)

        session.appendUserMessage("hi")
        await session.send("hi", context: makeContext())

        #expect(session.messages.count == 2)
        #expect(session.messages.last?.role == .assistant)
        #expect(session.messages.last?.content == "Hello!")
        #expect(session.error == nil)
        #expect(!session.isGenerating)
    }

    @Test("The request carries the selected model and the system instructions")
    func sendsModelAndSystemInstruction() async {
        let client = MockGeminiClient(chunks: ["ok"])
        let session = makeSession(client: client)
        session.selectedModel = "gemini-2.5-pro"

        await session.send("hi", context: makeContext())

        let recorded = client.recordedRequests
        #expect(recorded.count == 1)
        #expect(recorded.first?.request.model == "gemini-2.5-pro")
        #expect(recorded.first?.request.systemInstruction != nil)
        // The instruction block carries no role — Gemini takes it
        // as its own top-level field, not as a turn.
        #expect(recorded.first?.request.systemInstruction?.role == nil)
        #expect(recorded.first?.apiKey == "AIzaTestKey1234")
    }

    @Test("The second turn replays the first, so the model keeps context")
    func sendsMultiTurnHistory() async {
        let client = MockGeminiClient(chunks: ["one"])
        let session = makeSession(client: client)

        await session.send("first", context: makeContext())
        await session.send("second", context: makeContext())

        let second = client.recordedRequests.last?.request
        // user, model, user
        #expect(second?.contents.count == 3)
        #expect(second?.contents.map(\.role) == [.user, .model, .user])
    }

    // MARK: - Credentials

    @Test("With no key stored, nothing is sent and the error explains why")
    func requiresAnAPIKey() async {
        let client = MockGeminiClient(chunks: ["never"])
        let session = makeSession(client: client, seededKey: nil)

        await session.send("hi", context: makeContext())

        #expect(client.recordedRequests.isEmpty)
        #expect(session.error != nil)
        #expect(!session.isGenerating)
    }

    // MARK: - Failure Handling

    @Test("A stream failure rolls the turn back so a retry doesn't double the history")
    func rollsBackOnFailure() async {
        let client = MockGeminiClient(
            chunks: [],
            error: AICloudError.serverError(provider: .gemini, message: "boom")
        )
        let session = makeSession(client: client)

        session.appendUserMessage("hi")
        await session.send("hi", context: makeContext())

        // The user's bubble stays; the empty assistant placeholder
        // is removed rather than left hanging.
        #expect(session.messages.count == 1)
        #expect(session.messages.first?.role == .user)
        #expect(session.error != nil)
    }

    @Test("An invalid-credentials failure offers the in-app sign-in remediation")
    func offersSignInActionOnAuthFailure() async {
        let client = MockGeminiClient(
            chunks: [],
            error: AICloudError.invalidCredentials(provider: .gemini)
        )
        let session = makeSession(client: client)

        await session.send("hi", context: makeContext())

        #expect(session.errorAction?.kind == .openSignIn)
    }

    @Test("clearError clears the action too, so no message-less banner is left behind")
    func clearErrorClearsAction() async {
        let client = MockGeminiClient(
            chunks: [],
            error: AICloudError.networkUnavailable
        )
        let session = makeSession(client: client)
        await session.send("hi", context: makeContext())
        #expect(session.errorAction != nil)

        session.clearError()

        #expect(session.error == nil)
        #expect(session.errorAction == nil)
    }

    // MARK: - Reset

    @Test("Reset clears the transcript and the replayed history")
    func resetClearsEverything() async {
        let client = MockGeminiClient(chunks: ["hi"])
        let session = makeSession(client: client)
        await session.send("first", context: makeContext())

        session.reset()
        await session.send("second", context: makeContext())

        // A single user turn, so the pre-reset exchange is gone.
        #expect(client.recordedRequests.last?.request.contents.count == 1)
        #expect(session.messages.count == 1)
    }
}
