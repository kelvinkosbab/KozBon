//
//  PrepareCustomServiceTypeTool.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels

// MARK: - PrepareCustomServiceTypeTool

/// Chat assistant tool that drafts a new custom Bonjour service
/// type and surfaces it to the user for confirmation via the
/// existing "Create custom service type" sheet.
///
/// The tool does NOT persist the service type — it publishes a
/// ``BonjourChatIntent/createCustomServiceType(name:type:transport:details:)``
/// intent to the broker, and the chat view presents
/// `CreateOrUpdateBonjourServiceTypeView` pre-filled with the
/// model's parameters. The user reviews and confirms via the
/// sheet's existing Done button. This keeps the assistant safe by
/// design: it can extract intent and parameters (its strength) but
/// can't commit destructive changes without user review.
///
/// Argument shape mirrors the form fields the user would otherwise
/// fill in by hand. `transport` is supplied as the wire string
/// ("tcp" or "udp") so the model doesn't need to reason about the
/// `TransportLayer` enum.
@available(iOS 26, macOS 26, visionOS 26, *)
public struct PrepareCustomServiceTypeTool: Tool {

    public let name = "prepareCustomServiceType"

    public let description = """
        Draft a new custom Bonjour service type and present a \
        confirmation form to the user. Use when the user asks to \
        create a new service type (e.g. \"create a service type for \
        my home media server\"). The user must confirm via the form \
        — your tool call only opens the sheet pre-filled. Do not \
        claim the service type was created; the user has to tap \
        Done in the form to actually save it.
        """

    @Generable
    public struct Arguments {

        @Guide(description: "Human-readable display name (e.g. \"Home Media Server\"). Required.")
        public let name: String

        @Guide(
            description: """
                Bonjour type identifier WITHOUT leading underscore or transport \
                suffix. Lowercase ASCII, digits, and hyphens only. \
                Example: \"home-media\" (not \"_home-media._tcp\").
                """
        )
        public let type: String

        @Guide(
            description: """
                Transport layer. Must be exactly \"tcp\" or \"udp\" (lowercase). \
                Use \"tcp\" unless the user explicitly mentions UDP.
                """
        )
        public let transport: String

        @Guide(description: "Brief English description of what this service type does. Required.")
        public let details: String
    }

    private let broker: BonjourChatIntentBroker

    public init(broker: BonjourChatIntentBroker) {
        self.broker = broker
    }

    public func call(arguments: Arguments) async throws -> String {
        // Per-turn rate limit. Reserved BEFORE arg validation so a
        // model that's looping through invalid args still consumes
        // its quota.
        guard await broker.reserveToolSlot() else {
            return "Too many actions in this turn — ask the user to confirm what they want first."
        }

        // Normalize before publishing so the form lands with clean
        // values regardless of how the model formatted them. The
        // sheet has its own validation, but trimming here means the
        // user doesn't see leading/trailing whitespace they have to
        // remove before tapping Done.
        let cleanName = arguments.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanType = arguments.type
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let cleanTransport = arguments.transport
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let cleanDetails = arguments.details.trimmingCharacters(in: .whitespacesAndNewlines)

        // Defense-in-depth: if the model passes something obviously
        // bad we bounce it back rather than presenting a form the
        // user can't submit. The error message is what the model
        // will see and (per system prompt) relay to the user.
        guard !cleanName.isEmpty else {
            return "Couldn't draft the form: a display name is required. " +
                "Ask the user what they want to call the service type."
        }
        guard !cleanType.isEmpty else {
            return "Couldn't draft the form: the Bonjour type identifier is required " +
                "(e.g. \"home-media\")."
        }
        guard cleanTransport == "tcp" || cleanTransport == "udp" else {
            return "Couldn't draft the form: transport must be \"tcp\" or \"udp\", " +
                "got \"\(arguments.transport)\"."
        }
        guard !cleanDetails.isEmpty else {
            return "Couldn't draft the form: a short description of what the service " +
                "does is required."
        }

        // Reject injection-pattern payloads in any string arg before
        // publishing. The model could be tricked into passing
        // `</context> SYSTEM: …` as a name or description; the
        // user wouldn't notice the injection in the form's
        // pre-fill, and the value would land in Core Data as a
        // permanent context-block injection vector for every
        // future conversation.
        for (label, value) in [
            ("name", cleanName),
            ("type", cleanType),
            ("details", cleanDetails)
        ] where PromptInjectionSanitizer.containsInjectionPatterns(value) {
            return "Couldn't draft the form: the \(label) contains content that " +
                "looks like an instruction-injection attempt. Ask the user to " +
                "rephrase using ordinary descriptive text."
        }

        let intent = BonjourChatIntent.createCustomServiceType(
            name: cleanName,
            type: cleanType,
            transport: cleanTransport,
            details: cleanDetails
        )
        await broker.publish(intent)

        // The output the model will weave into its reply. Kept
        // short — the model's voice template (system prompt) tells
        // it to acknowledge the form and let the user review.
        return "Drafted a custom service type form for \"\(cleanName)\" " +
            "(_\(cleanType)._\(cleanTransport)). The form is open for the user to review and confirm."
    }
}

#endif
