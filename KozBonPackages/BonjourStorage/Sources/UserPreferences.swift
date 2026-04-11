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

    /// Whether AI-powered service explanations are enabled.
    public var aiAnalysisEnabled: Bool = true

    /// The preferred expertise level for AI explanations (`"beginner"` or `"technical"`).
    public var aiExpertiseLevel: String = "beginner"

    /// The default sort order ID for discovered services (empty string means no preference).
    public var defaultSortOrder: String = ""

    /// Creates a new preferences instance with default values.
    public init() {}
}
