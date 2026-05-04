//
//  BonjourServiceExplainerFactory.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - BonjourServiceExplainerFactory

/// Picks the `BonjourServiceExplainerProtocol` implementation
/// appropriate for the current build environment.
///
/// - **Simulator builds** → ``SimulatorBonjourServiceExplainer``,
///   which streams lorem ipsum so the Insights UI can be exercised
///   end-to-end without on-device model hardware.
/// - **iOS 26 / macOS 26 / visionOS 26 on devices** that can
///   `import FoundationModels` → the real ``BonjourServiceExplainer``.
/// - **Anything else** (older OS / no FoundationModels) → `nil`,
///   which the app's environment plumbing treats as "Insights
///   unavailable" so the long-press menu silently omits the action.
///
/// Lives in `BonjourAI` rather than the app target because the
/// platform / availability gates are an `BonjourAI` concern —
/// the module owns both impls and can decide which one to hand
/// out. Callers (the app, tests, future surfaces) just ask for
/// "the explainer for this environment" and get back the right
/// one.
public enum BonjourServiceExplainerFactory {

    /// Returns the explainer for the current build environment, or
    /// `nil` if the device can't run on-device AI.
    @MainActor
    public static func makeForCurrentEnvironment() -> (any BonjourServiceExplainerProtocol)? {
        #if targetEnvironment(simulator)
        return SimulatorBonjourServiceExplainer()
        #elseif canImport(FoundationModels)
        if #available(iOS 26, macOS 26, visionOS 26, *) {
            return BonjourServiceExplainer()
        }
        return nil
        #else
        return nil
        #endif
    }
}
