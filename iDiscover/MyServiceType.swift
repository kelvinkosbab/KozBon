//
//  MyServiceType.swift
//  Test
//
//  Created by Kelvin Kosbab on 12/25/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation

class MyServiceType: Equatable {
  
  // Equatable
  
  static func == (lhs: MyServiceType, rhs: MyServiceType) -> Bool {
    return lhs.fullType == rhs.fullType
  }
  
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
    return "_\(self.type)._\(self.transportLayer.string)"
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
  
  static func fetchAll() -> [MyServiceType] {
    var all = self.serviceTypeLibrary
    for persistentServiceType in self.fetchAllPersistentCopies() {
      if !all.contains(persistentServiceType) {
        all.append(persistentServiceType)
      }
    }
    return all
  }
  
  static var serviceTypeLibrary: [MyServiceType] {
    return self.tcpServiceTypes
  }
  
  static func typeExists(_ type: String) -> Bool {
    for serviceType in self.fetchAll() {
      if serviceType.type == type {
        return true
      }
    }
    return false
  }
}
