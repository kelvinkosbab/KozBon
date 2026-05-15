//
//  AnthropicMessageRequestTests.swift
//  BonjourAIAnthropic
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourAIAnthropic

// MARK: - AnthropicMessageRequestTests

@Suite("AnthropicMessageRequest")
struct AnthropicMessageRequestTests {

    // MARK: - Helpers

    /// Decodes the encoded request body into a generic dictionary
    /// so tests can assert against snake-case keys without
    /// reflecting the Swift property names.
    private func encodedDictionary(_ request: AnthropicMessageRequest) throws -> [String: Any] {
        let data = try JSONEncoder().encode(request)
        let any = try JSONSerialization.jsonObject(with: data)
        guard let dictionary = any as? [String: Any] else {
            Issue.record("Encoded payload was not a dictionary")
            return [:]
        }
        return dictionary
    }

    // MARK: - Encoding Shape

    @Test("Top-level keys are snake-case and match Anthropic's API")
    func encodesSnakeCaseTopLevelKeys() throws {
        let request = AnthropicMessageRequest(
            model: "claude-sonnet-4-5",
            maxTokens: 1024,
            stream: true,
            system: [AnthropicSystemBlock(text: "Test system block")],
            messages: [AnthropicMessage(role: .user, content: "Hello")]
        )

        let json = try encodedDictionary(request)

        #expect(json["model"] as? String == "claude-sonnet-4-5")
        #expect(json["max_tokens"] as? Int == 1024)
        #expect(json["stream"] as? Bool == true)
        // `messages` and `system` are arrays — presence check
        // is enough; nested shape is verified separately below.
        #expect(json["messages"] is [Any])
        #expect(json["system"] is [Any])
    }

    @Test("System block carries the `text` type discriminator")
    func systemBlockHasTextDiscriminator() throws {
        let request = AnthropicMessageRequest(
            model: "m",
            maxTokens: 128,
            system: [AnthropicSystemBlock(text: "System prompt body")],
            messages: [AnthropicMessage(role: .user, content: "Hi")]
        )

        let json = try encodedDictionary(request)
        let system = try #require(json["system"] as? [[String: Any]])
        let firstBlock = try #require(system.first)

        #expect(firstBlock["type"] as? String == "text")
        #expect(firstBlock["text"] as? String == "System prompt body")
    }

    @Test("Cache control marker renders as `cache_control: {type: ephemeral}`")
    func cacheControlRendersSnakeCase() throws {
        let request = AnthropicMessageRequest(
            model: "m",
            maxTokens: 128,
            system: [
                AnthropicSystemBlock(
                    text: "Cached prefix",
                    cacheControl: .ephemeral
                )
            ],
            messages: [AnthropicMessage(role: .user, content: "Hi")]
        )

        let json = try encodedDictionary(request)
        let system = try #require(json["system"] as? [[String: Any]])
        let firstBlock = try #require(system.first)
        let cacheControl = try #require(firstBlock["cache_control"] as? [String: Any])

        #expect(cacheControl["type"] as? String == "ephemeral")
    }

    @Test("Omitted cache control is absent from the encoded payload")
    func omittedCacheControlNotEncoded() throws {
        let request = AnthropicMessageRequest(
            model: "m",
            maxTokens: 128,
            system: [AnthropicSystemBlock(text: "Body")],
            messages: [AnthropicMessage(role: .user, content: "Hi")]
        )

        let json = try encodedDictionary(request)
        let system = try #require(json["system"] as? [[String: Any]])
        let firstBlock = try #require(system.first)

        #expect(firstBlock["cache_control"] == nil)
    }

    @Test("Messages encode with role + content fields")
    func messagesEncodeRoleAndContent() throws {
        let request = AnthropicMessageRequest(
            model: "m",
            maxTokens: 128,
            system: [AnthropicSystemBlock(text: "S")],
            messages: [
                AnthropicMessage(role: .user, content: "u1"),
                AnthropicMessage(role: .assistant, content: "a1"),
                AnthropicMessage(role: .user, content: "u2")
            ]
        )

        let json = try encodedDictionary(request)
        let messages = try #require(json["messages"] as? [[String: Any]])

        #expect(messages.count == 3)
        #expect(messages[0]["role"] as? String == "user")
        #expect(messages[0]["content"] as? String == "u1")
        #expect(messages[1]["role"] as? String == "assistant")
        #expect(messages[2]["role"] as? String == "user")
    }

    @Test("Temperature is omitted from the payload when nil")
    func temperatureOmittedWhenNil() throws {
        let request = AnthropicMessageRequest(
            model: "m",
            maxTokens: 128,
            system: [AnthropicSystemBlock(text: "S")],
            messages: [AnthropicMessage(role: .user, content: "Hi")]
        )

        let json = try encodedDictionary(request)
        #expect(json["temperature"] == nil)
    }

    @Test("Temperature is included when set")
    func temperatureIncludedWhenSet() throws {
        let request = AnthropicMessageRequest(
            model: "m",
            maxTokens: 128,
            system: [AnthropicSystemBlock(text: "S")],
            messages: [AnthropicMessage(role: .user, content: "Hi")],
            temperature: 0.3
        )

        let json = try encodedDictionary(request)
        // JSON decodes 0.3 as Double; compare via Double cast.
        let temperature = try #require(json["temperature"] as? Double)
        #expect(abs(temperature - 0.3) < 0.001)
    }
}
