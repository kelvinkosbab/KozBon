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
import BonjourAIGemini
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
    private let geminiClient: any GeminiClientProtocol

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
        geminiClient: any GeminiClientProtocol = GeminiClient(),
    ) {
        self.appleFactory = appleFactory
        self.credentialsStore = credentialsStore
        self.preferencesStore = preferencesStore
        self.anthropicClient = anthropicClient
        self.geminiClient = geminiClient
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
            return makeCloudExplainerIfPossible(for: .anthropic)
                ?? makeCloudExplainerIfPossible(for: .gemini)

        case .anthropic, .gemini:
            if let provider = backend.cloudProvider,
               let cloudExplainer = makeCloudExplainerIfPossible(for: provider) {
                return cloudExplainer
            }
            return appleExplainer
        }
    }

    // MARK: - Private

    /// Builds the explainer for `provider` when a key is stored
    /// for it, reading the model from that provider's own
    /// preference slot.
    @MainActor
    private func makeCloudExplainerIfPossible(
        for provider: AICloudProvider
    ) -> (any BonjourServiceExplainerProtocol)? {
        guard credentialsStore.hasAPIKey(for: provider) else {
            explainerRoutingLogger.debug("Cloud backend requested but no API key configured.")
            return nil
        }

        // `selectedModel` is concrete on each explainer rather than
        // a protocol requirement, so assign before erasing.
        let model = preferencesStore.aiCloudModelIdentifier(for: provider)
        switch provider {
        case .anthropic:
            let explainer = AnthropicBonjourServiceExplainer(
                client: anthropicClient,
                credentialsStore: credentialsStore
            )
            explainer.selectedModel = model
            return explainer
        case .gemini:
            let explainer = GeminiBonjourServiceExplainer(
                client: geminiClient,
                credentialsStore: credentialsStore
            )
            explainer.selectedModel = model
            return explainer
        case .github:
            // Retired 2026-07-30; unreachable from any backend.
            return nil
        }
    }

}
