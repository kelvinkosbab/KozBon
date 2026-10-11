//
//  BroadcastServiceIntent.swift
//  BonjourAppIntents
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import AppIntents
import Foundation
import BonjourCore
import BonjourLocalization
import BonjourModels

// MARK: - BroadcastServiceIntent

/// Starts broadcasting a service type on a port, the same as the
/// Broadcast form in the Discover tab.
///
/// Opens the app: a broadcast stops when KozBon is suspended, and the
/// user can see and stop it in Discover.
public struct BroadcastServiceIntent: AppIntent {

    public static let title: LocalizedStringResource = .init("intent_broadcast_title")

    public static let description = IntentDescription(.init("intent_broadcast_description"))

    public static let openAppWhenRun: Bool = true

    @Parameter(title: .init("intent_parameter_service_type"))
    public var serviceType: BonjourServiceTypeEntity

    @Parameter(title: .init("intent_parameter_port"))
    public var port: Int

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let reply = try await Self.broadcast(fullType: serviceType.id, port: port, bridge: .shared)
        return .result(dialog: IntentDialog(LocalizedStringResource(stringLiteral: reply)))
    }

    // MARK: - Helpers

    /// Publishes the service and returns what Siri says.
    ///
    /// - Throws: ``SiriIntentError`` for a UDP type (the Broadcast form
    ///   is TCP-only too), a port out of range, a missing publish
    ///   manager, or a failed publish.
    @MainActor
    static func broadcast(fullType: String, port: Int, bridge: AppIntentsBridge) async throws -> String {
        guard let serviceType = BonjourServiceType.fetch(fullType: fullType),
              let publishManager = bridge.publishManager else {
            throw SiriIntentError(message: Strings.Siri.openAppAndRetry)
        }
        guard serviceType.transportLayer == .tcp else {
            throw SiriIntentError(message: Strings.Siri.broadcastTCPOnly)
        }
        guard port >= Constants.Network.minimumPort else {
            throw SiriIntentError(message: Strings.Errors.portMin(Constants.Network.minimumPort))
        }
        guard port <= Constants.Network.maximumPort else {
            throw SiriIntentError(message: Strings.Errors.portMax(Constants.Network.maximumPort))
        }

        let service: BonjourService
        do {
            service = try await publishManager.publish(
                name: serviceType.name,
                type: serviceType.type,
                port: port,
                domain: Constants.Network.defaultDomain,
                transportLayer: .tcp,
                detail: serviceType.localizedDetail ?? "N/A"
            )
        } catch {
            throw SiriIntentError(message: Strings.Errors.publishFailed(error.localizedDescription))
        }
        bridge.didPublish?(service)
        return Strings.Siri.broadcastStarted(serviceType.name, port: String(port))
    }
}

// MARK: - StopBroadcastingIntent

/// Stops every broadcast KozBon started, from Siri or the app.
public struct StopBroadcastingIntent: AppIntent {

    public static let title: LocalizedStringResource = .init("intent_stop_broadcast_title")

    public static let description = IntentDescription(.init("intent_stop_broadcast_description"))

    public static let openAppWhenRun: Bool = false

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let reply = await Self.stopAll(bridge: .shared)
        return .result(dialog: IntentDialog(LocalizedStringResource(stringLiteral: reply)))
    }

    @MainActor
    static func stopAll(bridge: AppIntentsBridge) async -> String {
        guard let publishManager = bridge.publishManager, !publishManager.publishedServices.isEmpty else {
            return Strings.Siri.noBroadcasts
        }
        let count = publishManager.publishedServices.count
        await publishManager.unPublishAllServices()
        bridge.didStopAllBroadcasts?()
        return Strings.Siri.stoppedBroadcasts(count)
    }
}
