//
//  AICloudEnvironment.swift
//  BonjourAICloud
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - Environment Values

public extension EnvironmentValues {

    /// The credentials store views read and write through to
    /// manage cloud-AI API keys.
    ///
    /// The production default is a real `KeychainAICloudCredentialsStore`
    /// — the iOS Keychain is the only place API keys ever live.
    /// Previews and tests inject an `InMemoryAICloudCredentialsStore`
    /// via ``View/aiCloudCredentialsStore(_:)`` so the simulator
    /// and CI don't pollute developer-machine Keychains.
    ///
    /// The default is created via `MainActor.assumeIsolated` for
    /// the same reason `preferencesStore` is: the `@Entry` macro
    /// generates a nonisolated default-value site, but SwiftUI
    /// always evaluates the default on the main thread in
    /// practice, so the explicit hop matches the runtime
    /// behavior without tripping the type system.
    @Entry var aiCloudCredentialsStore: any AICloudCredentialsStore =
        MainActor.assumeIsolated { KeychainAICloudCredentialsStore() }
}

// MARK: - View Extension

public extension View {

    /// Inject a custom credentials store into the view hierarchy.
    ///
    /// Previews use this to seed a signed-in state without
    /// touching the real Keychain; tests use it to assert against
    /// an `InMemoryAICloudCredentialsStore` they control.
    func aiCloudCredentialsStore(_ store: any AICloudCredentialsStore) -> some View {
        self.environment(\.aiCloudCredentialsStore, store)
    }
}
