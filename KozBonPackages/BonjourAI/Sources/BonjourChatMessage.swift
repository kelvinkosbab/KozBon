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
/// Conforms to `Codable` so messages can be serialized for persistence
/// across app launches when the user opts in via the
/// "Persist chat history" preference.
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

    // MARK: - Persistence Trimming

    /// Returns the suffix of `messages` whose JSON-encoded form fits
    /// within both `maxCount` (number of messages) and `maxBytes`
    /// (encoded size in bytes). Used at the persistence boundary so
    /// the saved chat history can't grow unbounded across long
    /// conversations.
    ///
    /// The byte ceiling is enforced after the count cap by
    /// progressively dropping from the head until the encoded size
    /// fits — this keeps the most recent context, which is what the
    /// user is most likely to look back at on the next launch.
    ///
    /// - Parameters:
    ///   - messages: The conversation in chronological order
    ///     (oldest first, newest last).
    ///   - maxCount: Maximum number of messages to keep. Values ≤ 0
    ///     return an empty array.
    ///   - maxBytes: Maximum encoded byte size. Values ≤ 0 return
    ///     an empty array. The encoder is chosen by the caller and
    ///     should match the encoder used when actually saving.
    ///   - encoder: The encoder used to measure the encoded size.
    /// - Returns: The trimmed message array. If a single message
    ///   alone exceeds `maxBytes`, it is returned anyway — there's
    ///   no useful conversation state below that floor.
    public static func trimmed(
        messages: [BonjourChatMessage],
        maxCount: Int,
        maxBytes: Int,
        encoder: JSONEncoder = JSONEncoder()
    ) -> [BonjourChatMessage] {
        guard maxCount > 0, maxBytes > 0 else { return [] }

        var trimmed = messages.suffix(maxCount).map { $0 }

        // Drop oldest until the encoded size fits, leaving at least
        // one message so the user sees something on relaunch even
        // if their last reply was unusually long.
        while trimmed.count > 1,
              let encoded = try? encoder.encode(trimmed),
              encoded.count > maxBytes {
            trimmed.removeFirst()
        }
        return trimmed
    }
}
