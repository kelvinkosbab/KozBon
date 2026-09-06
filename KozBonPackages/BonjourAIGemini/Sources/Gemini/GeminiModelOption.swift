//
//  GeminiModelOption.swift
//  BonjourAIGemini
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - GeminiModelOption

/// One selectable Gemini model in the Settings picker.
///
/// A struct rather than an enum for the same reason
/// ``AnthropicModelOption`` is: the picker's contents aren't known
/// at compile time. Google ships new models between KozBon
/// releases, and a hardcoded enum leaves users pinned to whatever
/// generation shipped with the binary.
///
/// Options come from two places — the live catalog
/// (``GeminiModelCatalog``, `GET /v1beta/models` with the user's
/// own key) and ``GeminiModel``, the small compiled-in list used as
/// the offline floor. ``isBuiltIn`` records which, so the UI can
/// hint that a list is a stale fallback.
public struct GeminiModelOption: Identifiable, Hashable, Sendable {

    /// The API model identifier, without the `models/` prefix the
    /// REST surface wraps names in. Also the value persisted in
    /// preferences.
    public let id: String

    /// Human-readable name for the picker row. For catalog-sourced
    /// options this is Google's own `displayName`, which is
    /// English-only — consistent with how KozBon treats every model
    /// name, since they're brand identifiers.
    public let displayName: String

    /// Whether this came from the compiled-in fallback rather than
    /// the live catalog.
    public let isBuiltIn: Bool

    public init(id: String, displayName: String, isBuiltIn: Bool) {
        self.id = id
        self.displayName = displayName
        self.isBuiltIn = isBuiltIn
    }

    /// Builds an option from a compiled-in fallback case.
    public init(builtIn model: GeminiModel) {
        self.init(id: model.rawValue, displayName: model.displayName, isBuiltIn: true)
    }

    /// The offline fallback list, most-capable-first to match the
    /// catalog's ordering convention.
    public static var builtInOptions: [GeminiModelOption] {
        GeminiModel.allCases.map(GeminiModelOption.init(builtIn:))
    }
}
