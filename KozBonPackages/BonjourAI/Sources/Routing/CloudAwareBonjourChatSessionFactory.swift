//
//  CloudAwareBonjourChatSessionFactory.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import OSLog
import BonjourAICore
import BonjourAIApple
import BonjourAIAnthropic
import BonjourScanning
import BonjourStorage

// MARK: - Logger

private let routingLogger = os.Logger(
    subsystem: "com.kozinga.KozBon",
    category: "CloudAwareBonjourChatSessionFactory"
)

// MARK: - CloudAwareBonjourChatSessionFactory

/// Cloud-aware ``BonjourChatSessionFactoryProtocol`` that picks
/// between the on-device Apple Foundation Models session and the
/// Anthropic Claude session based on the user's current
/// preferences.
///
/// Sits on top of the existing
/// ``BonjourChatSessionFactory`` (which knows how to build the
/// Apple-side session) rather than reaching into the
/// FoundationModels-gated implementation directly. This keeps
/// the simulator / iOS-version branching localized to one place
/// (the inner factory) and lets the cloud-aware layer focus on
/// the routing decision.
///
/// Routing rules:
///
/// - **`.appleIntelligence`** — call through to the inner Apple
///   factory. Returns `nil` on hardware that can't run
///   FoundationModels; falls through to the cloud path when
///   Anthropic credentials are configured (so users on
///   ineligible hardware can still get a Chat tab via Claude).
/// - **`.anthropic`** — read the Anthropic key from the
///   credentials store; if present, return an
///   ``AnthropicBonjourChatSession``. If no key, fall back to the
///   Apple session (so the tab doesn't disappear when the user
///   selects cloud but hasn't signed in yet).
/// - **Neither available** — return `nil`, matching the legacy
///   contract that hides the Chat tab.
///
/// Pre-warming is delegated to the active backend's own
/// `prewarm()` method: for the Anthropic path that just builds
/// the cached system block, for the Apple path it compiles the
/// `LanguageModelSession` instructions.
public struct CloudAwareBonjourChatSessionFactory: BonjourChatSessionFactoryProtocol {

    // MARK: - Long-Lived Dependencies

    private let appleFactory: any BonjourChatSessionFactoryProtocol
    private let credentialsStore: any AICloudCredentialsStore & Sendable
    private let preferencesStore: PreferencesStore
    private let client: any AnthropicClientProtocol

    // MARK: - Init

    /// - Parameters:
    ///   - appleFactory: The inner factory that produces the
    ///     on-device session. Defaults to the production
    ///     ``BonjourAI.BonjourChatSessionFactory``; tests inject
    ///     a mock.
    ///   - credentialsStore: Where to read the Anthropic API key
    ///     from. Defaults to the Keychain-backed store; tests
    ///     pass an `InMemoryAICloudCredentialsStore`.
    ///   - preferencesStore: Source of `aiBackend` and
    ///     `aiCloudModel` selection. Read fresh on every
    ///     `makeForCurrentEnvironment(...)` call so the routing
    ///     reflects any preference change between app launches.
    ///   - client: The Anthropic API client used when routing
    ///     hits the cloud path. Defaults to a real
    ///     ``AnthropicClient`` against `api.anthropic.com`.
    public init(
        appleFactory: any BonjourChatSessionFactoryProtocol = BonjourChatSessionFactory(),
        credentialsStore: any AICloudCredentialsStore & Sendable,
        preferencesStore: PreferencesStore,
        client: any AnthropicClientProtocol = AnthropicClient()
    ) {
        self.appleFactory = appleFactory
        self.credentialsStore = credentialsStore
        self.preferencesStore = preferencesStore
        self.client = client
    }

    // MARK: - BonjourChatSessionFactoryProtocol

    @MainActor
    public func makeForCurrentEnvironment(
        publishManager: any BonjourPublishManagerProtocol
    ) -> (any BonjourChatSessionProtocol)? {
        let appleSession = appleFactory.makeForCurrentEnvironment(publishManager: publishManager)
        let backend = preferencesStore.aiBackend

        switch backend {
        case .appleIntelligence:
            // User picked on-device. Honor that choice; if the
            // device can't actually run it, fall back to cloud
            // when credentials are configured so the surface
            // doesn't vanish.
            if appleSession != nil {
                return appleSession
            }
            return makeAnthropicSessionIfPossible()

        case .anthropic:
            // User picked cloud. Use cloud when possible; fall
            // back to the Apple session if no credentials so the
            // tab still surfaces (users who pick Anthropic and
            // then forget to sign in see a working on-device
            // path instead of an empty tab).
            if let cloudSession = makeAnthropicSessionIfPossible() {
                return cloudSession
            }
            return appleSession
        }
    }

    @MainActor
    public func prewarmIfEnabled(
        session: (any BonjourChatSessionProtocol)?,
        aiAnalysisEnabled: Bool
    ) async {
        guard aiAnalysisEnabled, let session else { return }

        // The inner Apple factory's prewarm gates on Apple
        // Intelligence availability — for the cloud path that
        // check would unhelpfully skip the warmup. Pick the
        // right strategy based on what we actually got back.
        if session is AnthropicBonjourChatSession {
            await Task.yield()
            session.prewarm()
        } else {
            await appleFactory.prewarmIfEnabled(
                session: session,
                aiAnalysisEnabled: aiAnalysisEnabled
            )
        }
    }

    // MARK: - Private

    /// Builds an ``AnthropicBonjourChatSession`` when the
    /// credentials store has a key. Returns `nil` otherwise so
    /// callers can fall back to the Apple path or surface "not
    /// signed in" UX.
    @MainActor
    private func makeAnthropicSessionIfPossible() -> AnthropicBonjourChatSession? {
        guard credentialsStore.hasAPIKey(for: .anthropic) else {
            routingLogger.debug("Anthropic backend requested but no API key configured.")
            return nil
        }
        let session = AnthropicBonjourChatSession(
            client: client,
            credentialsStore: credentialsStore
        )
        session.selectedModel = preferencesStore.aiCloudModel
        return session
    }
}
