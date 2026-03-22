//
//  BonjourServiceType.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - BonjourServiceType

struct BonjourServiceType: Hashable, Equatable, Sendable, Codable {

    let name: String
    let type: String
    let transportLayer: TransportLayer
    let detail: String?
    let fullType: String

    init(
        name: String,
        type: String,
        transportLayer: TransportLayer,
        detail: String? = nil
    ) {
        self.name = name
        self.type = type
        self.transportLayer = transportLayer
        self.detail = detail
        self.fullType = BonjourServiceType.generateFullType(
            type: type,
            transportLayer: transportLayer
        )
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.fullType)
    }

    static func == (lhs: BonjourServiceType, rhs: BonjourServiceType) -> Bool {
        return lhs.name == rhs.name && lhs.fullType == rhs.fullType && lhs.detail == rhs.detail
    }

    var isBuiltIn: Bool {
        BonjourServiceType.serviceTypeLibrary.contains(self)
    }

    // MARK: - Static Helpers

    static func generateFullType(
        type: String,
        transportLayer: TransportLayer
    ) -> String {
        return "_\(type)._\(transportLayer.string)"
    }

    @MainActor
    static func fetchAll() -> [BonjourServiceType] {
        var all = self.serviceTypeLibrary
        for persistentServiceType in self.fetchAllPersistentCopies() where
            self.fetch(serviceTypes: all, type: persistentServiceType.type, transportLayer: persistentServiceType.transportLayer) == nil {
            all.append(persistentServiceType)
        }
        return all
    }

    static var serviceTypeLibrary: [BonjourServiceType] {
        return self.tcpServiceTypes + self.udpServiceTypes
    }

    @MainActor
    static func fetch(
        serviceTypes: [BonjourServiceType]? = nil,
        type: String,
        transportLayer: TransportLayer
    ) -> BonjourServiceType? {
        let typesToFilter = serviceTypes ?? self.fetchAll()
        let filtered = typesToFilter.filter { serviceType -> Bool in
            serviceType.type == type && serviceType.transportLayer == transportLayer
        }
        return filtered.first
    }

    @MainActor
    static func fetch(
        serviceTypes: [BonjourServiceType]? = nil,
        fullType: String
    ) -> BonjourServiceType? {
        let typesToFilter = serviceTypes ?? self.fetchAll()
        let filtered = typesToFilter.filter { (serviceType) -> Bool in
            serviceType.fullType == fullType
        }
        return filtered.first
    }

    @MainActor
    static func exists(
        serviceTypes: [BonjourServiceType]? = nil,
        type: String,
        transportLayer: TransportLayer
    ) -> Bool {
        return self.fetch(serviceTypes: serviceTypes, type: type, transportLayer: transportLayer) != nil
    }

    @MainActor
    static func exists(
        serviceTypes: [BonjourServiceType]? = nil,
        fullType: String
    ) -> Bool {
        return self.fetch(serviceTypes: serviceTypes, fullType: fullType) != nil
    }
}
