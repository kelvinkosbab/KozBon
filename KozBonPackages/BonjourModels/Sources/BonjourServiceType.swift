//
//  BonjourServiceType.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourCore

// MARK: - BonjourServiceType

public struct BonjourServiceType: Hashable, Equatable, Sendable, Codable {

    public let name: String
    public let type: String
    public let transportLayer: TransportLayer
    public let detail: String?
    public let fullType: String

    public init(
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

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.fullType)
    }

    public static func == (lhs: BonjourServiceType, rhs: BonjourServiceType) -> Bool {
        return lhs.name == rhs.name && lhs.fullType == rhs.fullType && lhs.detail == rhs.detail
    }

    public var isBuiltIn: Bool {
        BonjourServiceType.serviceTypeLibrary.contains(self)
    }

    // MARK: - Static Helpers

    public static func generateFullType(
        type: String,
        transportLayer: TransportLayer
    ) -> String {
        return "_\(type)._\(transportLayer.string)"
    }

    @MainActor
    public static func fetchAll() -> [BonjourServiceType] {
        var all = self.serviceTypeLibrary
        for persistentServiceType in self.fetchAllPersistentCopies() where
            self.fetch(serviceTypes: all, type: persistentServiceType.type, transportLayer: persistentServiceType.transportLayer) == nil {
            all.append(persistentServiceType)
        }
        return all
    }

    public static var serviceTypeLibrary: [BonjourServiceType] {
        return self.tcpServiceTypes + self.udpServiceTypes
    }

    @MainActor
    public static func fetch(
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
    public static func fetch(
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
    public static func exists(
        serviceTypes: [BonjourServiceType]? = nil,
        type: String,
        transportLayer: TransportLayer
    ) -> Bool {
        return self.fetch(serviceTypes: serviceTypes, type: type, transportLayer: transportLayer) != nil
    }

    @MainActor
    public static func exists(
        serviceTypes: [BonjourServiceType]? = nil,
        fullType: String
    ) -> Bool {
        return self.fetch(serviceTypes: serviceTypes, fullType: fullType) != nil
    }
}
