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

// MARK: - BonjourServiceExplainerFactoryProtocol

/// Abstraction over the choice of
/// `BonjourServiceExplainerProtocol` implementation for the
/// current build environment.
///
/// Defined as a protocol so consumers (`AppCore`, future
/// surfaces) can inject the factory rather than reach into a
/// static namespace. Production uses
/// ``BonjourServiceExplainerFactory``; tests substitute a mock.
public protocol BonjourServiceExplainerFactoryProtocol: Sendable {

    /// Returns the explainer for the current build environment,
    /// or `nil` if the device can't run on-device AI.
    @MainActor
    func makeForCurrentEnvironment() -> (any BonjourServiceExplainerProtocol)?
}

// MARK: - BonjourServiceExplainerFactory

/// Production implementation of
/// ``BonjourServiceExplainerFactoryProtocol``.
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
/// Stateless — see the matching note on
/// ``BonjourChatSessionFactory`` for why the type is a struct
/// rather than a static enum namespace.
public struct BonjourServiceExplainerFactory: BonjourServiceExplainerFactoryProtocol {

    public init() {}

    @MainActor
    public func makeForCurrentEnvironment() -> (any BonjourServiceExplainerProtocol)? {
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
