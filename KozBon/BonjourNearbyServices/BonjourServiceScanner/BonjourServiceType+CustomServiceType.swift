//
//  BonjourServiceType+CustomServiceType.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 1/1/17.
//  Copyright © 2017 Kozinga. All rights reserved.
//

import Foundation

extension BonjourServiceType {

  // MARK: - Saving / Deleting Persistent Copies

  @MainActor
  var hasPersistentCopy: Bool {
    return CustomServiceType.fetch(
        serviceType: self.type,
        transportLayer: self.transportLayer
    ) != nil
  }

  @MainActor
  func savePersistentCopy() {
      _ = CustomServiceType.createOrUpdate(
          name: self.name,
          serviceType: self.type,
          transportLayer: self.transportLayer,
          detail: self.detail
      )
  }

  @MainActor
  func deletePersistentCopy() {
    if let persistentCopy = CustomServiceType.fetch(
        serviceType: self.type,
        transportLayer: self.transportLayer
    ) {
      CustomServiceType.deleteOne(persistentCopy)
    }
  }

  // MARK: - Static Helpers

  @MainActor
  static func fetchPersistentCopy(type: String, transportLayer: TransportLayer) -> BonjourServiceType? {
    if let persistentCopy = CustomServiceType.fetch(
        serviceType: type,
        transportLayer: transportLayer
    ) {
      return persistentCopy.BonjourServiceType
    }
    return nil
  }

  @MainActor
  static func fetchAllPersistentCopies() -> [BonjourServiceType] {
    var copies: [BonjourServiceType] = []
    for serviceType in CustomServiceType.fetchAll() {
      copies.append(serviceType.BonjourServiceType)
    }
    return copies
  }

  @MainActor
  static func deletePersistentCopy(serviceType: BonjourServiceType) {
    serviceType.deletePersistentCopy()
  }

  @MainActor
  static func deleteAllPersistentCopies() {
    CustomServiceType.deleteAll()
  }
}
