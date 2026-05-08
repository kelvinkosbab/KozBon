//
//  PreferencesEnvironment.swift
//  BonjourStorage
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - Environment Values

public extension EnvironmentValues {
    /// The app's preferences store, accessible via `@Environment(\.preferencesStore)`.
    ///
    /// The default uses `MainActor.assumeIsolated` because
    /// `PreferencesStore.init` is main-actor-isolated and the
    /// `@Entry` macro generates the default-value site in a
    /// nonisolated context. SwiftUI always evaluates environment
    /// values on the main actor in practice, so the runtime check
    /// never trips — but the type system can't see that, hence
    /// the explicit hop.
    @Entry var preferencesStore: PreferencesStore = MainActor.assumeIsolated { PreferencesStore() }
}

// MARK: - View Extension

public extension View {
    /// Inject a custom preferences store into the view hierarchy.
    func preferencesStore(_ store: PreferencesStore) -> some View {
        self.environment(\.preferencesStore, store)
    }
}
