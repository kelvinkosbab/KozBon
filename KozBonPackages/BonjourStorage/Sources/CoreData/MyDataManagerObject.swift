//
//  MyDataManagerObject.swift
//  BonjourStorage
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourCore
import CoreData

/// Defines a standard interface for Core Data managed objects, providing CRUD convenience methods.
///
/// Conforming types gain default implementations for creating, fetching, deleting, and counting
/// entities through the extension on `NSManagedObject`. All operations run on the main actor
/// and use the shared ``MyCoreDataStack`` context.
@MainActor
public protocol MyDataManagerObject {

    /// Optional sort descriptors applied by default when fetching entities of this type.
    ///
    /// Return `nil` to use no particular ordering.
    static var sortDescriptors: [NSSortDescriptor]? { get }
}

public extension MyDataManagerObject where Self: NSManagedObject {

    private static var entityName: String {
        return String(describing: Self.self)
    }

    private static var logger: Loggable {
        Logger(category: Self.entityName)
    }

    // MARK: - Managed Object Context

    /// The main-thread managed object context from the shared Core Data stack.
    static var mainContext: NSManagedObjectContext {
        return MyCoreDataStack.shared.mainContext
    }

    /// Saves any pending changes in the main context to the persistent store.
    ///
    /// Catches and logs any save errors so that callers (delete, create, update)
    /// don't need to handle throws individually.
    static func saveMainContext() {
        do {
            try MyCoreDataStack.shared.saveMainContext()
        } catch {
            logger.error("Failed to save context: \(error.localizedDescription)")
        }
    }

    // MARK: - Create

    /// Inserts a new managed object of this type into the main context.
    ///
    /// - Returns: The newly created managed object.
    static func create() -> Self {
        // swiftlint:disable:next force_cast
        return NSEntityDescription.insertNewObject(forEntityName: self.entityName, into: self.mainContext) as! Self
    }

    // MARK: - Managed Object Entity

    private static func getEntity() -> NSEntityDescription? {
        return NSEntityDescription.entity(forEntityName: self.entityName, in: self.mainContext)
    }

    // MARK: - Fetching

    /// Creates a new fetch request for this entity type.
    ///
    /// - Returns: A typed `NSFetchRequest` targeting this entity.
    static func newFetchRequest() -> NSFetchRequest<Self> {
        return NSFetchRequest<Self>(entityName: self.entityName)
    }

    /// Fetches a single managed object matching the given predicate format string.
    ///
    /// - Parameters:
    ///   - format: An `NSPredicate` format string.
    ///   - args: Arguments to substitute into the format string.
    /// - Returns: The first matching object, or `nil` if none is found.
    static func fetchOne(format: String, _ args: CVarArg...) -> Self? {
        let predicate = NSPredicate(format: format, arguments: getVaList(args))
        return self.fetch(predicate: predicate).first
    }

    /// Fetches all managed objects matching the given predicate, using the type's default sort descriptors.
    ///
    /// - Parameters:
    ///   - format: An `NSPredicate` format string.
    ///   - args: Arguments to substitute into the format string.
    /// - Returns: An array of matching objects.
    static func fetchMany(format: String, _ args: CVarArg...) -> [Self] {
        return self.fetchMany(sortDescriptors: self.sortDescriptors, format: format, args)
    }

    /// Fetches all managed objects matching the given predicate, using the provided sort descriptors.
    ///
    /// - Parameters:
    ///   - sortDescriptors: Sort descriptors to order the results, or `nil` for no ordering.
    ///   - format: An `NSPredicate` format string.
    ///   - args: Arguments to substitute into the format string.
    /// - Returns: An array of matching objects.
    static func fetchMany(sortDescriptors: [NSSortDescriptor]?, format: String, _ args: CVarArg...) -> [Self] {
        let predicate = NSPredicate(format: format, arguments: getVaList(args))
        return self.fetch(predicate: predicate, sortDescriptors: sortDescriptors)
    }

    /// Fetches all managed objects of this type, optionally sorted by the given descriptors.
    ///
    /// - Parameter sortDescriptors: Sort descriptors to order the results. Falls back to the type's
    ///   default ``sortDescriptors`` when `nil`.
    /// - Returns: An array of all objects of this entity type.
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
            logger.error("Fetch failed for \(Self.entityName): \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Deleting

    /// Deletes a single managed object and saves the context.
    ///
    /// - Parameter object: The managed object to delete.
    static func deleteOne(_ object: Self) {
        self.delete(object: object)
        self.saveMainContext()
    }

    /// Deletes all managed objects matching the given predicate and saves the context.
    ///
    /// - Parameters:
    ///   - format: An `NSPredicate` format string.
    ///   - args: Arguments to substitute into the format string.
    static func deleteMany(format: String, _ args: CVarArg...) {
        for object in self.fetchMany(format: format, args) {
            self.delete(object: object)
        }
        self.saveMainContext()
    }

    /// Deletes all managed objects of this type and saves the context.
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

    /// Returns the total number of managed objects of this type in the persistent store.
    static func countAll() -> Int {
        return self.count(predicate: nil)
    }

    /// Returns the number of managed objects matching the given predicate.
    ///
    /// - Parameters:
    ///   - format: An `NSPredicate` format string.
    ///   - args: Arguments to substitute into the format string.
    /// - Returns: The count of matching objects, or `0` if an error occurs.
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
            logger.error("Count failed for \(Self.entityName): \(error.localizedDescription)")
            return 0
        }
    }
}
