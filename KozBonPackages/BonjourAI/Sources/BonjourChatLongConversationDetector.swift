//
//  BonjourChatLongConversationDetector.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - Array<BonjourChatMessage> Long-Conversation Detection

/// Heuristic for "the conversation is getting long enough that the
/// on-device model's context budget is being approached".
///
/// Apple's `FoundationModels` framework doesn't expose token
/// counts, remaining context, or rate-limit headroom — see the
/// design discussion in the chat session for the full picture.
/// Without an authoritative signal, we use a simple proxy: if the
/// accumulated transcript crosses **either** a message-count or a
/// total-character threshold, we surface a passive indicator in
/// the chat header.
///
/// Two thresholds are tracked rather than just one because the
/// pathological cases differ: a long back-and-forth of short
/// turns hits the count limit first, while a small number of
/// very long replies (technical explanations, debugging dumps)
/// hits the character limit first. Either signal flags the same
/// underlying concern: the model is getting close to its window.
///
/// The thresholds are intentionally conservative — set so the
/// indicator appears BEFORE failures typically occur, not after.
/// They're tunable from real `exceededContextWindowSize` data
/// captured via the OSLog plumbing in `AskKozBonIntent` and the
/// chat session's error catch.
public extension Array where Element == BonjourChatMessage {

    /// Message count above which a conversation is flagged as
    /// "long". Picked to fire before the on-device model's
    /// context window is plausibly exhausted by transcript
    /// accumulation alone.
    ///
    /// 30 messages = roughly 15 user/assistant turns.
    static var longConversationMessageThreshold: Int { 30 }

    /// Total character count of message content above which a
    /// conversation is flagged as "long". Catches the small-
    /// message-count, large-content case (one or two very long
    /// model replies) that the message-count threshold would
    /// miss.
    ///
    /// 8,000 characters ≈ 1,500-2,000 tokens of transcript.
    /// Combined with our static prompt overhead (~3,000-3,500
    /// tokens of system instructions plus tool schemas), this
    /// approaches the on-device Foundation Model's reported
    /// context window.
    static var longConversationCharacterThreshold: Int { 8_000 }

    /// Returns `true` when the conversation has accumulated
    /// enough transcript that the model's context budget is
    /// being approached, by either threshold.
    var isLongConversation: Bool {
        if count >= Self.longConversationMessageThreshold {
            return true
        }
        let totalCharacters = reduce(0) { $0 + $1.content.count }
        return totalCharacters >= Self.longConversationCharacterThreshold
    }
}
