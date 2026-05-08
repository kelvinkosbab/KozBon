//
//  PreferencesEnvironment.swift
//  BonjourStorage
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - Environment Key

private struct PreferencesStoreKey: @preconcurrency EnvironmentKey {
    @MainActor static let defaultValue = PreferencesStore()
}

public extension EnvironmentValues {
    /// The app's preferences store, accessible via `@Environment(\.preferencesStore)`.
    var preferencesStore: PreferencesStore {
        get { self[PreferencesStoreKey.self] }
        set { self[PreferencesStoreKey.self] = newValue }
    }
}

// MARK: - View Extension

public extension View {
    /// Inject a custom preferences store into the view hierarchy.
    func preferencesStore(_ store: PreferencesStore) -> some View {
        self.environment(\.preferencesStore, store)
    }
}
