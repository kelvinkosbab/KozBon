//
//  String+Util.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - Helpers & Helpers

public extension String {

    var trimmed: String {
        self.trimmingCharacters(in: .whitespaces)
    }

    func containsIgnoreCase(_ string: String) -> Bool {
        self.lowercased().range(of: string.lowercased()) != nil
    }
}
