//
//  PrepareStopBroadcastTool.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourModels

#if canImport(FoundationModels)
import FoundationModels

// MARK: - PrepareStopBroadcastTool

/// Chat assistant tool that drafts a destructive confirmation
/// dialog asking the user to confirm stopping one of their
/// currently-active service broadcasts.
///
/// The tool consults a live closure for the published-services
/// list so the membership check sees fresh state — a service the
/// user broadcast mid-conversation (via the `prepareBroadcast`
/// tool's confirmation path) can be stopped in the same
/// conversation without forcing a session recreation.
///
/// As with the other destructive tool, this only opens a
/// confirmation; the actual `unPublish(service:)` call runs from
/// the dialog's destructive button.
@available(iOS 26, macOS 26, visionOS 26, *)
public struct PrepareStopBroadcastTool: Tool {

    public let name = "prepareStopBroadcast"

    public let description = """
        Surface a destructive confirmation dialog asking the user to \
        stop one of their currently-active service broadcasts. Use \
        when the user explicitly asks to stop, end, or unpublish a \
        broadcast they started from this device. The user must tap \
        the dialog's destructive button to actually stop the \
        broadcast; your tool call only opens the confirmation. \
        After the tool returns, briefly tell the user the \
        confirmation is open.
        """

    @Generable
    public struct Arguments {

        @Guide(
            description: """
                Full DNS-SD service type of the broadcast to stop, in the \
                form _name._transport. Must match the type of a service the \
                user is currently broadcasting from this device — published \
                services from other devices on the network can't be stopped \
                from here.
                """
        )
        public let serviceType: String
    }

    private let broker: BonjourChatIntentBroker
    private let publishedServicesProvider: @MainActor () -> [BonjourService]

    public init(
        broker: BonjourChatIntentBroker,
        publishedServicesProvider: @escaping @MainActor () -> [BonjourService]
    ) {
        self.broker = broker
        self.publishedServicesProvider = publishedServicesProvider
    }

    public func call(arguments: Arguments) async throws -> String {
        let cleanFullType = arguments.serviceType
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanFullType.isEmpty else {
            return "Couldn't draft the stop: the service type is required."
        }

        // Everything that touches the (`@MainActor`, non-`Sendable`)
        // `BonjourService` must stay on the main actor. We resolve
        // the service AND extract the strings we need into a
        // `Sendable` `Outcome` value before crossing the actor
        // boundary back to the tool's calling context.
        let outcome: Outcome = await MainActor.run {
            let published = publishedServicesProvider()
            if let target = published.first(where: { $0.serviceType.fullType == cleanFullType }) {
                return .matched(displayName: target.service.name)
            }
            // Distinguish "no broadcasts at all" from "that specific
            // type isn't broadcasting" so the model can give a more
            // helpful reply.
            if published.isEmpty {
                return .noActiveBroadcasts
            }
            return .typeNotActive(activeTypes: published.map(\.serviceType.fullType))
        }

        switch outcome {
        case .noActiveBroadcasts:
            return "Couldn't draft the stop: there are no active broadcasts " +
                "from this device right now. Tell the user nothing is " +
                "currently being broadcast."
        case let .typeNotActive(activeTypes):
            return "Couldn't draft the stop: \"\(cleanFullType)\" isn't currently " +
                "being broadcast from this device. The active broadcast types " +
                "are: " + activeTypes.joined(separator: ", ")
        case let .matched(displayName):
            let intent = BonjourChatIntent.stopBroadcast(
                serviceTypeFullType: cleanFullType
            )
            await broker.publish(intent)
            return "Opened a confirmation dialog asking the user whether to stop " +
                "broadcasting \"\(displayName)\" (\(cleanFullType)). " +
                "They have to tap the destructive button to confirm — until then " +
                "the broadcast keeps running."
        }
    }

    /// `Sendable` projection of the main-actor lookup result. Holding
    /// only `String` (and arrays of `String`) means the value can
    /// cross back out of `MainActor.run` cleanly under Swift 6
    /// strict concurrency.
    private enum Outcome: Sendable {
        case matched(displayName: String)
        case noActiveBroadcasts
        case typeNotActive(activeTypes: [String])
    }
}

#endif
