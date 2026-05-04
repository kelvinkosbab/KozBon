//
//  BonjourChatSessionFactory.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourScanning

#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - BonjourChatSessionFactoryProtocol

/// Abstraction over the choice of `BonjourChatSessionProtocol`
/// implementation for the current build environment.
///
/// Defined as a protocol — rather than just exposing the
/// production type's static methods directly — so that
/// `AppCore` (and any future consumer that wires a chat surface)
/// receives the factory as an injected dependency instead of
/// reaching into a static namespace. Production code uses
/// ``BonjourChatSessionFactory``; tests can substitute a mock
/// that returns a stub session and tracks `prewarmIfEnabled`
/// calls.
public protocol BonjourChatSessionFactoryProtocol: Sendable {

    /// Returns the chat session for the current build
    /// environment, or `nil` if the device can't run on-device
    /// AI.
    @MainActor
    func makeForCurrentEnvironment(
        publishManager: any BonjourPublishManagerProtocol
    ) -> (any BonjourChatSessionProtocol)?

    /// Eagerly compiles the session's system instructions so
    /// the user's first interaction with the chat tab doesn't
    /// pay the model-load cost. No-ops when AI isn't available,
    /// when the user has turned AI features off, or when the
    /// caller passed a nil session.
    @MainActor
    func prewarmIfEnabled(
        session: (any BonjourChatSessionProtocol)?,
        aiAnalysisEnabled: Bool
    ) async
}

// MARK: - BonjourChatSessionFactory

/// Production implementation of ``BonjourChatSessionFactoryProtocol``.
///
/// - **Simulator builds** → ``SimulatorBonjourChatSession``,
///   which streams lorem ipsum so the chat UI can be exercised
///   end-to-end without on-device model hardware.
/// - **iOS 26 / macOS 26 / visionOS 26 on devices** that can
///   `import FoundationModels` → the real ``BonjourChatSession``.
/// - **Anything else** → `nil`, which the app's environment
///   plumbing treats as "chat unavailable" so the chat tab
///   doesn't surface.
///
/// The struct holds no state — it's a stateless namespace that
/// happens to be an instance type so consumers can inject it as
/// a dependency. A single shared instance is fine for the whole
/// app's lifetime; the production default in AppCore creates
/// one and never replaces it.
public struct BonjourChatSessionFactory: BonjourChatSessionFactoryProtocol {

    public init() {}

    @MainActor
    public func makeForCurrentEnvironment(
        publishManager: any BonjourPublishManagerProtocol
    ) -> (any BonjourChatSessionProtocol)? {
        #if targetEnvironment(simulator)
        return SimulatorBonjourChatSession()
        #elseif canImport(FoundationModels)
        if #available(iOS 26, macOS 26, visionOS 26, *) {
            return BonjourChatSession(publishManager: publishManager)
        }
        return nil
        #else
        return nil
        #endif
    }

    /// Yields once before doing the work so the first frame
    /// paints (the rest of the tab content) before we hand main
    /// back to the model for instruction compilation. Without
    /// the yield the model load lands inside the app's launch
    /// path and the splash-to-first-frame transition stutters.
    @MainActor
    public func prewarmIfEnabled(
        session: (any BonjourChatSessionProtocol)?,
        aiAnalysisEnabled: Bool
    ) async {
        guard AppleIntelligenceSupport.isDeviceSupported,
              aiAnalysisEnabled,
              let session else { return }
        await Task.yield()
        session.prewarm()
    }
}
