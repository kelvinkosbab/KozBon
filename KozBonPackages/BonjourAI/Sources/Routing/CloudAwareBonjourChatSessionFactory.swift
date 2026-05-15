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
import BonjourAIGitHub
import BonjourScanning
import BonjourStorage

// MARK: - Logger

private let routingLogger = os.Logger(
    subsystem: "com.kozinga.KozBon",
    category: "CloudAwareBonjourChatSessionFactory"
)

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
    private let githubClient: any GitHubModelsClientProtocol

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
    ///   - githubClient: The GitHub Models API client used when
    ///     routing hits the GitHub path. Defaults to a real
    ///     ``GitHubModelsClient`` against
    ///     `models.inference.ai.azure.com`.
    public init(
        appleFactory: any BonjourChatSessionFactoryProtocol = BonjourChatSessionFactory(),
        credentialsStore: any AICloudCredentialsStore & Sendable,
        preferencesStore: PreferencesStore,
        anthropicClient: any AnthropicClientProtocol = AnthropicClient(),
        githubClient: any GitHubModelsClientProtocol = GitHubModelsClient()
    ) {
        self.appleFactory = appleFactory
        self.credentialsStore = credentialsStore
        self.preferencesStore = preferencesStore
        self.anthropicClient = anthropicClient
        self.githubClient = githubClient
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
            return makeAnthropicSessionIfPossible()
                ?? makeGitHubSessionIfPossible()

        case .anthropic:
            // User picked Anthropic. Use it when possible; fall
            // back to the Apple session if no credentials so the
            // tab still surfaces.
            if let cloudSession = makeAnthropicSessionIfPossible() {
                return cloudSession
            }
            return appleSession

        case .github:
            // User picked GitHub. Use it when possible; same
            // Apple fall-back semantics as the Anthropic branch.
            if let cloudSession = makeGitHubSessionIfPossible() {
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
        if session is AnthropicBonjourChatSession
            || session is GitHubBonjourChatSession {
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
    /// credentials store has an Anthropic key. Returns `nil`
    /// otherwise so callers can fall back to other paths.
    @MainActor
    private func makeAnthropicSessionIfPossible() -> AnthropicBonjourChatSession? {
        guard credentialsStore.hasAPIKey(for: .anthropic) else {
            routingLogger.debug("Anthropic backend requested but no API key configured.")
            return nil
        }
        let session = AnthropicBonjourChatSession(
            client: anthropicClient,
            credentialsStore: credentialsStore
        )
        session.selectedModel = preferencesStore.aiCloudModel
        return session
    }

    /// Builds a ``GitHubBonjourChatSession`` when the credentials
    /// store has a GitHub PAT. Returns `nil` otherwise. No model
    /// selection: the GitHub backend hardcodes `gpt-4o`.
    @MainActor
    private func makeGitHubSessionIfPossible() -> GitHubBonjourChatSession? {
        guard credentialsStore.hasAPIKey(for: .github) else {
            routingLogger.debug("GitHub backend requested but no PAT configured.")
            return nil
        }
        return GitHubBonjourChatSession(
            client: githubClient,
            credentialsStore: credentialsStore
        )
    }
}
