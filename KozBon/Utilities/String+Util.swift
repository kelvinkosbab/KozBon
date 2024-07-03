//
//  String+Util.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 12/27/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation

// MARK: - Helpers & Helpers

extension String {

    var trimmed: String {
        self.trimmingCharacters(in: .whitespaces)
    }

    func containsIgnoreCase(_ string: String) -> Bool {
        self.lowercased().range(of: string.lowercased()) != nil
    }
}
