//
//  CloudAwareBonjourChatSessionFactory.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourAICore
import BonjourAIApple
import BonjourAIAnthropic
import BonjourAIGemini
import BonjourCore
import BonjourScanning
import BonjourStorage

// MARK: - CloudAwareBonjourChatSessionFactory

/// Cloud-aware ``BonjourChatSessionFactoryProtocol`` that picks
/// between the on-device Apple Foundation Models session, the
/// Anthropic Claude session, and the GitHub Models (GPT-4o)
/// session based on the user's current preferences.
///
/// Sits on top of the existing ``BonjourChatSessionFactory``
/// (which knows how to build the Apple-side session) rather than
/// reaching into the FoundationModels-gated implementation
/// directly. This keeps the simulator / iOS-version branching
/// localized to one place (the inner factory) and lets the
/// cloud-aware layer focus on the routing decision.
///
/// Routing rules:
///
/// - **`.appleIntelligence`** — call through to the inner Apple
///   factory. Returns `nil` on hardware that can't run
///   FoundationModels; falls through to a cloud path when any
///   cloud credentials are configured (so users on ineligible
///   hardware can still get a Chat tab via Claude or GitHub).
/// - **`.anthropic`** — read the Anthropic key from the
///   credentials store; if present, return an
///   ``AnthropicBonjourChatSession``. If no key, fall back to the
///   Apple session (so the tab doesn't disappear when the user
///   selects cloud but hasn't signed in yet).
/// - **`.github`** — read the GitHub PAT from the credentials
///   store; if present, return a ``GitHubBonjourChatSession``.
///   Same fall-back-to-Apple semantics as the Anthropic branch.
/// - **Neither available** — return `nil`, matching the legacy
///   contract that hides the Chat tab.
///
/// Pre-warming is delegated to the active backend's own
/// `prewarm()` method.
public struct CloudAwareBonjourChatSessionFactory: BonjourChatSessionFactoryProtocol {

    // MARK: - Long-Lived Dependencies

    private let appleFactory: any BonjourChatSessionFactoryProtocol
    private let credentialsStore: any AICloudCredentialsStore & Sendable
    private let preferencesStore: PreferencesStore
    private let anthropicClient: any AnthropicClientProtocol
    private let geminiClient: any GeminiClientProtocol

    /// Subsystem-scoped logger for cloud-fallback diagnostics.
    /// Console.app filters by category
    /// `CloudAwareBonjourChatSessionFactory`.
    private let routingLogger = Logger(
        subsystem: "com.kozinga.KozBon",
        category: "CloudAwareBonjourChatSessionFactory"
    )

    // MARK: - Init

    /// - Parameters:
    ///   - appleFactory: The inner factory that produces the
    ///     on-device session. Defaults to the production
    ///     ``BonjourAI.BonjourChatSessionFactory``; tests inject
    ///     a mock.
    ///   - credentialsStore: Where to read cloud credentials
    ///     from. Defaults to the Keychain-backed store; tests
    ///     pass an `InMemoryAICloudCredentialsStore`.
    ///   - preferencesStore: Source of `aiBackend` and
    ///     `aiCloudModel` selection. Read fresh on every
    ///     `makeForCurrentEnvironment(...)` call so the routing
    ///     reflects any preference change between app launches.
    ///   - anthropicClient: The Anthropic API client used when
    ///     routing hits the Anthropic path. Defaults to a real
    ///     ``AnthropicClient`` against `api.anthropic.com`.
    ///   - geminiClient: The Gemini API client used when routing
    ///     hits the Gemini path. Defaults to a real
    ///     ``GeminiClient`` against
    ///     `generativelanguage.googleapis.com`.
    public init(
        appleFactory: any BonjourChatSessionFactoryProtocol = BonjourChatSessionFactory(),
        credentialsStore: any AICloudCredentialsStore & Sendable,
        preferencesStore: PreferencesStore,
        anthropicClient: any AnthropicClientProtocol = AnthropicClient(),
        geminiClient: any GeminiClientProtocol = GeminiClient(),
    ) {
        self.appleFactory = appleFactory
        self.credentialsStore = credentialsStore
        self.preferencesStore = preferencesStore
        self.anthropicClient = anthropicClient
        self.geminiClient = geminiClient
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
            // device can't actually run it, fall back to whichever
            // cloud backend has credentials so the surface doesn't
            // vanish.
            if appleSession != nil {
                return appleSession
            }
            return makeCloudSessionIfPossible(for: .anthropic)
                ?? makeCloudSessionIfPossible(for: .gemini)

        case .anthropic, .gemini:
            // User picked a cloud provider. Use it when possible;
            // fall back to the Apple session if no credentials so
            // the tab still surfaces.
            if let provider = backend.cloudProvider,
               let cloudSession = makeCloudSessionIfPossible(for: provider) {
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
        if session is AnthropicBonjourChatSession || session is GeminiBonjourChatSession {
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

    /// Builds the session for `provider` when the credentials
    /// store holds a key for it. Returns `nil` otherwise so callers
    /// can fall back to another path.
    ///
    /// The model comes from that provider's own preference slot, so
    /// switching backends can't hand Gemini a `claude-` identifier.
    @MainActor
    private func makeCloudSessionIfPossible(
        for provider: AICloudProvider
    ) -> (any BonjourChatSessionProtocol)? {
        guard credentialsStore.hasAPIKey(for: provider) else {
            routingLogger.debug("Cloud backend requested but no API key configured.")
            return nil
        }

        // `selectedModel` is a concrete property on each session
        // type rather than a protocol requirement, so it has to be
        // assigned before the value is erased to the protocol.
        let model = preferencesStore.aiCloudModelIdentifier(for: provider)
        switch provider {
        case .anthropic:
            let session = AnthropicBonjourChatSession(
                client: anthropicClient,
                credentialsStore: credentialsStore
            )
            session.selectedModel = model
            return session
        case .gemini:
            let session = GeminiBonjourChatSession(
                client: geminiClient,
                credentialsStore: credentialsStore
            )
            session.selectedModel = model
            return session
        case .github:
            // Retired 2026-07-30; unreachable from any backend.
            return nil
        }
    }

}
