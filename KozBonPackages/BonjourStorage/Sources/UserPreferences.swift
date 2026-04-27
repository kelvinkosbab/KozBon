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

    /// Default value for ``persistChatHistory``.
    ///
    /// Defaults to `true` so a returning user's conversation is
    /// restored across launches without making them hunt for a
    /// toggle. Existing users who opted out keep their preference
    /// — SwiftData stores the chosen value, so the new default
    /// only applies to fresh installs.
    public static let defaultPersistChatHistory = true

    /// Hard ceiling on the number of messages saved to disk when
    /// ``persistChatHistory`` is enabled. The in-memory session is
    /// not trimmed — this only bounds the persisted blob so storage
    /// stays predictable across very long conversations.
    ///
    /// Sized to comfortably fit several dozen chat turns of mixed
    /// user/assistant content (each turn is roughly two messages).
    public static let maxStoredChatMessages: Int = 200

    /// Hard ceiling on the encoded byte size of the persisted chat
    /// history. Prevents pathological growth if a single assistant
    /// response is unusually long, and keeps the SwiftData blob
    /// well under platform sync limits (CloudKit's 1 MB per-record
    /// cap, in case persistence is ever moved off-device).
    public static let maxStoredChatBytes: Int = 1_048_576

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
    /// launches. When `true` (default), the most recent
    /// conversation is encoded into ``chatHistory`` on each turn
    /// and restored when the Chat tab next appears. When `false`,
    /// the chat resets when the app cold-launches.
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
