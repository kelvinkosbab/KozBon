//
//  GitHubMessageRequestTests.swift
//  BonjourAIGitHub
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourAIGitHub

// MARK: - GitHubMessageRequestTests

@Suite("GitHubMessageRequest")
struct GitHubMessageRequestTests {

    // MARK: - Helpers

    private func encodedDictionary(_ request: GitHubMessageRequest) throws -> [String: Any] {
        let data = try JSONEncoder().encode(request)
        let any = try JSONSerialization.jsonObject(with: data)
        guard let dictionary = any as? [String: Any] else {
            Issue.record("Encoded payload was not a dictionary")
            return [:]
        }
        return dictionary
    }

    // MARK: - Encoding Shape

    @Test("Top-level keys match GitHub Models' OpenAI-compatible API")
    func encodesSnakeCaseTopLevelKeys() throws {
        let request = GitHubMessageRequest(
            model: "gpt-4o",
            messages: [
                GitHubMessage(role: .system, content: "system prompt"),
                GitHubMessage(role: .user, content: "Hello")
            ],
            stream: true,
            maxTokens: 1024
        )

        let json = try encodedDictionary(request)

        #expect(json["model"] as? String == "gpt-4o")
        #expect(json["max_tokens"] as? Int == 1024)
        #expect(json["stream"] as? Bool == true)
        #expect(json["messages"] is [Any])
    }

    @Test("System prompt rides as a leading `role: system` message, not a top-level field")
    func systemPromptIsLeadingMessage() throws {
        // OpenAI-style: system messages are first-class, unlike
        // Anthropic where the system block is a separate
        // top-level field. The chat session relies on this — it
        // prepends `[systemMessage] + conversationHistory` per
        // request.
        let request = GitHubMessageRequest(
            model: "gpt-4o",
            messages: [
                GitHubMessage(role: .system, content: "You are a helpful assistant."),
                GitHubMessage(role: .user, content: "Hi")
            ],
            maxTokens: 128
        )

        let json = try encodedDictionary(request)
        let messages = try #require(json["messages"] as? [[String: Any]])

        #expect(json["system"] == nil, "GitHub Models takes `system` as a role, not a top-level field")
        #expect(messages.count == 2)
        #expect(messages[0]["role"] as? String == "system")
        #expect(messages[0]["content"] as? String == "You are a helpful assistant.")
        #expect(messages[1]["role"] as? String == "user")
    }

    @Test("Messages encode with role + content fields")
    func messagesEncodeRoleAndContent() throws {
        let request = GitHubMessageRequest(
            model: "gpt-4o",
            messages: [
                GitHubMessage(role: .system, content: "S"),
                GitHubMessage(role: .user, content: "u1"),
                GitHubMessage(role: .assistant, content: "a1"),
                GitHubMessage(role: .user, content: "u2")
            ],
            maxTokens: 128
        )

        let json = try encodedDictionary(request)
        let messages = try #require(json["messages"] as? [[String: Any]])

        #expect(messages.count == 4)
        #expect(messages[0]["role"] as? String == "system")
        #expect(messages[1]["role"] as? String == "user")
        #expect(messages[1]["content"] as? String == "u1")
        #expect(messages[2]["role"] as? String == "assistant")
        #expect(messages[3]["role"] as? String == "user")
    }

    @Test("Temperature is omitted from the payload when nil")
    func temperatureOmittedWhenNil() throws {
        let request = GitHubMessageRequest(
            model: "gpt-4o",
            messages: [GitHubMessage(role: .user, content: "Hi")],
            maxTokens: 128
        )

        let json = try encodedDictionary(request)
        #expect(json["temperature"] == nil)
    }

    @Test("Temperature is included when set")
    func temperatureIncludedWhenSet() throws {
        let request = GitHubMessageRequest(
            model: "gpt-4o",
            messages: [GitHubMessage(role: .user, content: "Hi")],
            maxTokens: 128,
            temperature: 0.3
        )

        let json = try encodedDictionary(request)
        let temperature = try #require(json["temperature"] as? Double)
        #expect(abs(temperature - 0.3) < 0.001)
    }
}
