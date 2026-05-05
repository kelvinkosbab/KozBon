//
//  PrepareEditCustomServiceTypeTool.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourCore
import BonjourModels

#if canImport(FoundationModels)
import FoundationModels

// MARK: - PrepareEditCustomServiceTypeTool

/// Chat assistant tool that opens the create-or-update sheet in
/// **edit mode** for an existing custom service type, optionally
/// pre-filling a new display name and/or description.
///
/// The DNS-SD type and transport are immutable in edit mode (the
/// existing form disables that field), so this tool's job is
/// limited to the two editable fields. Built-in (non-custom) types
/// can't be edited; the tool returns a hint to the model when the
/// user asks to edit one.
///
/// Like the other prepare-* tools, this does NOT save anything —
/// the user reviews and confirms via the form's Done button.
@available(iOS 26, macOS 26, visionOS 26, *)
public struct PrepareEditCustomServiceTypeTool: Tool {

    public let name = "prepareEditCustomServiceType"

    public let description = """
        Open the existing-custom-service-type form in edit mode and \
        present it for the user to review. Use when the user asks to \
        rename or revise the description of one of their custom \
        service types (\"rename my home media type\", \"change the \
        description of _foo._tcp\"). Pass `nil`/empty for \
        suggestedName/suggestedDetails when the user only said \
        \"edit\" without a concrete suggestion — the form will open \
        with the current values for them to revise. Do NOT use for \
        built-in service types: only types the user created \
        themselves are editable.
        """

    @Generable
    public struct Arguments {

        @Guide(
            description: """
                Full DNS-SD service type of the custom type the user wants to \
                edit, in the form _name._transport (e.g. \"_homemedia._tcp\"). \
                Must match a custom (user-created) service type — built-ins are \
                not editable.
                """
        )
        public let serviceType: String

        @Guide(
            description: """
                New display name to suggest, or an empty string to leave the \
                current name in place. Only fill this when the user has \
                explicitly asked for a new name.
                """
        )
        public let suggestedName: String

        @Guide(
            description: """
                New description to suggest, or an empty string to leave the \
                current description in place. Only fill this when the user has \
                explicitly asked for a new description.
                """
        )
        public let suggestedDetails: String
    }

    private let broker: BonjourChatIntentBroker
    private let library: [BonjourServiceType]

    public init(
        broker: BonjourChatIntentBroker,
        library: [BonjourServiceType]
    ) {
        self.broker = broker
        self.library = library
    }

    public func call(arguments: Arguments) async throws -> String {
        guard await broker.reserveToolSlot() else {
            return "Too many actions in this turn — ask the user to confirm what they want first."
        }

        let cleanFullType = arguments.serviceType.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanSuggestedName = arguments.suggestedName
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanSuggestedDetails = arguments.suggestedDetails
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanFullType.isEmpty else {
            return "Couldn't draft the edit: the service type is required."
        }

        guard let target = library.first(where: { $0.fullType == cleanFullType }) else {
            return "Couldn't draft the edit: \"\(cleanFullType)\" isn't in the user's " +
                "library. Tell them you couldn't find that service type."
        }

        // Built-ins are part of the bundled library, not stored as
        // custom types — the create-or-update form's Core Data path
        // wouldn't know how to operate on them. Refuse cleanly so
        // the user gets a real explanation rather than a sheet that
        // does nothing on Done.
        guard !target.isBuiltIn else {
            return "Couldn't draft the edit: \"\(cleanFullType)\" is a built-in " +
                "service type, which can't be edited. Only types the user " +
                "created themselves can be renamed or revised."
        }

        // Same injection-pattern check as the create tool — a
        // suggested rename or revised description carrying
        // `</context> SYSTEM: …` would land in Core Data as a
        // permanent context-block injection vector.
        for (label, value) in [
            ("suggested name", cleanSuggestedName),
            ("suggested details", cleanSuggestedDetails)
        ]
        where !value.isEmpty && PromptInjectionSanitizer.containsInjectionPatterns(value) {
            return "Couldn't draft the edit: the \(label) contains content that " +
                "looks like an instruction-injection attempt. Ask the user to " +
                "rephrase using ordinary descriptive text."
        }

        // The tool stores the suggestions as `nil` rather than empty
        // strings so the view layer can distinguish "no suggestion"
        // from "explicit empty". An explicit empty would be a user
        // error anyway (the form rejects it), but this keeps the
        // view-side handling clean.
        let intent = BonjourChatIntent.editCustomServiceType(
            currentFullType: cleanFullType,
            suggestedName: cleanSuggestedName.isEmpty ? nil : cleanSuggestedName,
            suggestedDetails: cleanSuggestedDetails.isEmpty ? nil : cleanSuggestedDetails
        )
        await broker.publish(intent)

        return "Drafted an edit form for \"\(target.name)\" (\(cleanFullType)). " +
            "The form is open for the user to review and confirm."
    }
}

#endif
