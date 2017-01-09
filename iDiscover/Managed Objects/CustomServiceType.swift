//
//  CustomServiceType.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 12/26/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData

@objc(CustomServiceType)
public class CustomServiceType: NSManagedObject {
  @NSManaged public var detail: String?
  @NSManaged public var name: String
  @NSManaged public var serviceType: String
  @NSManaged public var transportLayerValue: Int16
}

extension CustomServiceType: MyDataManagerObject {
  
  // MARK: - MyDataManagerObject
  
  static let sortDescriptors: [NSSortDescriptor]? = nil
  
  // MARK: - Properties
  
  var fullType: String? {
    return "_\(self.serviceType)._\(self.transportLayer.string)"
  }
  
  private var transportLayer: MyTransportLayer {
    get {
      return MyTransportLayer(rawValue: Int(self.transportLayerValue))!
    }
    set {
      self.transportLayerValue = Int16(newValue.rawValue)
    }
  }
  
  var myServiceType: MyServiceType {
    return MyServiceType(name: self.name, type: self.serviceType, transportLayer: self.transportLayer, detail: self.detail)
  }
  
  // MARK: - Fetch
  
  static func fetch(serviceType: String, transportLayer: MyTransportLayer) -> CustomServiceType? {
    return self.fetchOne(format: "serviceType = %@ AND transportLayerValue = %ld", serviceType, Int16(transportLayer.rawValue))
  }
  
  // MARK: - Create / Update
  
  static func createOrUpdate(name: String, serviceType: String, transportLayer: MyTransportLayer, detail: String? = nil) -> CustomServiceType {
    let object = self.fetch(serviceType: serviceType, transportLayer: transportLayer) ?? self.create()
    object.name = name
    object.serviceType = serviceType
    object.transportLayer = transportLayer
    object.detail = detail
    self.saveMainContext()
    return object
  }
}
