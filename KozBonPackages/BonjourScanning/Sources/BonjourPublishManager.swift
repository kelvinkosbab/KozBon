//
//  BonjourPublishManager.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourCore
import BonjourModels

@MainActor
public protocol BonjourPublishManagerDelegate: AnyObject, Sendable {
    func publishedServicesUpdated(_ publishedServices: [BonjourService])
}

@MainActor
public final class BonjourPublishManager {

    // MARK: - Singleton

    public static let shared = BonjourPublishManager()

    private init() {}

    // MARK: - Published Services

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

    public func publish(service: BonjourService) async throws -> BonjourService {
        try await service.publishService()
        self.add(publishedService: service)
        return service
    }

    // MARK: - Un-Publishing

    public func unPublish(service: BonjourService) async {
        await service.unPublish()
        self.remove(publishedService: service)
    }

    public func unPublishAllServices() async {
        for service in publishedServices {
            await service.unPublish()
        }
        publishedServices.removeAll()
    }
}
