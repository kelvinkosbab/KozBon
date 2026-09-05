//
//  AnthropicModelOption.swift
//  BonjourAIAnthropic
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - AnthropicModelOption

/// One selectable Claude model in the Settings picker.
///
/// Deliberately a struct rather than an enum: the picker's
/// contents are no longer known at compile time. Anthropic ships
/// new models between KozBon releases, and a hardcoded enum meant
/// the picker silently rotted — users were pinned to whatever
/// generation shipped with the binary until the next App Store
/// update.
///
/// Options come from two places:
///
/// - **The live catalog** (``AnthropicModelCatalog``), fetched
///   from `GET /v1/models` with the user's own API key. This is
///   the authoritative list and always reflects what the account
///   can actually call today.
/// - **``AnthropicModel``**, the small hardcoded enum, used as
///   the offline floor. KozBon is a local-network tool that is
///   routinely used with no internet at all, so the picker must
///   still render something usable when the catalog can't be
///   fetched.
///
/// ``isBuiltIn`` records which source an option came from so the
/// UI can hint that a list is a stale fallback rather than the
/// live catalog.
public struct AnthropicModelOption: Identifiable, Hashable, Sendable {

    /// The API model identifier sent as `model` in a request
    /// (e.g. `claude-opus-5`). Also the value persisted in
    /// preferences.
    public let id: String

    /// Human-readable name for the picker row (e.g.
    /// "Claude Opus 5").
    ///
    /// For catalog-sourced options this is Anthropic's own
    /// `display_name`, which is English-only. That's consistent
    /// with how KozBon already treats provider names — model
    /// names are brand identifiers, and the String Catalog marks
    /// the equivalent backend labels "do not translate".
    public let displayName: String

    /// Whether this option came from the hardcoded
    /// ``AnthropicModel`` fallback rather than the live catalog.
    public let isBuiltIn: Bool

    public init(id: String, displayName: String, isBuiltIn: Bool) {
        self.id = id
        self.displayName = displayName
        self.isBuiltIn = isBuiltIn
    }

    /// Builds an option from a hardcoded fallback case.
    public init(builtIn model: AnthropicModel) {
        self.init(id: model.rawValue, displayName: model.displayName, isBuiltIn: true)
    }

    /// The offline fallback list, newest-tier-first to match the
    /// catalog's ordering convention.
    public static var builtInOptions: [AnthropicModelOption] {
        AnthropicModel.allCases.map(AnthropicModelOption.init(builtIn:))
    }
}
