//
//  MyCoreDataStack.swift
//  BonjourStorage
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

    // MARK: - Shared Instance

    /// The shared Core Data stack instance used by `MyDataManagerObject` protocol extensions.
    ///
    /// This is a singleton because the protocol extension pattern uses static methods
    /// that cannot receive injected dependencies through initializers.
    public static let shared = MyCoreDataStack()

    private init() {}

    /// Whether the bundled Core Data model (`iDiscover.momd`) is
    /// reachable in the package's resource bundle.
    ///
    /// `false` under `swift test` from the SPM CLI — the Swift
    /// Package Manager doesn't compile `.xcdatamodeld` files, so
    /// the bundle ships without the resolved `.momd`. `true` in
    /// the app, in `xcodebuild test` runs, and in any context
    /// where Xcode's build pipeline produced the bundle.
    ///
    /// Tests that exercise paths reaching ``mainContext``
    /// short-circuit on `false` to avoid the fatal error in
    /// ``persistentContainer``'s lazy initializer.
    public static var isBundledModelAvailable: Bool {
        Bundle.module.url(
            forResource: "iDiscover",
            withExtension: "momd"
        ) != nil
    }

    // MARK: - Store Properties

    private let persistentContainerName = "iDiscover"

    private lazy var persistentContainer: NSPersistentContainer = {
        guard let modelURL = Bundle.module.url(forResource: self.persistentContainerName, withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to load Core Data model from package bundle")
        }
        let container = NSPersistentContainer(name: self.persistentContainerName, managedObjectModel: model)
        container.loadPersistentStores { (_, error) in
            if let error = error as NSError? {
                // If the persistent store cannot be loaded, the app cannot function.
                // Common causes: directory permissions, device storage full, model migration failure.
                fatalError("Failed to load persistent store: \(error), \(error.userInfo)")
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
    /// - Throws: An error if the context fails to save (e.g., validation errors, store unavailable).
    public func saveMainContext() throws {
        let context = self.mainContext
        if context.hasChanges {
            try context.save()
        }
    }
}
