//
//  BonjourServiceTypeScope.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - BonjourServiceTypeScope

/// A filter scope for browsing Bonjour service types.
///
/// Used to narrow the service type list to all types, only built-in types
/// from the app's library, or only user-created custom types.
public enum BonjourServiceTypeScope: CaseIterable, Sendable {

    /// Show all service types (built-in and user-created).
    case all

    /// Show only built-in service types from the app's library.
    case builtIn

    /// Show only user-created custom service types.
    case created

    /// A human-readable display string for this scope (e.g. `"All"`, `"Built-In"`, `"Created"`).
    public var string: String {
        switch self {
        case .all:
            return "All"
        case .builtIn:
            return "Built-In"
        case .created:
            return "Created"
        }
    }

    /// Whether this scope is ``all``.
    public var isAll: Bool {
        return self == .all
    }

    /// Whether this scope is ``builtIn``.
    public var isBuiltIn: Bool {
        return self == .builtIn
    }

    /// Whether this scope is ``created``.
    public var isCreated: Bool {
        return self == .created
    }

    /// All available scopes in display order.
    public static let allScopes: [BonjourServiceTypeScope] = [ .all, .builtIn, .created ]

    /// The display strings for all available scopes, in the same order as ``allScopes``.
    public static var allScopeTitles: [String] {
        var titles: [String] = []
        for scope in self.allScopes {
            titles.append(scope.string)
        }
        return titles
    }
}
