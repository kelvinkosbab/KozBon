//
//  CloudAwareBonjourServiceExplainerFactory.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourAICore
import BonjourAIApple
import BonjourAIAnthropic
import BonjourAIGitHub
import BonjourCore
import BonjourStorage

// MARK: - CloudAwareBonjourServiceExplainerFactory

/// Cloud-aware ``BonjourServiceExplainerFactoryProtocol`` that
/// mirrors ``CloudAwareBonjourChatSessionFactory`` for the
/// Insights surface.
///
/// Same routing rules as the chat factory: respect the user's
/// `aiBackend` preference, fall back to the other backend when
/// the preferred one is unavailable, return `nil` only when
/// neither path can produce an explainer.
public struct CloudAwareBonjourServiceExplainerFactory: BonjourServiceExplainerFactoryProtocol {

    // MARK: - Long-Lived Dependencies

    private let appleFactory: any BonjourServiceExplainerFactoryProtocol
    private let credentialsStore: any AICloudCredentialsStore & Sendable
    private let preferencesStore: PreferencesStore
    private let anthropicClient: any AnthropicClientProtocol
    private let githubClient: any GitHubModelsClientProtocol

    /// Subsystem-scoped logger. Console.app filters by category
    /// `CloudAwareBonjourServiceExplainerFactory`.
    private let explainerRoutingLogger = Logger(
        subsystem: "com.kozinga.KozBon",
        category: "CloudAwareBonjourServiceExplainerFactory"
    )

    // MARK: - Init

    public init(
        appleFactory: any BonjourServiceExplainerFactoryProtocol = BonjourServiceExplainerFactory(),
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

    // MARK: - BonjourServiceExplainerFactoryProtocol

    @MainActor
    public func makeForCurrentEnvironment() -> (any BonjourServiceExplainerProtocol)? {
        let appleExplainer = appleFactory.makeForCurrentEnvironment()
        let backend = preferencesStore.aiBackend

        switch backend {
        case .appleIntelligence:
            if appleExplainer != nil {
                return appleExplainer
            }
            return makeAnthropicExplainerIfPossible()
                ?? makeGitHubExplainerIfPossible()

        case .anthropic:
            if let cloudExplainer = makeAnthropicExplainerIfPossible() {
                return cloudExplainer
            }
            return appleExplainer

        case .github:
            if let cloudExplainer = makeGitHubExplainerIfPossible() {
                return cloudExplainer
            }
            return appleExplainer
        }
    }

    // MARK: - Private

    @MainActor
    private func makeAnthropicExplainerIfPossible() -> AnthropicBonjourServiceExplainer? {
        guard credentialsStore.hasAPIKey(for: .anthropic) else {
            explainerRoutingLogger.debug("Anthropic backend requested but no API key configured.")
            return nil
        }
        let explainer = AnthropicBonjourServiceExplainer(
            client: anthropicClient,
            credentialsStore: credentialsStore
        )
        explainer.selectedModel = preferencesStore.aiCloudModel
        return explainer
    }

    @MainActor
    private func makeGitHubExplainerIfPossible() -> GitHubBonjourServiceExplainer? {
        guard credentialsStore.hasAPIKey(for: .github) else {
            explainerRoutingLogger.debug("GitHub backend requested but no PAT configured.")
            return nil
        }
        return GitHubBonjourServiceExplainer(
            client: githubClient,
            credentialsStore: credentialsStore
        )
    }
}
