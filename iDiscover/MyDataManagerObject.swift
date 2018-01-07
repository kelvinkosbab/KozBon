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
  
  // MARK: - Managed Object Context
  
  static var mainContext: NSManagedObjectContext {
    return MyCoreDataStack.shared.mainContext
  }
  
  static func saveMainContext() {
    MyCoreDataStack.shared.saveMainContext()
  }
  
  // MARK: - Create
  
  static func create() -> Self {
    return NSEntityDescription.insertNewObject(forEntityName: self.entityName, into: self.mainContext) as! Self
  }
  
  // MARK: - Managed Object Entity
  
  private static func getEntity() -> NSEntityDescription? {
    return NSEntityDescription.entity(forEntityName: self.entityName, in: self.mainContext)
  }
  
  // MARK: - Fetching
  
  static func newFetchRequest() -> NSFetchRequest<Self> {
    return NSFetchRequest<Self>(entityName: self.entityName)
  }
  
  static func fetchOne(format: String, _ args: CVarArg...) -> Self? {
    let predicate = NSPredicate(format: format, arguments: getVaList(args))
    return self.fetch(predicate: predicate).first
  }
  
  static func fetchMany(format: String, _ args: CVarArg...) -> [Self] {
    return self.fetchMany(sortDescriptors: self.sortDescriptors, format: format, args)
  }
  
  static func fetchMany(sortDescriptors: [NSSortDescriptor]?, format: String, _ args: CVarArg...) -> [Self] {
    let predicate = NSPredicate(format: format, arguments: getVaList(args))
    return self.fetch(predicate: predicate, sortDescriptors: sortDescriptors)
  }
  
  static func fetchAll(sortDescriptors: [NSSortDescriptor]? = nil) -> [Self] {
    let request = self.newFetchRequest()
    request.sortDescriptors = sortDescriptors ?? self.sortDescriptors
    request.returnsObjectsAsFaults = false
    return self.fetch(sortDescriptors: sortDescriptors)
  }
  
  private static func fetch(predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) -> [Self] {
    let request = self.newFetchRequest()
    request.predicate = predicate
    request.sortDescriptors = sortDescriptors ?? self.sortDescriptors
    request.returnsObjectsAsFaults = false
    do {
      return try self.mainContext.fetch(request)
    } catch {
      Log.log("\(error.localizedDescription)")
    }
    return []
  }
  
  // MARK: - Deleting
  
  static func deleteOne(_ object: Self) {
    self.delete(object: object)
    self.saveMainContext()
  }

  static func deleteMany(format: String, _ args: CVarArg...) {
    for object in self.fetchMany(format: format, args) {
      self.delete(object: object)
    }
    self.saveMainContext()
  }
  
  static func deleteAll() {
    for object in self.fetchAll() {
      self.delete(object: object)
    }
    self.saveMainContext()
  }
  
  private static func delete(object: Self) {
    self.mainContext.delete(object)
  }
  
  // MARK: - Counting
  
  static func countAll() -> Int {
    return self.count(predicate: nil)
  }
  
  static func countMany(format: String, _ args: CVarArg...) -> Int {
    let predicate = NSPredicate(format: format, arguments: getVaList(args))
    return self.count(predicate: predicate)
  }
  
  private static func count(predicate: NSPredicate? = nil) -> Int {
    let request = self.newFetchRequest()
    request.predicate = predicate
    request.returnsObjectsAsFaults = false
    request.includesSubentities = false
    do {
      return try self.mainContext.count(for: request)
    } catch {
      return 0
    }
  }
}
