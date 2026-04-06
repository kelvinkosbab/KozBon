//
//  MyDataManager.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import CoreData

@MainActor
public final class MyDataManager: NSObject {

    // MARK: - Singleton

    public static let shared = MyDataManager()

    private override init() { super.init() }

    // MARK: - Properties

    private lazy var coreDataStack = MyCoreDataStack.shared

    // MARK: - Managed Object Context

    public func saveMainContext() {
        self.coreDataStack.saveMainContext()
    }

    public var mainContext: NSManagedObjectContext {
        return self.coreDataStack.mainContext
    }
}
