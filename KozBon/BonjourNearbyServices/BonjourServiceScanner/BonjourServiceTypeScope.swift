//
//  BonjourServiceTypeScope.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - BonjourServiceTypeScope

enum BonjourServiceTypeScope: CaseIterable {

    case all, builtIn, created

    var string: String {
        switch self {
        case .all:
            return "All"
        case .builtIn:
            return "Built-In"
        case .created:
            return "Created"
        }
    }

    var isAll: Bool {
        return self == .all
    }

    var isBuiltIn: Bool {
        return self == .builtIn
    }

    var isCreated: Bool {
        return self == .created
    }

    static let allScopes: [BonjourServiceTypeScope] = [ .all, .builtIn, .created ]

    static var allScopeTitles: [String] {
        var titles: [String] = []
        for scope in self.allScopes {
            titles.append(scope.string)
        }
        return titles
    }
}
