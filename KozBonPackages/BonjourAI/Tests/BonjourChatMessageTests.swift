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
        // The chat-persistence path (`persistChatHistory` preference)
        // serializes the whole `[BonjourChatMessage]` array as a
        // single Data blob. This pins that the array-level encoding
        // also round-trips byte-for-byte.
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
        // Pin the wire format too — this is the contract the
        // persistence layer relies on, so a future renaming of the
        // enum cases mustn't silently change what's on disk.
        #expect(String(data: data, encoding: .utf8) == "\"user\"")
    }

    // MARK: - Persistence Trimming

    @Test("`trimmed` returns the input unchanged when both caps are well above the input size")
    func trimmingNoOpWhenWellUnderCaps() {
        let messages = (0..<10).map { BonjourChatMessage(role: .user, content: "msg \($0)") }
        let trimmed = BonjourChatMessage.trimmed(
            messages: messages,
            maxCount: 100,
            maxBytes: 1_048_576
        )
        #expect(trimmed == messages)
    }

    @Test("`trimmed` keeps the most recent N messages when the count cap is exceeded")
    func trimmingByCountKeepsTail() {
        // The conversation is chronological (oldest first), so the
        // suffix is what the user is most likely to look back at on
        // the next launch — that's what we keep.
        let messages = (0..<50).map { BonjourChatMessage(role: .user, content: "msg \($0)") }
        let trimmed = BonjourChatMessage.trimmed(
            messages: messages,
            maxCount: 10,
            maxBytes: 1_048_576
        )
        #expect(trimmed.count == 10)
        #expect(trimmed.first?.content == "msg 40")
        #expect(trimmed.last?.content == "msg 49")
    }

    @Test("`trimmed` drops oldest messages until the encoded size fits under the byte cap")
    func trimmingByBytesDropsHead() throws {
        // Each message has ~1 KB of content, so 20 messages encodes
        // to noticeably more than a 5 KB cap. The trim must therefore
        // shed messages from the front (oldest first) until it fits.
        let oneKBString = String(repeating: "x", count: 1_024)
        let messages = (0..<20).map { BonjourChatMessage(role: .assistant, content: "\($0):\(oneKBString)") }

        let cap = 5_000
        let trimmed = BonjourChatMessage.trimmed(
            messages: messages,
            maxCount: 1_000,
            maxBytes: cap
        )

        let encoded = try JSONEncoder().encode(trimmed)
        #expect(encoded.count <= cap)
        #expect(trimmed.count < messages.count)
        // The newest message must still be present — we dropped from
        // the head, not the tail.
        #expect(trimmed.last == messages.last)
    }

    @Test("`trimmed` returns the empty array when `maxCount` is zero or negative")
    func trimmingZeroCountReturnsEmpty() {
        let messages = [BonjourChatMessage(role: .user, content: "anything")]
        #expect(BonjourChatMessage.trimmed(messages: messages, maxCount: 0, maxBytes: 1_000).isEmpty)
        #expect(BonjourChatMessage.trimmed(messages: messages, maxCount: -1, maxBytes: 1_000).isEmpty)
    }

    @Test("`trimmed` returns the empty array when `maxBytes` is zero or negative")
    func trimmingZeroBytesReturnsEmpty() {
        let messages = [BonjourChatMessage(role: .user, content: "anything")]
        #expect(BonjourChatMessage.trimmed(messages: messages, maxCount: 100, maxBytes: 0).isEmpty)
        #expect(BonjourChatMessage.trimmed(messages: messages, maxCount: 100, maxBytes: -1).isEmpty)
    }

    @Test("`trimmed` keeps a single oversize message rather than emptying the conversation")
    func trimmingSingleOversizeMessageIsKept() {
        // Edge case: one message alone is bigger than the byte cap.
        // The contract is that we always leave at least one message
        // — emptying everything would be a worse user experience
        // than a slightly oversize blob (and the in-memory session
        // is not affected anyway).
        let huge = BonjourChatMessage(role: .assistant, content: String(repeating: "y", count: 10_000))
        let trimmed = BonjourChatMessage.trimmed(
            messages: [huge],
            maxCount: 100,
            maxBytes: 100
        )
        #expect(trimmed == [huge])
    }
}
