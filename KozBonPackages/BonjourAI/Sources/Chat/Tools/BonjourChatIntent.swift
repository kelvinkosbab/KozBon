//
//  BonjourChatIntent.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourCore

// MARK: - BonjourChatIntent

/// A side-effecting action the chat assistant has asked the app to
/// surface for user confirmation. Intents are produced by tool calls
/// during a chat turn and consumed by the chat view, which presents
/// the matching pre-filled form.
///
/// The assistant never performs the action directly — the tool call
/// only drafts a form. The user reviews and confirms via the same
/// presentation flow they'd use from the Discover or Library tab,
/// so every existing validation, error path, and accessibility
/// affordance applies.
public enum BonjourChatIntent: Sendable, Equatable {

    /// Open the "Create custom service type" sheet pre-filled.
    ///
    /// `transport` is supplied as the wire string ("tcp" or "udp")
    /// so the model's tool argument doesn't need to know the
    /// `TransportLayer` enum. The view layer maps it back to the
    /// enum on the way into the sheet.
    case createCustomServiceType(
        name: String,
        type: String,
        transport: String,
        details: String
    )

    /// Open the "Broadcast a service" sheet pre-filled.
    ///
    /// `serviceTypeFullType` matches the canonical `_type._transport`
    /// form used everywhere else in the app. If the form is opened
    /// for a type that already exists in the library, the sheet's
    /// service-type row resolves it; otherwise the model is
    /// instructed to draft a custom service type first.
    case broadcastService(
        serviceTypeFullType: String,
        port: Int?,
        domain: String,
        txtRecords: [TxtRecordDraft]
    )

    /// Open the create-or-update sheet in **edit mode** for an
    /// existing custom service type, optionally with model-suggested
    /// new values pre-filled. The DNS-SD type and transport are
    /// immutable in edit mode (the form disables that field), so
    /// only the display name and the description can be revised
    /// from chat.
    ///
    /// The suggested fields are nullable: if the model only knows
    /// which type to edit but doesn't have a concrete suggestion,
    /// it can pass `nil`/empty and the form will simply open with
    /// the existing values, ready for the user to revise.
    case editCustomServiceType(
        currentFullType: String,
        suggestedName: String?,
        suggestedDetails: String?
    )

    /// Surface a destructive confirmation dialog asking the user to
    /// confirm deletion of one of their custom service types.
    /// Acted on (against Core Data) only when the user taps the
    /// destructive button in the dialog — the chat view never
    /// auto-confirms.
    case deleteCustomServiceType(serviceTypeFullType: String)

    /// Surface a destructive confirmation dialog asking the user to
    /// confirm that they want to stop one of their currently-active
    /// service broadcasts. The actual `unPublish(service:)` call is
    /// deferred to the dialog's destructive button — confirming
    /// from inside chat would bypass the user-confirms-destructive-
    /// actions guarantee.
    case stopBroadcast(serviceTypeFullType: String)
}

// MARK: - TxtRecordDraft

/// A user-supplied or model-suggested TXT record for a broadcast
/// intent. Kept separate from `BonjourService.TxtDataRecord` (which
/// is `@MainActor` and lives in `BonjourModels`) so intents can be
/// constructed and tested without touching the runtime model layer.
public struct TxtRecordDraft: Sendable, Equatable, Hashable, Codable {
    public let key: String
    public let value: String

    public init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}
