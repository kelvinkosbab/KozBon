//
//  BonjourChatMessage.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - BonjourChatMessage

/// A single message in a Bonjour chat conversation.
///
/// Can represent either a user message or a streaming assistant response.
/// Content is mutable so assistant messages can be updated as tokens stream in.
///
/// Conforms to `Codable` because mocks/tests round-trip messages through
/// JSON to verify shape stability — the production app keeps chat purely
/// in-memory and relies on the app process lifecycle to clear it.
public struct BonjourChatMessage: Identifiable, Sendable, Hashable, Codable {

    /// Whether the message is from the user or the assistant.
    public enum Role: String, Sendable, Codable {
        case user
        case assistant
    }

    /// A stable identifier for this message.
    public let id: UUID

    /// The author of the message.
    public let role: Role

    /// The message text. Mutable so streaming responses can append content.
    public var content: String

    /// When the message was created.
    public let timestamp: Date

    public init(
        id: UUID = UUID(),
        role: Role,
        content: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}
