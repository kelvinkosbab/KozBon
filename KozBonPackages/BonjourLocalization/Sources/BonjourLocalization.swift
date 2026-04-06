//
//  BonjourLocalization.swift
//  BonjourLocalization
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - BonjourLocalization

/// Provides access to the localization bundle for the BonjourLocalization module.
///
/// Use `BonjourLocalization.bundle` when you need to pass a bundle reference
/// for string lookup, or use the type-safe constants in ``Strings``.
public enum BonjourLocalization {
    /// The resource bundle containing localized string catalogs.
    public static let bundle: Bundle = .module
}
