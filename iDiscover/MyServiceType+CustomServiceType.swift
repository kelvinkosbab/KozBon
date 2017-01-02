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
    if let _  = CustomServiceType.fetch(serviceType: self) {
      return true
    }
    return false
  }
  
  func savePersistentCopy() {
    // Check if type already exists in the built in library
    if !MyServiceType.serviceTypeLibrary.contains(self) {
      _ = CustomServiceType.createOrUpdate(serviceType: self)
    }
  }
  
  func deletePersistentCopy() {
    if let persistentCopy = CustomServiceType.fetch(serviceType: self) {
      CustomServiceType.destroy(object: persistentCopy)
      MyDataManager.shared.saveMainContext()
    }
  }
  
  // MARK: - Static Helpers
  
  static func fetchPersistentCopy(type: String) -> MyServiceType? {
    if let persistentCopy = CustomServiceType.fetch(type: type) {
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
    MyDataManager.shared.saveMainContext()
  }
}
