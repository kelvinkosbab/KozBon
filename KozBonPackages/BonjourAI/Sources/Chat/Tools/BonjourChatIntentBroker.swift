//
//  BonjourChatIntentBroker.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Observation

// MARK: - BonjourChatIntentBroker

/// Side channel between the chat session's tool calls and the chat
/// view's sheet presentation.
///
/// Tools run inside the model's pipeline and can't directly mutate
/// the chat view's `@State`. Each tool calls ``publish(_:)`` with
/// the intent it just drafted; the chat view watches
/// ``pendingIntent`` via `.onChange` and presents the matching
/// pre-filled sheet. After the sheet dismisses, the view calls
/// ``consume()`` so the same intent doesn't re-fire on every
/// subsequent re-render.
///
/// Holds at most one intent at a time. The tools are designed so
/// the assistant only drafts one form per turn; if a future flow
/// needs to queue multiple, swap this for an array.
@MainActor
@Observable
public final class BonjourChatIntentBroker {

    /// The most recently drafted intent awaiting user review, or
    /// `nil` if no draft is currently outstanding. Setting this
    /// (via ``publish(_:)``) triggers the chat view to present the
    /// matching sheet.
    public private(set) var pendingIntent: BonjourChatIntent?

    /// Maximum number of tool calls allowed per user turn. Reset
    /// to zero by ``resetToolCallCount()`` at the start of each
    /// `BonjourChatSession.send(...)`. Beyond the cap,
    /// ``reserveToolSlot()`` returns `false` so the offending tool
    /// can return a relayable error to the model instead of
    /// publishing an intent.
    ///
    /// Picked to comfortably allow the documented chains
    /// (create→broadcast and stop→delete are two-tool flows split
    /// across two turns; in-turn chaining is uncommon but possible)
    /// while still bounding runaway tool-loops if the model gets
    /// stuck or is prompt-injected.
    public static let maxToolCallsPerTurn = 3

    /// Number of tool calls already granted in the current turn.
    /// Read-only externally so callers can't accidentally bypass
    /// the cap.
    public private(set) var toolCallsThisTurn: Int = 0

    public init() {}

    /// Publish a new intent for the chat view to present. Replaces
    /// any previous unconsumed intent — the user has presumably
    /// dismissed the prior sheet implicitly by asking the model
    /// for something new.
    public func publish(_ intent: BonjourChatIntent) {
        pendingIntent = intent
    }

    /// Clear the pending intent. Called by the chat view once the
    /// sheet for the current intent has been presented (or
    /// dismissed), so the same intent doesn't immediately re-trigger
    /// presentation on the next render.
    public func consume() {
        pendingIntent = nil
    }

    /// Atomically increments the per-turn tool-call counter and
    /// returns whether the call is allowed. Tools must invoke this
    /// before doing any side-effecting work — when it returns
    /// `false`, the tool must return a relayable error to the model
    /// instead of publishing an intent, so the model can tell the
    /// user it didn't act on what was asked.
    ///
    /// The counter is reset by ``resetToolCallCount()`` at the
    /// start of each user turn (see `BonjourChatSession.send(...)`).
    public func reserveToolSlot() -> Bool {
        guard toolCallsThisTurn < Self.maxToolCallsPerTurn else { return false }
        toolCallsThisTurn += 1
        return true
    }

    /// Resets the per-turn tool-call counter. Called by the chat
    /// session at the start of each user turn so the model gets a
    /// fresh quota every time the user submits a message.
    public func resetToolCallCount() {
        toolCallsThisTurn = 0
    }
}
