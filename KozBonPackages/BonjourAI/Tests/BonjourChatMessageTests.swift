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
}
