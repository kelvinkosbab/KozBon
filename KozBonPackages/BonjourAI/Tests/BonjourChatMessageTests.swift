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

    @Test func userMessageStoresRole() {
        let message = BonjourChatMessage(role: .user, content: "Hello")
        #expect(message.role == .user)
    }

    @Test func assistantMessageStoresRole() {
        let message = BonjourChatMessage(role: .assistant, content: "Hi there")
        #expect(message.role == .assistant)
    }

    @Test func messageStoresContent() {
        let message = BonjourChatMessage(role: .user, content: "test content")
        #expect(message.content == "test content")
    }

    @Test func messageGeneratesUniqueIdsByDefault() {
        let message1 = BonjourChatMessage(role: .user, content: "A")
        let message2 = BonjourChatMessage(role: .user, content: "B")
        #expect(message1.id != message2.id)
    }

    @Test func messageUsesProvidedId() {
        let id = UUID()
        let message = BonjourChatMessage(id: id, role: .user, content: "test")
        #expect(message.id == id)
    }

    @Test func messageUsesProvidedTimestamp() {
        let date = Date(timeIntervalSince1970: 1_000_000)
        let message = BonjourChatMessage(role: .user, content: "test", timestamp: date)
        #expect(message.timestamp == date)
    }

    // MARK: - Mutability

    @Test func contentIsMutable() {
        var message = BonjourChatMessage(role: .assistant, content: "initial")
        message.content = "updated"
        #expect(message.content == "updated")
    }

    @Test func contentCanAppend() {
        var message = BonjourChatMessage(role: .assistant, content: "Hello")
        message.content += " world"
        #expect(message.content == "Hello world")
    }

    // MARK: - Equality

    @Test func messagesWithSameIdAndContentAreEqual() {
        let id = UUID()
        let date = Date()
        let message1 = BonjourChatMessage(id: id, role: .user, content: "A", timestamp: date)
        let message2 = BonjourChatMessage(id: id, role: .user, content: "A", timestamp: date)
        #expect(message1 == message2)
    }

    @Test func messagesWithDifferentIdsAreNotEqual() {
        let message1 = BonjourChatMessage(role: .user, content: "A")
        let message2 = BonjourChatMessage(role: .user, content: "A")
        #expect(message1 != message2)
    }

    // MARK: - Role Raw Values

    @Test func userRoleRawValueIsUser() {
        #expect(BonjourChatMessage.Role.user.rawValue == "user")
    }

    @Test func assistantRoleRawValueIsAssistant() {
        #expect(BonjourChatMessage.Role.assistant.rawValue == "assistant")
    }
}
