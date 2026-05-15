//
//  AIBackend.swift
//  BonjourAICore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourLocalization
import BonjourStorage

// MARK: - AIBackend

/// The backend the user has selected for KozBon's AI features.
///
/// Surfaces the choice ADR 0005 introduced: on-device Apple
/// Foundation Models (the default and the privacy-preserving
/// option) vs a user-supplied cloud provider. New cloud providers
/// added in the future get a new case here.
///
/// Persisted via `UserPreferences.aiBackend` as the raw string,
/// so a future OS that doesn't recognize a stored value
/// (downgrade, retired provider) gracefully falls back to
/// ``default`` via ``resolved(rawValue:)``.
public enum AIBackend: String, Sendable, CaseIterable, Codable, Identifiable {

    /// Apple Foundation Models running on-device. The default —
    /// no setup required for users on capable hardware, and the
    /// only path where no data leaves the device.
    case appleIntelligence = "apple"

    /// Anthropic Claude via the user's own API key. Opt-in;
    /// requires the user to paste a key from `console.anthropic.com`.
    case anthropic

    // MARK: - Identifiable

    public var id: String { rawValue }

    // MARK: - Defaults

    /// The backend a fresh install uses.
    ///
    /// ADR 0005 requires this stays Apple Foundation Models —
    /// switching to cloud is a deliberate user action, never a
    /// default.
    public static let `default`: AIBackend = .appleIntelligence

    /// Returns the backend matching the given raw value, falling
    /// back to ``default`` for unrecognized values (retired
    /// providers, schema drift).
    public static func resolved(rawValue: String?) -> AIBackend {
        guard let rawValue, let backend = AIBackend(rawValue: rawValue) else {
            return .default
        }
        return backend
    }

    // MARK: - Classification

    /// Whether this backend routes requests over the network.
    ///
    /// The Settings UI uses this to swap the privacy footer
    /// between "everything runs privately on your device" and
    /// "your questions are sent to <provider>". The chat tab's
    /// viability check uses it the other way — even if the
    /// device can't run Apple Intelligence, a configured cloud
    /// backend keeps the tab visible.
    public var isCloud: Bool {
        switch self {
        case .appleIntelligence:
            return false
        case .anthropic:
            return true
        }
    }

    /// The cloud provider this backend corresponds to, or `nil`
    /// for the on-device case.
    ///
    /// Lets call sites that need to ask "is a key configured for
    /// the currently-selected backend?" do one credentials-store
    /// lookup instead of pattern-matching every case.
    public var cloudProvider: AICloudProvider? {
        switch self {
        case .appleIntelligence:
            return nil
        case .anthropic:
            return .anthropic
        }
    }

    // MARK: - Localized Display

    /// Localized user-facing name for this backend. Used by the
    /// Settings picker.
    public var displayName: LocalizedStringResource {
        switch self {
        case .appleIntelligence:
            return Strings.Settings.aiBackendApple
        case .anthropic:
            return Strings.Settings.aiBackendAnthropic
        }
    }

    /// Localized one-line description shown under the picker
    /// option. Captures the privacy / setup posture so users can
    /// compare options without expanding the row.
    public var displaySubtitle: LocalizedStringResource {
        switch self {
        case .appleIntelligence:
            return Strings.Settings.aiBackendAppleSubtitle
        case .anthropic:
            return Strings.Settings.aiBackendAnthropicSubtitle
        }
    }
}

// MARK: - PreferencesStore Bridge

public extension PreferencesStore {

    /// The user's currently-selected AI backend, as a typed enum.
    ///
    /// Backed by `aiBackendRawValue` (a `String` on the SwiftData
    /// model). Reading the typed value goes through
    /// ``AIBackend/resolved(rawValue:)`` so retired or
    /// unrecognized stored values gracefully fall back to
    /// ``AIBackend/default``. Writing the typed value persists
    /// `rawValue` underneath.
    var aiBackend: AIBackend {
        get { AIBackend.resolved(rawValue: aiBackendRawValue) }
        set { aiBackendRawValue = newValue.rawValue }
    }
}

// The typed `PreferencesStore.aiCloudModel` bridge for
// ``AnthropicModel`` lives in `BonjourAIAnthropic` so this module
// stays provider-agnostic.
