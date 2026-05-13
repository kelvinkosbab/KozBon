//
//  AnthropicModel.swift
//  BonjourAICloud
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - AnthropicModel

/// The Claude models KozBon's Settings UI lets the user choose
/// between.
///
/// Stored in user preferences via ``rawValue`` (a stable API
/// identifier), surfaced to users via ``displayName`` and
/// ``shortDescription`` (both localizable in the UI layer; the
/// strings here are English fallbacks for log output and tests).
///
/// The enum is intentionally small — three named tiers covering
/// the common quality-vs-latency trade-off — rather than a
/// free-form string. When Anthropic publishes a new generation,
/// the cases are updated and any persisted preference that
/// references a retired identifier falls back to ``defaultModel``.
public enum AnthropicModel: String, Sendable, CaseIterable, Codable, Identifiable {

    /// The most capable Claude model. Slowest first-token latency
    /// and highest per-token cost; appropriate for users who care
    /// more about answer quality than response speed.
    case opus = "claude-opus-4-5"

    /// The balanced default. Strong reasoning, lower cost per
    /// token than Opus, faster first-token latency. The model the
    /// Settings UI picks for users who haven't explicitly chosen.
    case sonnet = "claude-sonnet-4-5"

    /// The fastest, cheapest tier. Lower reasoning depth but
    /// great for short, structured answers (per-service Insights,
    /// the long-press explainer).
    case haiku = "claude-haiku-4-5"

    // MARK: - Identifiable

    public var id: String { rawValue }

    // MARK: - Defaults

    /// The model used when the user hasn't explicitly picked one.
    ///
    /// `sonnet` is the right default for KozBon's mix of "explain
    /// this service in two sentences" (short, easy) and "what
    /// devices are on my network?" (multi-turn reasoning).
    public static let `default`: AnthropicModel = .sonnet

    /// Returns the model matching the given identifier, or
    /// ``default`` when the identifier doesn't match a known case.
    ///
    /// Used by preference deserialization to gracefully handle
    /// retired model identifiers. A user who persisted
    /// `claude-opus-4-1` (hypothetical retirement) reads back as
    /// the current default rather than a `nil` that the UI would
    /// have to special-case.
    public static func resolved(rawValue: String?) -> AnthropicModel {
        guard let rawValue, let model = AnthropicModel(rawValue: rawValue) else {
            return .default
        }
        return model
    }

    // MARK: - Version

    /// Marketing version of the model (e.g. `"4.5"`).
    ///
    /// Separate from ``rawValue`` (which carries the dash-cased
    /// API identifier `claude-opus-4-5`) so the UI can surface a
    /// human-readable version next to the model name without
    /// parsing the API identifier — and so the source of truth
    /// for "which Claude generation does KozBon currently
    /// support" lives in exactly one place. When Anthropic ships
    /// `4.6` (or whatever), bumping the version is a one-line
    /// edit here plus the matching ``rawValue`` change.
    public var version: String {
        switch self {
        case .opus, .sonnet, .haiku:
            return "4.5"
        }
    }

    // MARK: - Display

    /// English display name used in logs and tests, including the
    /// marketing version. The UI layer localizes via
    /// `Strings.Settings.aiCloudModelOpus` / `…Sonnet` / `…Haiku`,
    /// which encode the same name + version pair through the
    /// String Catalog so translators don't have to manage version
    /// numbers across locales.
    public var displayName: String {
        switch self {
        case .opus:   return "Claude Opus \(version)"
        case .sonnet: return "Claude Sonnet \(version)"
        case .haiku:  return "Claude Haiku \(version)"
        }
    }

    /// English one-line summary used in logs and tests. The UI
    /// layer localizes via the Strings facade.
    public var shortDescription: String {
        switch self {
        case .opus:   return "Most capable, slowest, highest cost."
        case .sonnet: return "Balanced — recommended for most users."
        case .haiku:  return "Fastest, lowest cost, for short answers."
        }
    }
}
