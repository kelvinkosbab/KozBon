//
//  BonjourPublishManager.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourCore
import BonjourModels

/// Delegate protocol for receiving updates when the set of published Bonjour services changes.
@MainActor
public protocol BonjourPublishManagerDelegate: AnyObject, Sendable {
    /// Called when the list of published services has been updated.
    ///
    /// - Parameter publishedServices: The current array of published services.
    func publishedServicesUpdated(_ publishedServices: [BonjourService])
}

/// Manages publishing (broadcasting) Bonjour services on the local network.
///
/// Use the ``shared`` singleton to publish and unpublish services. Published services
/// are tracked in ``publishedServices`` and automatically resolved upon registration.
@MainActor
public final class BonjourPublishManager {

    // MARK: - Singleton

    /// The shared singleton instance used for publishing Bonjour services.
    public static let shared = BonjourPublishManager()

    private init() {}

    // MARK: - Published Services

    /// The set of services currently published by this manager.
    public private(set) var publishedServices: Set<BonjourService> = Set()

    private func add(publishedService service: BonjourService) {
        if !publishedServices.contains(service) {
            publishedServices.insert(service)
            service.resolve()
        }
    }

    private func remove(publishedService service: BonjourService) {
        publishedServices.remove(service)
    }

    // MARK: - Publishing

    /// Publishes a new Bonjour service on the network with the given parameters.
    ///
    /// - Parameters:
    ///   - name: The human-readable name of the service.
    ///   - type: The Bonjour service type identifier (e.g., `"_http"`).
    ///   - port: The port number the service listens on.
    ///   - domain: The domain to publish in (use `""` for the default domain).
    ///   - transportLayer: The transport protocol (TCP or UDP).
    ///   - detail: A description of the service type.
    /// - Returns: The published ``BonjourService`` instance.
    /// - Throws: An error if the service fails to publish.
    public func publish(
        name: String,
        type: String,
        port: Int,
        domain: String,
        transportLayer: TransportLayer,
        detail: String
    ) async throws -> BonjourService {
        let serviceType = BonjourServiceType(name: name, type: type, transportLayer: transportLayer, detail: detail)
        let netService = NetService(domain: domain, type: serviceType.fullType, name: name, port: Int32(port))
        let service = BonjourService(service: netService, serviceType: serviceType)
        return try await publish(service: service)
    }

    /// Publishes an existing ``BonjourService`` on the network.
    ///
    /// - Parameter service: The service to publish.
    /// - Returns: The published service.
    /// - Throws: An error if the service fails to publish.
    public func publish(service: BonjourService) async throws -> BonjourService {
        try await service.publishService()
        self.add(publishedService: service)
        return service
    }

    // MARK: - Un-Publishing

    /// Stops publishing the given service and removes it from ``publishedServices``.
    ///
    /// - Parameter service: The service to unpublish.
    public func unPublish(service: BonjourService) async {
        await service.unPublish()
        self.remove(publishedService: service)
    }

    /// Stops publishing all currently published services and clears ``publishedServices``.
    public func unPublishAllServices() async {
        for service in publishedServices {
            await service.unPublish()
        }
        publishedServices.removeAll()
    }
}
