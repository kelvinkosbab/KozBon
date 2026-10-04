//
//  OpenAIModel.swift
//  BonjourAIOpenAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourAICore

// MARK: - OpenAIModel

/// The OpenAI models compiled into the binary as an offline floor.
///
/// Mirrors ``GeminiModel``'s role: the Settings picker is driven by
/// the live catalog (``OpenAIModelCatalog``), and this enum is only
/// what the picker falls back to when the catalog can't be fetched.
/// KozBon is a local-network tool routinely used with no internet
/// at all, so the picker must still render something usable
/// offline.
public enum OpenAIModel: String, Sendable, CaseIterable, Codable, Identifiable {

    /// The most capable tier. Deepest reasoning, slowest first
    /// token, highest cost per token.
    case flagship = "gpt-6-astra"

    /// The balanced default — fast and inexpensive enough for
    /// KozBon's mix of short service explanations and multi-turn
    /// network questions.
    case mini = "gpt-5.4-mini"

    /// The cheapest, fastest tier, well suited to the long-press
    /// Insights explainer.
    case nano = "gpt-5.4-nano"

    // MARK: - Identifiable

    public var id: String { rawValue }

    // MARK: - Defaults

    /// The model used when the user hasn't explicitly picked one.
    ///
    /// Must agree with
    /// ``AICloudProvider/defaultModelIdentifier`` for `.openai` —
    /// `OpenAIModelTests` enforces that, since the two live in
    /// different modules and would otherwise drift.
    public static let `default`: OpenAIModel = .mini

    /// Returns the model matching the given identifier, or
    /// ``default`` when it doesn't match a known case.
    public static func resolved(rawValue: String?) -> OpenAIModel {
        guard let rawValue, let model = OpenAIModel(rawValue: rawValue) else {
            return .default
        }
        return model
    }

    // MARK: - Display

    /// English display name used in logs, tests, and the offline
    /// picker. Model names are brand identifiers, so they aren't
    /// translated — the same treatment the backend labels get.
    public var displayName: String {
        OpenAIModelOption.displayName(forIdentifier: rawValue)
    }

    /// English one-line summary used in logs and tests.
    public var shortDescription: String {
        switch self {
        case .flagship: return "Most capable, slowest, highest cost."
        case .mini:     return "Balanced — recommended for most users."
        case .nano:     return "Fastest, lowest cost, for short answers."
        }
    }
}
