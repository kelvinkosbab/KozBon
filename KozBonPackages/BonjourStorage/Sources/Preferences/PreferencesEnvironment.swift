//
//  PreferencesEnvironment.swift
//  BonjourStorage
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - Default Store

extension PreferencesStore {

    /// Backs `EnvironmentValues.preferencesStore` when nothing has
    /// been injected.
    ///
    /// Allocated once here instead of inline at the `@Entry`
    /// declaration: that default-value site is re-evaluated on every
    /// read, so building a store there hands out a fresh object each
    /// time and invalidates every view reading the environment.
    ///
    /// `nonisolated` so the generated default-value site — which the
    /// macro emits in a nonisolated context — can reference it
    /// directly. The `assumeIsolated` hop covers the main-actor-
    /// isolated `init`; SwiftUI always resolves environment defaults
    /// on the main actor, so the runtime check never trips.
    nonisolated static let environmentDefault = MainActor.assumeIsolated {
        PreferencesStore()
    }
}

// MARK: - Environment Values

public extension EnvironmentValues {
    /// The app's preferences store, accessible via `@Environment(\.preferencesStore)`.
    @Entry var preferencesStore: PreferencesStore = .environmentDefault
}

// MARK: - View Extension

public extension View {
    /// Inject a custom preferences store into the view hierarchy.
    func preferencesStore(_ store: PreferencesStore) -> some View {
        self.environment(\.preferencesStore, store)
    }
}
