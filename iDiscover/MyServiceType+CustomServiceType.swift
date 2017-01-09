//
//  MyServiceType+CustomServiceType.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 1/1/17.
//  Copyright © 2017 Kozinga. All rights reserved.
//

import Foundation

extension MyServiceType {
  
  // MARK: - Saving / Deleting Persistent Copies
  
  var hasPersistentCopy: Bool {
    return CustomServiceType.fetch(serviceType: self.type, transportLayer: self.transportLayer) != nil
  }
  
  func savePersistentCopy() {
    // Check if type already exists in the built in library
    if !MyServiceType.exists(serviceTypes: MyServiceType.serviceTypeLibrary, fullType: self.fullType) {
      _ = CustomServiceType.createOrUpdate(name: self.name, serviceType: self.type, transportLayer: self.transportLayer, detail: self.detail)
    }
  }
  
  func deletePersistentCopy() {
    if let persistentCopy = CustomServiceType.fetch(serviceType: self.type, transportLayer: self.transportLayer) {
      CustomServiceType.deleteOne(persistentCopy)
    }
  }
  
  // MARK: - Static Helpers
  
  static func fetchPersistentCopy(type: String, transportLayer: MyTransportLayer) -> MyServiceType? {
    if let persistentCopy = CustomServiceType.fetch(serviceType: type, transportLayer: transportLayer) {
      return persistentCopy.myServiceType
    }
    return nil
  }
  
  static func fetchAllPersistentCopies() -> [MyServiceType] {
    var copies: [MyServiceType] = []
    for serviceType in CustomServiceType.fetchAll() {
      copies.append(serviceType.myServiceType)
    }
    return copies
  }
  
  static func deletePersistentCopy(serviceType: MyServiceType) {
    serviceType.deletePersistentCopy()
  }
  
  static func deleteAllPersistentCopies() {
    CustomServiceType.deleteAll()
  }
}
