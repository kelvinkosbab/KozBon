//
//  MyCoreDataStack.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourCore
import CoreData

/// Manages the Core Data persistent container and provides access to the main-thread managed object context.
///
/// Use the ``shared`` singleton to access the stack. All access is confined to the main actor
/// because the underlying `viewContext` must only be used from the main thread.
@MainActor
public final class MyCoreDataStack {

    private let logger = Logger(category: "MyCoreDataStack")

    // MARK: - Singleton

    /// The shared singleton instance of the Core Data stack.
    public static let shared = MyCoreDataStack()

    private init() {}

    // MARK: - Store Properties

    private let persistentContainerName = "iDiscover"

    private lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        guard let modelURL = Bundle.module.url(forResource: self.persistentContainerName, withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to load Core Data model from package bundle")
        }
        let container = NSPersistentContainer(name: self.persistentContainerName, managedObjectModel: model)
        container.loadPersistentStores { [weak self] (_, error) in
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
            // fatalError("Unresolved error \(error), \(error.userInfo)")
              self?.logger.error("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()

    // MARK: - Managed Object Context

    /// The main-thread managed object context (`viewContext`) used for all Core Data operations.
    public var mainContext: NSManagedObjectContext {
        return self.persistentContainer.viewContext
    }

    /// Saves any pending changes in the main context to the persistent store.
    ///
    /// If the context has no unsaved changes this method does nothing. Errors during
    /// save are logged rather than causing a fatal error.
    public func saveMainContext() {
        let context = self.mainContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                // fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                logger.error("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
