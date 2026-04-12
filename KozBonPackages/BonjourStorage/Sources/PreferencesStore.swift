//
//  PreferencesStore.swift
//  BonjourStorage
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import OSLog
import SwiftData

// MARK: - PreferencesStore

/// Centralized, observable store for user preferences backed by SwiftData.
///
/// Manages a single ``UserPreferences`` row in a local SwiftData container.
/// All property mutations are automatically persisted.
///
/// ```swift
/// // Read a preference
/// if preferencesStore.aiAnalysisEnabled { ... }
///
/// // Write a preference (auto-saved)
/// preferencesStore.defaultSortOrder = "hostNameAsc"
///
/// // Reset everything
/// preferencesStore.resetToDefaults()
/// ```
@MainActor
@Observable
public final class PreferencesStore {

    // MARK: - Storage

    private let container: ModelContainer
    private let context: ModelContext
    private var preferences: UserPreferences

    // MARK: - Init

    /// Creates a preferences store backed by the default on-disk SwiftData container.
    ///
    /// Falls back to an in-memory container if the on-disk store cannot be created
    /// (e.g. due to disk permission or corruption issues).
    public init() {
        let container: ModelContainer
        do {
            container = try ModelContainer(for: UserPreferences.self)
        } catch {
            let logger = Logger(subsystem: "com.kozinga.KozBon", category: "BonjourStorage")
            logger.error(
                "Failed to create on-disk ModelContainer: \(error.localizedDescription). Falling back to in-memory store."
            )
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            // In-memory containers should never fail to initialize.
            // swiftlint:disable:next force_try
            container = try! ModelContainer(for: UserPreferences.self, configurations: config)
        }
        self.container = container
        self.context = container.mainContext
        self.preferences = Self.fetchOrCreate(in: container.mainContext)
    }

    /// Creates a preferences store with a custom container (useful for testing).
    ///
    /// - Parameter container: A pre-configured `ModelContainer`.
    public init(container: ModelContainer) {
        self.container = container
        self.context = container.mainContext
        self.preferences = Self.fetchOrCreate(in: container.mainContext)
    }

    // MARK: - Fetch or Create

    private static func fetchOrCreate(in context: ModelContext) -> UserPreferences {
        let descriptor = FetchDescriptor<UserPreferences>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let prefs = UserPreferences()
        context.insert(prefs)
        try? context.save()
        return prefs
    }

    // MARK: - Preferences

    /// Whether AI-powered service explanations are enabled.
    public var aiAnalysisEnabled: Bool {
        get { preferences.aiAnalysisEnabled }
        set {
            preferences.aiAnalysisEnabled = newValue
            save()
        }
    }

    /// The preferred expertise level for AI explanations (`"basic"` or `"technical"`).
    public var aiExpertiseLevel: String {
        get { preferences.aiExpertiseLevel }
        set {
            preferences.aiExpertiseLevel = newValue
            save()
        }
    }

    /// The default sort order ID for discovered services.
    ///
    /// An empty string means no preference (uses the default host name A→Z sort).
    public var defaultSortOrder: String {
        get { preferences.defaultSortOrder }
        set {
            preferences.defaultSortOrder = newValue
            save()
        }
    }

    // MARK: - Actions

    /// Resets all preferences to their default values.
    public func resetToDefaults() {
        preferences.aiAnalysisEnabled = UserPreferences.defaultAIAnalysisEnabled
        preferences.aiExpertiseLevel = UserPreferences.defaultAIExpertiseLevel
        preferences.defaultSortOrder = UserPreferences.defaultSortOrder
        save()
    }

    // MARK: - Persistence

    private func save() {
        try? context.save()
    }
}
