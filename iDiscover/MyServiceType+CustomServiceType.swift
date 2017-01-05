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
    return CustomServiceType.fetch(serviceType: self.type) != nil
  }
  
  func savePersistentCopy() {
    // Check if type already exists in the built in library
    if !MyServiceType.serviceTypeLibrary.contains(self) {
      _ = CustomServiceType.createOrUpdate(name: self.name, serviceType: self.type, transportLayer: self.transportLayer, detail: self.detail)
    }
  }
  
  func deletePersistentCopy() {
    if let persistentCopy = CustomServiceType.fetch(serviceType: self.type) {
      CustomServiceType.destroy(object: persistentCopy)
    }
  }
  
  // MARK: - Static Helpers
  
  static func fetchPersistentCopy(type: String) -> MyServiceType? {
    if let persistentCopy = CustomServiceType.fetch(serviceType: type) {
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
    CustomServiceType.destroyAll()
  }
}
