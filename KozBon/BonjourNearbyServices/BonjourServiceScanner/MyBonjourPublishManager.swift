//
//  MyBonjourPublishManager.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

@MainActor
protocol MyBonjourPublishManagerDelegate: AnyObject, Sendable {
    func publishedServicesUpdated(_ publishedServices: [BonjourService])
}

@MainActor
final class MyBonjourPublishManager {

    // MARK: - Singleton

    static let shared = MyBonjourPublishManager()

    private init() {}

    // MARK: - Published Services

    private(set) var publishedServices: Set<BonjourService> = Set()

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

    func publish(
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

    func publish(service: BonjourService) async throws -> BonjourService {
        try await service.publishService()
        self.add(publishedService: service)
        return service
    }

    // MARK: - Un-Publishing

    func unPublish(service: BonjourService) async {
        await service.unPublish()
        self.remove(publishedService: service)
    }

    func unPublishAllServices() async {
        for service in publishedServices {
            await service.unPublish()
        }
        publishedServices.removeAll()
    }
}
