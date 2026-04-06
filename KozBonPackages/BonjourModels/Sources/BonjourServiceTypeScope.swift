//
//  BonjourServiceTypeScope.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - BonjourServiceTypeScope

public enum BonjourServiceTypeScope: CaseIterable, Sendable {

    case all, builtIn, created

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

    public var isAll: Bool {
        return self == .all
    }

    public var isBuiltIn: Bool {
        return self == .builtIn
    }

    public var isCreated: Bool {
        return self == .created
    }

    public static let allScopes: [BonjourServiceTypeScope] = [ .all, .builtIn, .created ]

    public static var allScopeTitles: [String] {
        var titles: [String] = []
        for scope in self.allScopes {
            titles.append(scope.string)
        }
        return titles
    }
}
