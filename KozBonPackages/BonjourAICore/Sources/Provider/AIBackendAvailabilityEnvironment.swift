//
//  AIBackendAvailabilityEnvironment.swift
//  BonjourAICore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - Default Instance

extension AIBackendAvailability {

    /// Backs `EnvironmentValues.aiBackendAvailability` when nothing
    /// has been injected: no storefront, so every backend is
    /// offered.
    ///
    /// Allocated once rather than at the `@Entry` site, which is
    /// re-evaluated on every read. `assumeIsolated` covers the
    /// main-actor `init` from the macro's nonisolated default site;
    /// SwiftUI resolves environment defaults on the main actor.
    nonisolated static let environmentDefault = MainActor.assumeIsolated {
        AIBackendAvailability()
    }
}

// MARK: - Environment Values

public extension EnvironmentValues {

    /// The storefront-driven set of AI backends the app may offer.
    @Entry var aiBackendAvailability: AIBackendAvailability = .environmentDefault
}
