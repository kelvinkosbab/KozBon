//
//  BonjourChatMessageTests.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourAI

// MARK: - BonjourChatMessageTests

@Suite("BonjourChatMessage")
struct BonjourChatMessageTests {

    // MARK: - Init

    @Test("Init with `.user` role preserves the role on the message")
    func userMessageStoresRole() {
        let message = BonjourChatMessage(role: .user, content: "Hello")
        #expect(message.role == .user)
    }

    @Test("Init with `.assistant` role preserves the role on the message")
    func assistantMessageStoresRole() {
        let message = BonjourChatMessage(role: .assistant, content: "Hi there")
        #expect(message.role == .assistant)
    }

    @Test("Init preserves the content string verbatim")
    func messageStoresContent() {
        let message = BonjourChatMessage(role: .user, content: "test content")
        #expect(message.content == "test content")
    }

    @Test("Default init mints a fresh UUID per message so list diffing stays stable")
    func messageGeneratesUniqueIdsByDefault() {
        let message1 = BonjourChatMessage(role: .user, content: "A")
        let message2 = BonjourChatMessage(role: .user, content: "B")
        #expect(message1.id != message2.id)
    }

    @Test("Caller-supplied id wins over the default UUID generator")
    func messageUsesProvidedId() {
        let id = UUID()
        let message = BonjourChatMessage(id: id, role: .user, content: "test")
        #expect(message.id == id)
    }

    @Test("Caller-supplied timestamp wins over the default `Date()` snapshot")
    func messageUsesProvidedTimestamp() {
        let date = Date(timeIntervalSince1970: 1_000_000)
        let message = BonjourChatMessage(role: .user, content: "test", timestamp: date)
        #expect(message.timestamp == date)
    }

    // MARK: - Mutability

    @Test("`content` is var so streaming responses can mutate the same message")
    func contentIsMutable() {
        var message = BonjourChatMessage(role: .assistant, content: "initial")
        message.content = "updated"
        #expect(message.content == "updated")
    }

    @Test("`+=` append works for streaming token-by-token assistant replies")
    func contentCanAppend() {
        var message = BonjourChatMessage(role: .assistant, content: "Hello")
        message.content += " world"
        #expect(message.content == "Hello world")
    }

    // MARK: - Equality

    @Test("Two messages with identical id, role, content, and timestamp compare equal")
    func messagesWithSameIdAndContentAreEqual() {
        let id = UUID()
        let date = Date()
        let message1 = BonjourChatMessage(id: id, role: .user, content: "A", timestamp: date)
        let message2 = BonjourChatMessage(id: id, role: .user, content: "A", timestamp: date)
        #expect(message1 == message2)
    }

    @Test("Identity is by id — same content with different ids is not equal")
    func messagesWithDifferentIdsAreNotEqual() {
        let message1 = BonjourChatMessage(role: .user, content: "A")
        let message2 = BonjourChatMessage(role: .user, content: "A")
        #expect(message1 != message2)
    }

    // MARK: - Role Raw Values

    @Test("`Role.user` raw value is the wire-format string `user`")
    func userRoleRawValueIsUser() {
        #expect(BonjourChatMessage.Role.user.rawValue == "user")
    }

    @Test("`Role.assistant` raw value is the wire-format string `assistant`")
    func assistantRoleRawValueIsAssistant() {
        #expect(BonjourChatMessage.Role.assistant.rawValue == "assistant")
    }

    // MARK: - Codable

    @Test("Single message round-trips through JSON encode/decode")
    func singleMessageJsonRoundTrip() throws {
        let original = BonjourChatMessage(
            id: UUID(),
            role: .assistant,
            content: "AirPlay streams audio and video to compatible receivers.",
            timestamp: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(BonjourChatMessage.self, from: data)
        #expect(decoded == original)
    }

    @Test("Multi-message conversation round-trips through JSON encode/decode")
    func conversationJsonRoundTrip() throws {
        // `BonjourChatMessage` keeps `Codable` conformance for tests
        // and mocks that round-trip messages through JSON to verify
        // shape stability — pin that the array-level encoding also
        // round-trips byte-for-byte so a future Codable change
        // doesn't silently break the contract.
        let conversation: [BonjourChatMessage] = [
            BonjourChatMessage(role: .user, content: "What's _airplay._tcp?"),
            BonjourChatMessage(role: .assistant, content: "AirPlay over TCP — the receiver advertises…"),
            BonjourChatMessage(role: .user, content: "Why isn't it on my Apple TV?"),
            BonjourChatMessage(role: .assistant, content: "Likely the TV is asleep — Bonjour…")
        ]
        let data = try JSONEncoder().encode(conversation)
        let decoded = try JSONDecoder().decode([BonjourChatMessage].self, from: data)
        #expect(decoded == conversation)
    }

    @Test("`Role.user` round-trips as the JSON string `\"user\"`")
    func roleUserJsonValueIsString() throws {
        let data = try JSONEncoder().encode(BonjourChatMessage.Role.user)
        let decoded = try JSONDecoder().decode(BonjourChatMessage.Role.self, from: data)
        #expect(decoded == .user)
        // Pin the wire format too — `Role` is part of the public
        // Codable surface, so a future renaming of the enum cases
        // mustn't silently change what's encoded.
        #expect(String(data: data, encoding: .utf8) == "\"user\"")
    }
}
