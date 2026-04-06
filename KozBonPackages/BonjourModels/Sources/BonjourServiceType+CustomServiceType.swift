//
//  BonjourServiceType+CustomServiceType.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourCore
import BonjourData

// MARK: - CustomServiceType + BonjourServiceType Bridge

public extension CustomServiceType {

    /// Converts a Core Data `CustomServiceType` entity to a `BonjourServiceType` value type.
    // swiftlint:disable:next identifier_name
    var bonjourServiceType: BonjourServiceType {
        let transportLayer = TransportLayer(rawValue: Int(self.transportLayerValue)) ?? .tcp
        return BonjourServiceType(
            name: self.name,
            type: self.serviceType,
            transportLayer: transportLayer,
            detail: self.detail
        )
    }
}

// MARK: - BonjourServiceType + Persistence

extension BonjourServiceType {

    // MARK: - Saving / Deleting Persistent Copies

    @MainActor
    public var hasPersistentCopy: Bool {
        return CustomServiceType.fetch(
            serviceType: self.type,
            transportLayerValue: Int16(self.transportLayer.rawValue)
        ) != nil
    }

    @MainActor
    public func savePersistentCopy() {
        _ = CustomServiceType.createOrUpdate(
            name: self.name,
            serviceType: self.type,
            transportLayerValue: Int16(self.transportLayer.rawValue),
            detail: self.detail
        )
    }

    @MainActor
    public func deletePersistentCopy() {
        if let persistentCopy = CustomServiceType.fetch(
            serviceType: self.type,
            transportLayerValue: Int16(self.transportLayer.rawValue)
        ) {
            CustomServiceType.deleteOne(persistentCopy)
        }
    }

    // MARK: - Static Helpers

    @MainActor
    public static func fetchPersistentCopy(type: String, transportLayer: TransportLayer) -> BonjourServiceType? {
        if let persistentCopy = CustomServiceType.fetch(
            serviceType: type,
            transportLayerValue: Int16(transportLayer.rawValue)
        ) {
            return persistentCopy.bonjourServiceType
        }
        return nil
    }

    @MainActor
    public static func fetchAllPersistentCopies() -> [BonjourServiceType] {
        CustomServiceType.fetchAll().map(\.bonjourServiceType)
    }

    @MainActor
    public static func deletePersistentCopy(serviceType: BonjourServiceType) {
        serviceType.deletePersistentCopy()
    }

    @MainActor
    public static func deleteAllPersistentCopies() {
        CustomServiceType.deleteAll()
    }
}
