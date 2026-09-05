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
    ) {
        self.appleFactory = appleFactory
        self.credentialsStore = credentialsStore
        self.preferencesStore = preferencesStore
        self.anthropicClient = anthropicClient
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


        case .anthropic:
            if let cloudExplainer = makeAnthropicExplainerIfPossible() {
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
        explainer.selectedModel = preferencesStore.aiCloudModelIdentifier
        return explainer
    }

}
