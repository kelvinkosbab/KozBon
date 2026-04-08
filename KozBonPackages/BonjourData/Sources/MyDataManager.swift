//
//  MyDataManager.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import CoreData

/// A convenience facade over ``MyCoreDataStack`` that exposes the main context and save operations.
///
/// Use the ``shared`` singleton to access the data manager. This class delegates all
/// persistence work to ``MyCoreDataStack/shared``.
@MainActor
public final class MyDataManager: NSObject {

    // MARK: - Singleton

    /// The shared singleton instance of the data manager.
    public static let shared = MyDataManager()

    private override init() { super.init() }

    // MARK: - Properties

    private lazy var coreDataStack = MyCoreDataStack.shared

    // MARK: - Managed Object Context

    /// Saves any pending changes in the main context to the persistent store.
    ///
    /// - Throws: An error if the context fails to save.
    public func saveMainContext() throws {
        try self.coreDataStack.saveMainContext()
    }

    /// The main-thread managed object context used for all Core Data operations.
    public var mainContext: NSManagedObjectContext {
        return self.coreDataStack.mainContext
    }
}
