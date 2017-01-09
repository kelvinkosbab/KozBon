//
//  MyServiceType.swift
//  Test
//
//  Created by Kelvin Kosbab on 12/25/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation

extension Notification.Name {
  static let myServiceTypeDidCreateAndSave = Notification.Name(rawValue: "\(MyServiceType.name).myServiceTypeDidCreateAndSave")
}

class MyServiceType: NSObject {
  
  // MARK: - Properties \ Init
  
  let name: String
  let type: String
  let transportLayer: MyTransportLayer
  let detail: String?
  
  init(name: String, type: String, transportLayer: MyTransportLayer = .tcp, detail: String? = nil) {
    self.name = name
    self.type = type
    self.transportLayer = transportLayer
    self.detail = detail
  }
  
  var fullType: String {
    return MyServiceType.generateFullType(type: self.type, transportLayer: self.transportLayer)
  }
  
  var isBuiltIn: Bool {
    for serviceType in MyServiceType.serviceTypeLibrary {
      if self == serviceType {
        return true
      }
    }
    return false
  }
  
  // MARK: - Static Helpers
  
  static func generateFullType(type: String, transportLayer: MyTransportLayer) -> String {
    return "_\(type)._\(transportLayer.string)"
  }
  
  static func fetchAll() -> [MyServiceType] {
    var all = self.serviceTypeLibrary
    for persistentServiceType in self.fetchAllPersistentCopies() {
      if self.fetch(serviceTypes: all, type: persistentServiceType.type, transportLayer: persistentServiceType.transportLayer) == nil {
        all.append(persistentServiceType)
      }
    }
    return all
  }
  
  static var serviceTypeLibrary: [MyServiceType] {
    return self.tcpServiceTypes + self.udpServiceTypes
  }
  
  static func fetch(serviceTypes: [MyServiceType]? = nil, type: String, transportLayer: MyTransportLayer) -> MyServiceType? {
    let typesToFilter = serviceTypes ?? self.fetchAll()
    let filtered = typesToFilter.filter { (serviceType) -> Bool in
      serviceType.type == type && serviceType.transportLayer == transportLayer
    }
    return filtered.first
  }
  
  static func fetch(serviceTypes: [MyServiceType]? = nil, fullType: String) -> MyServiceType? {
    let typesToFilter = serviceTypes ?? self.fetchAll()
    let filtered = typesToFilter.filter { (serviceType) -> Bool in
      serviceType.fullType == fullType
    }
    return filtered.first
  }
  
  static func exists(serviceTypes: [MyServiceType]? = nil, type: String, transportLayer: MyTransportLayer) -> Bool {
    return self.fetch(serviceTypes: serviceTypes, type: type, transportLayer: transportLayer) != nil
  }
  
  static func exists(serviceTypes: [MyServiceType]? = nil, fullType: String) -> Bool {
    return self.fetch(serviceTypes: serviceTypes, fullType: fullType) != nil
  }
}
