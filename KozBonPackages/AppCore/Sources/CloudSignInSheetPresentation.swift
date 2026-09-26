//
//  CloudSignInSheetPresentation.swift
//  AppCore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourAICore
import BonjourUI

// MARK: - CloudSignInSheetPresentation

/// Hosts the scene-level `AICloudSignInSheet` and the
/// notification bridge that drives it. Mounted on both the
/// modern (`TabView { Tab { ... } }`) and legacy
/// (`TabView { ... .tabItem }`) branches of `AppCoreScene.body`
/// so the Insights long-press menu's
/// ``Notification.Name/aiCloudSignInRequested`` reaches a sheet
/// presenter regardless of which OS branch is in play.
///
/// `credentialsStore == nil` is the test path (the in-memory
/// stub init); the sheet still wires up but writes are no-ops.
struct CloudSignInSheetPresentation: ViewModifier {

    @Binding var pendingProvider: AICloudProvider?
    let credentialsStore: (any AICloudCredentialsStore & Sendable)?

    func body(content: Content) -> some View {
        content
            .onReceive(
                NotificationCenter.default.publisher(for: .aiCloudSignInRequested)
            ) { note in
                guard let raw = note.userInfo?[aiCloudSignInRequestedProviderKey] as? String,
                      let provider = AICloudProvider(rawValue: raw) else { return }
                pendingProvider = provider
            }
            .sheet(item: $pendingProvider) { provider in
                if let credentialsStore {
                    AICloudSignInSheet(
                        credentialsStore: credentialsStore,
                        provider: provider
                    )
                }
            }
    }
}
