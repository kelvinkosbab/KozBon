//
//  UserPreferences.swift
//  BonjourStorage
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import SwiftData

// MARK: - UserPreferences

/// SwiftData model representing the user's persisted app preferences.
///
/// A single row is maintained in the database. The ``PreferencesStore``
/// fetches or creates this record on first access.
@Model
public final class UserPreferences {

    // MARK: - Defaults

    /// Default value for ``aiAnalysisEnabled``.
    public static let defaultAIAnalysisEnabled = true

    /// Default value for ``aiExpertiseLevel``.
    ///
    /// Matches `BonjourServicePromptBuilder.ExpertiseLevel.basic.rawValue`.
    public static let defaultAIExpertiseLevel = "basic"

    /// Default value for ``aiResponseLength``.
    ///
    /// Matches `BonjourServicePromptBuilder.ResponseLength.standard.rawValue`.
    public static let defaultAIResponseLength = "standard"

    /// Default value for ``defaultSortOrder``.
    public static let defaultSortOrder = ""

    /// Default value for ``aiBackendRawValue``.
    ///
    /// `"apple"` corresponds to `AIBackend.appleIntelligence` in
    /// the `BonjourAI` typed bridge. ADR 0005 requires this
    /// stay on-device — a fresh install never routes to cloud
    /// without an explicit user action.
    public static let defaultAIBackendRawValue = "apple"

    /// Default value for ``aiCloudModelRawValue``.
    ///
    /// `"claude-sonnet-4-5"` corresponds to `AnthropicModel.sonnet`
    /// in the `BonjourAI` typed bridge.
    public static let defaultAICloudModelRawValue = "claude-sonnet-4-5"

    /// Default value for ``aiGeminiModelRawValue``.
    ///
    /// `"gemini-2.5-flash"` corresponds to `GeminiModel.flash` in
    /// the `BonjourAIGemini` typed bridge.
    public static let defaultAIGeminiModelRawValue = "gemini-2.5-flash"

    // MARK: - Properties

    /// Whether AI-powered service explanations are enabled.
    public var aiAnalysisEnabled: Bool = defaultAIAnalysisEnabled

    /// The preferred expertise level for AI explanations (`"basic"` or `"technical"`).
    public var aiExpertiseLevel: String = defaultAIExpertiseLevel

    /// The preferred response length for AI explanations (`"brief"`, `"standard"`, or `"thorough"`).
    public var aiResponseLength: String = defaultAIResponseLength

    /// The default sort order ID for discovered services (empty string means no preference).
    public var defaultSortOrder: String = UserPreferences.defaultSortOrder

    /// The user's selected AI backend, stored as a raw string so
    /// SwiftData doesn't need to know about the `AIBackend` enum
    /// (which lives in `BonjourAI`).
    ///
    /// Use `PreferencesStore.aiBackend` from `BonjourAI` for
    /// the typed accessor. Direct reads of this raw string belong
    /// only inside `BonjourStorage` and migration code.
    public var aiBackendRawValue: String = UserPreferences.defaultAIBackendRawValue

    /// The user's selected **Claude** model identifier, stored as a
    /// raw string for the same reason as ``aiBackendRawValue``.
    ///
    /// Each cloud provider gets its own slot so switching between
    /// them and back preserves both choices — one shared field
    /// would hand Gemini a `claude-` identifier it can't use. The
    /// generic-sounding name predates the second provider; it is
    /// kept as-is because renaming a `@Model` property is a
    /// schema migration for no user-visible gain.
    ///
    /// Read it through
    /// `PreferencesStore.aiCloudModelIdentifier(for:)` in
    /// `BonjourAICore` rather than directly.
    public var aiCloudModelRawValue: String = UserPreferences.defaultAICloudModelRawValue

    /// The user's selected **Gemini** model identifier — the
    /// per-provider counterpart to ``aiCloudModelRawValue``.
    ///
    /// Additive, so existing rows decode with the default and no
    /// migration plan is required.
    public var aiGeminiModelRawValue: String = UserPreferences.defaultAIGeminiModelRawValue

    /// Creates a new preferences instance with default values.
    public init() {}
}
