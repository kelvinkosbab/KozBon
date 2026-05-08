//
//  CustomServiceType.swift
//  BonjourStorage
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import CoreData
import BonjourCore

/// A Core Data managed object representing a user-created Bonjour service type.
///
/// Instances are persisted across app launches and allow users to define custom
/// service types beyond those included in the built-in library.
@objc(CustomServiceType)
@MainActor
public class CustomServiceType: NSManagedObject {

    /// An optional human-readable description of the service type.
    @NSManaged public var detail: String?

    /// The display name of the custom service type.
    @NSManaged public var name: String

    /// The Bonjour service type identifier (e.g., `"http"`), without leading underscore or transport suffix.
    @NSManaged public var serviceType: String

    /// The raw integer value of the transport layer protocol (TCP or UDP).
    ///
    /// Use ``BonjourCore/TransportLayer(rawValue:)`` to convert to a ``TransportLayer`` value.
    @NSManaged public var transportLayerValue: Int16
}

extension CustomServiceType: MyDataManagerObject {

    // MARK: - MyDataManagerObject

    /// Sort descriptors used when fetching custom service types. Always `nil` (no specific ordering).
    ///
    /// NSSortDescriptor is not Sendable, but this static is always nil and immutable.
    nonisolated(unsafe) public static let sortDescriptors: [NSSortDescriptor]? = nil

    // MARK: - Properties

    /// The complete Bonjour type string including underscores and transport suffix (e.g., `"_http._tcp"`).
    ///
    /// Returns `nil` if the transport layer value cannot be resolved.
    public var fullType: String? {
        return "_\(self.serviceType)._\(TransportLayer(rawValue: Int(self.transportLayerValue))?.string ?? "tcp")"
    }

    // MARK: - Fetch

    /// Fetches an existing custom service type matching the given type and transport layer.
    ///
    /// - Parameters:
    ///   - serviceType: The Bonjour service type identifier to search for.
    ///   - transportLayerValue: The raw transport layer value (TCP or UDP).
    /// - Returns: The matching ``CustomServiceType``, or `nil` if none exists.
    public static func fetch(
        serviceType: String,
        transportLayerValue: Int16
    ) -> CustomServiceType? {
        return self.fetchOne(format: "serviceType = %@ AND transportLayerValue = %ld", serviceType, transportLayerValue)
    }

    // MARK: - Create / Update

    /// Creates a new custom service type or updates an existing one that matches the given type and transport layer.
    ///
    /// If a record with the same `serviceType` and `transportLayerValue` already exists, its properties
    /// are updated in place. Otherwise a new managed object is inserted. The context is saved after the operation.
    ///
    /// - Parameters:
    ///   - name: The display name for the service type.
    ///   - serviceType: The Bonjour service type identifier.
    ///   - transportLayerValue: The raw transport layer value (TCP or UDP).
    ///   - detail: An optional human-readable description.
    /// - Returns: The created or updated ``CustomServiceType`` instance.
    public static func createOrUpdate(
        name: String,
        serviceType: String,
        transportLayerValue: Int16,
        detail: String? = nil
    ) -> CustomServiceType {
        let object = self.fetch(serviceType: serviceType, transportLayerValue: transportLayerValue) ?? self.create()
        object.name = name
        object.serviceType = serviceType
        object.transportLayerValue = transportLayerValue
        object.detail = detail
        self.saveMainContext()
        return object
    }
}
