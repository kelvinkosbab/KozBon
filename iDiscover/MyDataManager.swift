//
//  MyDataManager.swift
//  Test
//
//  Created by Kelvin Kosbab on 12/23/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import CoreData

class MyDataManager: NSObject {
  
  // MARK: - Singleton
  
  static let shared = MyDataManager()
  
  private override init() { super.init() }
  
  // MARK: - Properties
  
  private lazy var coreDataStack = MyCoreDataStack.shared
  
  // MARK: - Managed Object Context
  
  func saveMainContext() {
    self.coreDataStack.saveMainContext()
  }
  
  var mainContext: NSManagedObjectContext {
    return self.coreDataStack.mainContext
  }
}
