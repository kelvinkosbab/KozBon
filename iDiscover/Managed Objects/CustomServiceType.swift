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

extension CustomServiceType: MyDataManagerObject {
  
  // MARK: - MyDataManagerObject
  
  static let sortDescriptors: [NSSortDescriptor]? = []
  
  // MARK: - Properties
  
  var transportLayer: MyTransportLayer {
    get {
      return MyTransportLayer(rawValue: Int(self.transportLayerValue))!
    }
    set {
      self.transportLayerValue = Int16(newValue.rawValue)
    }
  }
  
  var myServiceType: MyServiceType {
    return MyServiceType(name: self.name!, type: self.type!, transportLayer: self.transportLayer, detail: self.detail)
  }
  
  // MARK: - Fetch
  
  class func fetch(type: String) -> CustomServiceType? {
    return self.fetchOne(format: "type == %@", name)
  }
  
  // MARK: - Create / Update
  
  class func createOrUpdate(name: String, type: String, transportLayer: MyTransportLayer, detail: String? = nil) -> CustomServiceType {
    let object = self.fetch(type: type) ?? self.create()
    object.name = name
    object.type = type
    object.transportLayer = transportLayer
    object.detail = detail
    MyDataManager.shared.saveMainContext()
    return object
  }
}
