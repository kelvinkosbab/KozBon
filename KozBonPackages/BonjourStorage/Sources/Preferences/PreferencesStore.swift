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

    /// Retained to keep the `ModelContext` alive for the store's lifetime.
    private let container: ModelContainer?
    private let context: ModelContext?
    private var preferences: UserPreferences?

    // MARK: - Init

    /// Creates a preferences store backed by the default on-disk SwiftData container.
    ///
    /// Falls back to an in-memory container if the on-disk store cannot be created.
    /// If both on-disk and in-memory containers fail, the store operates with
    /// in-memory defaults that are not persisted.
    public init() {
        let logger = Logger(subsystem: "com.kozinga.KozBon", category: "BonjourStorage")
        var resolvedContainer: ModelContainer?

        do {
            resolvedContainer = try ModelContainer(for: UserPreferences.self)
        } catch {
            logger.error(
                "Failed to create on-disk ModelContainer: \(error.localizedDescription). Falling back to in-memory store."
            )
            do {
                let config = ModelConfiguration(isStoredInMemoryOnly: true)
                resolvedContainer = try ModelContainer(for: UserPreferences.self, configurations: config)
            } catch {
                logger.error(
                    "Failed to create in-memory ModelContainer: \(error.localizedDescription). Preferences will not persist."
                )
            }
        }

        self.container = resolvedContainer
        self.context = resolvedContainer?.mainContext
        self.preferences = resolvedContainer.flatMap { Self.fetchOrCreate(in: $0.mainContext) }
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
    ///
    /// When enabled, users can request AI-generated explanations of Bonjour services.
    /// This preference should be exposed with proper accessibility labels and hints
    /// to ensure users with disabilities can understand and control this feature.
    ///
    /// - Important: Consider announcing changes to this preference to VoiceOver users
    ///   when toggled in your UI.
    public var aiAnalysisEnabled: Bool {
        get { preferences?.aiAnalysisEnabled ?? UserPreferences.defaultAIAnalysisEnabled }
        set {
            preferences?.aiAnalysisEnabled = newValue
            save()
        }
    }

    /// The preferred expertise level for AI explanations (`"basic"` or `"technical"`).
    public var aiExpertiseLevel: String {
        get { preferences?.aiExpertiseLevel ?? UserPreferences.defaultAIExpertiseLevel }
        set {
            preferences?.aiExpertiseLevel = newValue
            save()
        }
    }

    /// The preferred response length for AI explanations (`"brief"`, `"standard"`, or `"thorough"`).
    public var aiResponseLength: String {
        get { preferences?.aiResponseLength ?? UserPreferences.defaultAIResponseLength }
        set {
            preferences?.aiResponseLength = newValue
            save()
        }
    }

    /// The default sort order ID for discovered services.
    ///
    /// An empty string means no preference (uses the default host name A→Z sort).
    public var defaultSortOrder: String {
        get { preferences?.defaultSortOrder ?? UserPreferences.defaultSortOrder }
        set {
            preferences?.defaultSortOrder = newValue
            save()
        }
    }

    // MARK: - Actions

    /// Resets all preferences to their default values.
    public func resetToDefaults() {
        preferences?.aiAnalysisEnabled = UserPreferences.defaultAIAnalysisEnabled
        preferences?.aiExpertiseLevel = UserPreferences.defaultAIExpertiseLevel
        preferences?.aiResponseLength = UserPreferences.defaultAIResponseLength
        preferences?.defaultSortOrder = UserPreferences.defaultSortOrder
        save()
    }

    // MARK: - Persistence

    private func save() {
        try? context?.save()
    }
}
