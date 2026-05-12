//
//  CloudAwareBonjourServiceExplainerFactory.swift
//  BonjourAICloud
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import OSLog
import BonjourAI
import BonjourStorage

// MARK: - Logger

private let explainerRoutingLogger = os.Logger(
    subsystem: "com.kozinga.KozBon",
    category: "CloudAwareBonjourServiceExplainerFactory"
)

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
    private let client: any AnthropicClientProtocol

    // MARK: - Init

    public init(
        appleFactory: any BonjourServiceExplainerFactoryProtocol = BonjourServiceExplainerFactory(),
        credentialsStore: any AICloudCredentialsStore & Sendable,
        preferencesStore: PreferencesStore,
        client: any AnthropicClientProtocol = AnthropicClient()
    ) {
        self.appleFactory = appleFactory
        self.credentialsStore = credentialsStore
        self.preferencesStore = preferencesStore
        self.client = client
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
            client: client,
            credentialsStore: credentialsStore
        )
        explainer.selectedModel = preferencesStore.aiCloudModel
        return explainer
    }
}
