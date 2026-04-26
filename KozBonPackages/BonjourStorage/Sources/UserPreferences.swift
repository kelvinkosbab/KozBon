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

    /// Default value for ``persistChatHistory``. Off by default so the
    /// existing "fresh slate per launch" behavior is preserved for
    /// users who liked it; opting in is one toggle in Preferences.
    public static let defaultPersistChatHistory = false

    // MARK: - Properties

    /// Whether AI-powered service explanations are enabled.
    public var aiAnalysisEnabled: Bool = defaultAIAnalysisEnabled

    /// The preferred expertise level for AI explanations (`"basic"` or `"technical"`).
    public var aiExpertiseLevel: String = defaultAIExpertiseLevel

    /// The preferred response length for AI explanations (`"brief"`, `"standard"`, or `"thorough"`).
    public var aiResponseLength: String = defaultAIResponseLength

    /// The default sort order ID for discovered services (empty string means no preference).
    public var defaultSortOrder: String = UserPreferences.defaultSortOrder

    /// Whether the Chat conversation should be restored across app
    /// launches. When `false` (default), the chat resets when iOS
    /// reclaims the app from memory — matching the original
    /// fresh-slate behavior. When `true`, the most recent
    /// conversation is encoded into ``chatHistory`` on each turn
    /// and restored when the Chat tab next appears.
    public var persistChatHistory: Bool = defaultPersistChatHistory

    /// JSON-encoded `[BonjourChatMessage]` representing the user's
    /// last conversation, or `nil` if no history is saved.
    /// Persisted only when ``persistChatHistory`` is `true`. The
    /// value is `Data?` rather than `String?` so SwiftData stores
    /// it efficiently as a binary blob; encode/decode happens at
    /// the call site.
    public var chatHistory: Data?

    /// Creates a new preferences instance with default values.
    public init() {}
}
