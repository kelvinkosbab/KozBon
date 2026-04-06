//
//  Logger.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Core

// MARK: - Logger

public extension Logger {
    /// Creates a custom logger for logging to a specific subsystem and category.
    ///
    /// - Parameter category: Describes a category specifying the specific action that is happening.
    init(category: String) {
        self.init(subsystem: "KozBon", category: category)
    }
}
