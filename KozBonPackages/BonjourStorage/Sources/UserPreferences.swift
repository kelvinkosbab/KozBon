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

    // MARK: - Properties

    /// Whether AI-powered service explanations are enabled.
    public var aiAnalysisEnabled: Bool = defaultAIAnalysisEnabled

    /// The preferred expertise level for AI explanations (`"basic"` or `"technical"`).
    public var aiExpertiseLevel: String = defaultAIExpertiseLevel

    /// The preferred response length for AI explanations (`"brief"`, `"standard"`, or `"thorough"`).
    public var aiResponseLength: String = defaultAIResponseLength

    /// The default sort order ID for discovered services (empty string means no preference).
    public var defaultSortOrder: String = UserPreferences.defaultSortOrder

    /// Creates a new preferences instance with default values.
    public init() {}
}
