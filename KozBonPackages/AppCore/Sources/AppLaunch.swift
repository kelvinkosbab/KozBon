//
//  AppLaunch.swift
//  AppCore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourAI
import BonjourAIApple
import BonjourAICore
import BonjourAppIntents
import BonjourScanning
import BonjourStorage

// MARK: - AppLaunch

/// Builds the app's long-lived objects once per process.
///
/// Built from the app's initializer rather than the scene, because the
/// system can launch KozBon in the background to run a Siri action and
/// never build a scene. The scene then reuses the same view model.
@MainActor
enum AppLaunch {

    static let viewModel: AppCoreViewModel = {
        let credentialsStore = KeychainAICloudCredentialsStore()
        // ONE shared preferences store: the factories consult it
        // for routing and Settings writes through it. Separate
        // instances would each spin up their own SwiftData
        // container and writes wouldn't propagate.
        let preferencesStore = PreferencesStore()
        // Shared for the same reason: Settings and routing must agree
        // on which backends this storefront allows.
        let availability = AIBackendAvailability()
        let viewModel = AppCoreViewModel(
            dependencies: DependencyContainer(),
            explainerFactory: CloudAwareBonjourServiceExplainerFactory(
                credentialsStore: credentialsStore,
                preferencesStore: preferencesStore,
                isBackendOffered: { availability.isOffered($0) }
            ),
            chatSessionFactory: CloudAwareBonjourChatSessionFactory(
                credentialsStore: credentialsStore,
                preferencesStore: preferencesStore,
                isBackendOffered: { availability.isOffered($0) }
            ),
            credentialsStore: credentialsStore,
            preferencesStore: preferencesStore,
            aiBackendAvailability: availability
        )
        viewModel.connect(to: AppIntentsBridge.shared)
        return viewModel
    }()
}
