//
//  MyDataManagerObject.swift
//  Test
//
//  Created by Kelvin Kosbab on 12/23/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import CoreData

protocol MyDataManagerObject {
  static var sortDescriptors: [NSSortDescriptor]? { get }
}

extension MyDataManagerObject where Self : NSManagedObject {
  
  private static var entityName: String {
    return String(describing: Self.self)
  }
  
  static func newFetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
    return NSFetchRequest<CustomServiceType>(entityName: self.entityName) as! NSFetchRequest<NSFetchRequestResult>
  }
  
  static func create() -> Self {
    return MyDataManager.shared.createObject(entityName: self.entityName) as! Self
  }
  
  static func destroy(object: Self) {
    MyDataManager.shared.destroy(object: object)
  }
  
  static func destroyAll() {
    MyDataManager.shared.destroyAll(request: self.newFetchRequest())
  }
  
  static var count: Int {
    return MyDataManager.shared.count(request: self.newFetchRequest())
  }
  
  static func fetchOne(format: String, _ args: CVarArg...) -> Self? {
    return self.fetchMany(format: format, args).first
  }
  
  static func fetchMany(format: String, _ args: CVarArg...) -> [Self] {
    return self.fetchMany(sortDescriptors: self.sortDescriptors, format: format, args)
  }
  
  static func fetchMany(sortDescriptors: [NSSortDescriptor]?, format: String, _ args: CVarArg...) -> [Self] {
    let predicate = NSPredicate(format: format, arguments: getVaList(args))
    return MyDataManager.shared.fetch(request: self.newFetchRequest(), predicate: predicate, sortDescriptors: sortDescriptors) as! [Self]
  }
  
  static func fetchAll(sortDescriptors: [NSSortDescriptor]? = nil) -> [Self] {
    return MyDataManager.shared.fetch(request: self.newFetchRequest(), sortDescriptors: sortDescriptors ?? self.sortDescriptors) as! [Self]
  }
}
