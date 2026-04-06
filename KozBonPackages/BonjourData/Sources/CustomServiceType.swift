//
//  CustomServiceType.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import CoreData
import BonjourCore

@objc(CustomServiceType)
@MainActor
public class CustomServiceType: NSManagedObject {
    @NSManaged public var detail: String?
    @NSManaged public var name: String
    @NSManaged public var serviceType: String
    @NSManaged public var transportLayerValue: Int16
}

extension CustomServiceType: MyDataManagerObject {

    // MARK: - MyDataManagerObject

    // NSSortDescriptor is not Sendable, but this static is always nil and immutable
    nonisolated(unsafe) public static let sortDescriptors: [NSSortDescriptor]? = nil

    // MARK: - Properties

    public var fullType: String? {
        return "_\(self.serviceType)._\(TransportLayer(rawValue: Int(self.transportLayerValue))?.string ?? "tcp")"
    }

    // MARK: - Fetch

    public static func fetch(serviceType: String, transportLayerValue: Int16) -> CustomServiceType? {
        return self.fetchOne(format: "serviceType = %@ AND transportLayerValue = %ld", serviceType, transportLayerValue)
    }

    // MARK: - Create / Update

    public static func createOrUpdate(
        name: String, serviceType: String,
        transportLayerValue: Int16, detail: String? = nil
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
