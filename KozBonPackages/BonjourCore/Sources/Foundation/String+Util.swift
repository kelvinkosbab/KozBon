//
//  String+Util.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - String Utilities

public extension String {

    /// Returns the string with leading and trailing whitespace
    /// removed.
    ///
    /// Trims via `CharacterSet.whitespaces`, which covers the
    /// common ASCII space and Unicode whitespace categories *but
    /// not* line terminators (`\n`, `\r`). For form input fields
    /// where stray newlines should also be stripped, use
    /// `trimmingCharacters(in: .whitespacesAndNewlines)` directly
    /// — this property is the form most form-validation pipelines
    /// in the app expect (preserves multi-line content while
    /// trimming the visual padding).
    var trimmed: String {
        self.trimmingCharacters(in: .whitespaces)
    }

    /// Returns whether the receiver contains the given substring,
    /// ignoring case.
    ///
    /// Both sides are lowercased before the search, which is the
    /// simplest case-insensitive contains check that's safe for
    /// the languages KozBon ships in. For locale-sensitive
    /// comparisons (e.g. Turkish `i` / `İ` casing), prefer
    /// `range(of:options:locale:)` with explicit
    /// `[.caseInsensitive, .diacriticInsensitive]` and the
    /// user's current locale.
    ///
    /// - Parameter string: The substring to search for. An empty
    ///   query always returns `true` — matches the standard
    ///   `String.contains` semantics.
    /// - Returns: `true` if `self` contains `string` ignoring case.
    func containsIgnoreCase(_ string: String) -> Bool {
        self.lowercased().range(of: string.lowercased()) != nil
    }
}
