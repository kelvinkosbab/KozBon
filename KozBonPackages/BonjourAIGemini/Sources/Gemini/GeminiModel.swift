//
//  GeminiModel.swift
//  BonjourAIGemini
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourAICore

// MARK: - GeminiModel

/// The Gemini models compiled into the binary as an offline floor.
///
/// Mirrors ``AnthropicModel``'s role: the Settings picker is driven
/// by the live catalog (``GeminiModelCatalog``), and this enum is
/// only what the picker falls back to when the catalog can't be
/// fetched. KozBon is a local-network tool routinely used with no
/// internet at all, so the picker must still render something
/// usable offline.
///
/// Persisted via ``rawValue`` — the identifier the API expects in
/// the URL path, without the `models/` prefix the REST surface
/// wraps it in.
public enum GeminiModel: String, Sendable, CaseIterable, Codable, Identifiable {

    /// The most capable tier. Deepest reasoning, slowest first
    /// token, highest cost per token.
    case pro = "gemini-2.5-pro"

    /// The balanced default — the tier Google positions for
    /// general use, and the right fit for KozBon's mix of short
    /// service explanations and multi-turn network questions.
    case flash = "gemini-2.5-flash"

    /// The cheapest, fastest tier. Shallower reasoning, well
    /// suited to the long-press Insights explainer.
    case flashLite = "gemini-2.5-flash-lite"

    // MARK: - Identifiable

    public var id: String { rawValue }

    // MARK: - Defaults

    /// The model used when the user hasn't explicitly picked one.
    ///
    /// Must agree with
    /// ``AICloudProvider/defaultModelIdentifier`` for `.gemini` —
    /// `GeminiModelTests` enforces that, since the two live in
    /// different modules and would otherwise drift.
    public static let `default`: GeminiModel = .flash

    /// Returns the model matching the given identifier, or
    /// ``default`` when it doesn't match a known case.
    public static func resolved(rawValue: String?) -> GeminiModel {
        guard let rawValue, let model = GeminiModel(rawValue: rawValue) else {
            return .default
        }
        return model
    }

    // MARK: - Display

    /// English display name used in logs, tests, and the offline
    /// picker. Model names are brand identifiers, so they aren't
    /// translated — the same treatment the backend labels get.
    public var displayName: String {
        switch self {
        case .pro:       return "Gemini 2.5 Pro"
        case .flash:     return "Gemini 2.5 Flash"
        case .flashLite: return "Gemini 2.5 Flash-Lite"
        }
    }

    /// English one-line summary used in logs and tests.
    public var shortDescription: String {
        switch self {
        case .pro:       return "Most capable, slowest, highest cost."
        case .flash:     return "Balanced — recommended for most users."
        case .flashLite: return "Fastest, lowest cost, for short answers."
        }
    }
}
