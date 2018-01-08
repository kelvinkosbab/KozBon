//
//  MyCoreDataStack.swift
//  Test
//
//  Created by Kelvin Kosbab on 12/23/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import CoreData

class MyCoreDataStack: NSObject {
  
  // MARK: - Singleton
  
  static let shared = MyCoreDataStack()
  
  private override init() {
    super.init()
    
    NotificationCenter.default.addObserver(self, selector: #selector(self.contextWillSave(_:)), name: .NSManagedObjectContextWillSave, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(self.contextDidSave(_:)), name: .NSManagedObjectContextDidSave, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(self.contextObjectsDidChange(_:)), name: .NSManagedObjectContextObjectsDidChange, object: nil)
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  // MARK: - Store Properties
  
  private let persistentContainerName = "iDiscover"
  
  private lazy var persistentContainer: NSPersistentContainer = {
    /*
     The persistent container for the application. This implementation
     creates and returns a container, having loaded the store for the
     application to it. This property is optional since there are legitimate
     error conditions that could cause the creation of the store to fail.
     */
    let container = NSPersistentContainer(name: self.persistentContainerName)
    container.loadPersistentStores(completionHandler: { (storeDescription, error) in
      if let error = error as NSError? {
        // Replace this implementation with code to handle the error appropriately.
        // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        
        /*
         Typical reasons for an error here include:
         * The parent directory does not exist, cannot be created, or disallows writing.
         * The persistent store is not accessible, due to permissions or data protection when the device is locked.
         * The device is out of space.
         * The store could not be migrated to the current model version.
         Check the error message to determine what the actual problem was.
         */
        //fatalError("Unresolved error \(error), \(error.userInfo)")
        Log.log("Unresolved error \(error), \(error.userInfo)")
      }
    })
    return container
  }()
  
  // MARK: - Context Notifications
  
  @objc private func contextWillSave(_ notification: Notification) {
    Log.log("Context will save")
  }
  
  @objc private func contextDidSave(_ notification: Notification) {
    if let _ = notification.object as? NSManagedObjectContext {
      Log.log("Context did save")
    }
  }
  
  @objc private func contextObjectsDidChange(_ notification: Notification) {
    Log.log("Objects did change")
  }
  
  // MARK: - Managed Object Context
  
  var mainContext: NSManagedObjectContext {
    return self.persistentContainer.viewContext
  }
  
  func saveMainContext() {
    let context = self.mainContext
    if context.hasChanges {
      do {
        try context.save()
      } catch {
        // Replace this implementation with code to handle the error appropriately.
        // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        let nserror = error as NSError
        //fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        Log.log("Unresolved error \(nserror), \(nserror.userInfo)")
      }
    }
  }
}
