//
//  BonjourPublishManagerProtocol.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - BonjourPublishManagerProtocol

/// Protocol defining the interface for publishing Bonjour services on the local network.
///
/// Conforming types manage the lifecycle of published services — creating, advertising,
/// and removing them. The protocol uses async/await for all operations.
@MainActor
protocol BonjourPublishManagerProtocol: AnyObject, Sendable {

    /// The set of services currently being published by this manager.
    var publishedServices: Set<BonjourService> { get }

    /// Creates and publishes a new Bonjour service with the given parameters.
    func publish(
        name: String,
        type: String,
        port: Int,
        domain: String,
        transportLayer: TransportLayer,
        detail: String
    ) async throws -> BonjourService

    /// Publishes an existing ``BonjourService`` instance on the network.
    func publish(service: BonjourService) async throws -> BonjourService

    /// Stops publishing the given service and removes it from the published set.
    func unPublish(service: BonjourService) async

    /// Stops publishing all currently active services.
    func unPublishAllServices() async
}

// MARK: - MyBonjourPublishManager + Protocol Conformance

extension MyBonjourPublishManager: BonjourPublishManagerProtocol {}
