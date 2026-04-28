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
}
