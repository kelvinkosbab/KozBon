//
//  PrepareDeleteCustomServiceTypeTool.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourModels

#if canImport(FoundationModels)
import FoundationModels

// MARK: - PrepareDeleteCustomServiceTypeTool

/// Chat assistant tool that drafts a destructive confirmation
/// dialog asking the user to confirm deletion of one of their
/// custom service types.
///
/// The tool itself never deletes anything from Core Data — that
/// only happens after the user explicitly taps the destructive
/// button in the system confirmation dialog the chat view
/// presents. The dialog phrasing matches the established pattern
/// ("Are you sure you want to delete the <name> service type?")
/// so users get a familiar, decisive prompt before destructive
/// action lands.
///
/// Built-in (non-custom) types can't be deleted; the tool returns
/// a hint to the model so it can explain that to the user rather
/// than the user seeing a no-op dialog.
@available(iOS 26, macOS 26, visionOS 26, *)
public struct PrepareDeleteCustomServiceTypeTool: Tool {

    public let name = "prepareDeleteCustomServiceType"

    public let description = """
        Surface a destructive confirmation dialog asking the user to \
        delete one of their custom service types. Use when the user \
        explicitly asks to delete or remove a custom service type \
        they previously created. Do NOT use this tool for built-in \
        service types — those can't be deleted. The user must tap \
        the dialog's destructive button to actually remove the type; \
        your tool call only opens the confirmation. After the tool \
        returns, briefly tell the user the confirmation is open.
        """

    @Generable
    public struct Arguments {

        @Guide(
            description: """
                Full DNS-SD service type of the custom type to delete, in the \
                form _name._transport. Must match a custom (user-created) \
                type in the library — built-ins can't be deleted.
                """
        )
        public let serviceType: String
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
        let cleanFullType = arguments.serviceType
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanFullType.isEmpty else {
            return "Couldn't draft the deletion: the service type is required."
        }

        guard let target = library.first(where: { $0.fullType == cleanFullType }) else {
            return "Couldn't draft the deletion: \"\(cleanFullType)\" isn't in " +
                "the user's library. Tell them you couldn't find that service type."
        }

        guard !target.isBuiltIn else {
            return "Couldn't draft the deletion: \"\(cleanFullType)\" is a " +
                "built-in service type, which can't be deleted. Only types the " +
                "user created themselves can be removed."
        }

        let intent = BonjourChatIntent.deleteCustomServiceType(
            serviceTypeFullType: cleanFullType
        )
        await broker.publish(intent)

        return "Opened a confirmation dialog asking the user whether to delete " +
            "\"\(target.name)\" (\(cleanFullType)). They have to tap the " +
            "destructive button to confirm — until then nothing is removed."
    }
}

#endif
