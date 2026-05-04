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

// MARK: - BonjourChatSessionFactory

/// Picks the `BonjourChatSessionProtocol` implementation
/// appropriate for the current build environment.
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
/// Mirrors ``BonjourServiceExplainerFactory`` — same rationale
/// for living in `BonjourAI` rather than the app target.
public enum BonjourChatSessionFactory {

    /// Returns the session for the current build environment, or
    /// `nil` if the device can't run on-device AI.
    ///
    /// The publish manager is held weakly by the real session, so
    /// the factory's argument doesn't extend its lifetime.
    @MainActor
    public static func makeForCurrentEnvironment(
        publishManager: BonjourPublishManagerProtocol
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

    /// Eagerly compiles the chat session's system instructions so
    /// the user's first interaction with the chat tab doesn't pay
    /// the model-load cost. No-ops when AI isn't available on this
    /// device, when the user has turned AI features off, or when
    /// the caller passed a nil session — prewarming a chat tab
    /// that won't surface would just waste CPU and battery.
    ///
    /// Yields once before doing the work so the first frame paints
    /// (the rest of the tab content) before we hand main back to the
    /// model for instruction compilation. Without the yield the model
    /// load lands inside the app's launch path and the splash-to-
    /// first-frame transition stutters.
    ///
    /// - Parameters:
    ///   - session: The session returned by
    ///     ``makeForCurrentEnvironment(publishManager:)``, or `nil`
    ///     on devices that don't support on-device AI.
    ///   - aiAnalysisEnabled: The user's "AI features" preference
    ///     value, read from the app's preferences store. Forwarded
    ///     in by the View so the factory stays free of any
    ///     SwiftUI-environment dependencies.
    @MainActor
    public static func prewarmIfEnabled(
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
