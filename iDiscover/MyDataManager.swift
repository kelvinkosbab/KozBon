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
  
  // MARK: - Entities
  
  func getEntity(entityName: String) -> NSEntityDescription? {
    return self.getEntity(entityName: entityName, context: self.coreDataStack.mainContext)
  }
  
  private func getEntity(entityName: String, context: NSManagedObjectContext) -> NSEntityDescription? {
    return NSEntityDescription.entity(forEntityName: entityName, in: context)
  }
  
  // MARK: - Create
  
  func createObject(entityName: String) -> NSManagedObject {
    return self.createObject(entityName: entityName, context: self.coreDataStack.mainContext)
  }
  
  private func createObject(entityName: String, context: NSManagedObjectContext) -> NSManagedObject {
    return NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
  }
  
  // MARK: - Destroy
  
  func destroy(object: NSManagedObject) {
    self.delete(object: object)
    self.saveMainContext()
  }
  
  func destroy(request: NSFetchRequest<NSFetchRequestResult>, format: String, _ args: CVarArg...) {
    let predicate = NSPredicate(format: format, arguments: getVaList(args))
    self.destroyAll(request: request, predicate: predicate)
  }
  
  func destroyAll(request: NSFetchRequest<NSFetchRequestResult>, predicate: NSPredicate? = nil) {
    for object in self.fetch(request: request, predicate: predicate) {
      self.delete(object: object)
    }
    self.saveMainContext()
  }
  
  private func delete(object: NSManagedObject) {
    self.coreDataStack.mainContext.delete(object)
  }
  
  // MARK: - Fetching
  
  func fetch(request: NSFetchRequest<NSFetchRequestResult>, sortDescriptors: [NSSortDescriptor]? = nil, format: String, _ args: CVarArg...) -> [NSManagedObject] {
    let predicate = NSPredicate(format: format, arguments: getVaList(args))
    return self.fetch(request: request, predicate: predicate, sortDescriptors: sortDescriptors)
  }
  
  func fetch(request: NSFetchRequest<NSFetchRequestResult>, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) -> [NSManagedObject] {
    request.predicate = predicate
    request.sortDescriptors = sortDescriptors
    request.returnsObjectsAsFaults = false
    return self.fetch(request: request, context: self.coreDataStack.mainContext)
  }
  
  private func fetch(request: NSFetchRequest<NSFetchRequestResult>, context: NSManagedObjectContext) -> [NSManagedObject] {
    do {
      if let objects = try context.fetch(request) as? [NSManagedObject] {
        return objects
      } else {
        NSLog("\(self.className) : Failed to cast to NSManagedObject")
      }
    } catch {
      NSLog("\(self.className) : \(error.localizedDescription)")
    }
    return []
  }
  
  // MARK: - Counting
  
  func count(request: NSFetchRequest<NSFetchRequestResult>) -> Int {
    return self.count(request: request, predicate: nil)
  }
  
  func count(request: NSFetchRequest<NSFetchRequestResult>, format: String, _ args: CVarArg...) -> Int {
    let predicate = NSPredicate(format: format, arguments: getVaList(args))
    return self.count(request: request, predicate: predicate)
  }
  
  private func count(request: NSFetchRequest<NSFetchRequestResult>, predicate: NSPredicate?) -> Int {
    request.predicate = predicate
    request.returnsObjectsAsFaults = false
    request.includesSubentities = false
    
    do {
      return try self.coreDataStack.mainContext.count(for: request)
    } catch {
      return 0
    }
  }
}
