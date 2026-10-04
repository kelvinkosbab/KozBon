//
//  OpenAIBonjourServiceExplainer.swift
//  BonjourAIOpenAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourAICore
import BonjourCore
import BonjourModels

// MARK: - OpenAIBonjourServiceExplainer

/// OpenAI-backed implementation of
/// ``BonjourServiceExplainerProtocol`` for the Insights surface.
///
/// Mirrors ``GeminiBonjourServiceExplainer``: one-shot per
/// invocation, streamed into ``explanation``, with prompts from
/// `BonjourServicePromptBuilder` so tone and hedging are identical
/// across backends.
@MainActor
@Observable
public final class OpenAIBonjourServiceExplainer: BonjourServiceExplainerProtocol {

    // MARK: - Protocol-Required Properties

    public var explanation: String = ""
    public private(set) var isGenerating: Bool = false
    public var error: String?

    // MARK: - Diagnostics

    private let logger = Logger(
        subsystem: "com.kozinga.KozBon",
        category: "OpenAIBonjourServiceExplainer"
    )

    /// `true` when an OpenAI key is stored. With `false`, the
    /// Insights menu omits the row instead of showing a
    /// non-functional entry.
    public var isAvailable: Bool {
        credentialsStore.hasAPIKey(for: .openai)
    }

    public var expertiseLevel: BonjourServicePromptBuilder.ExpertiseLevel = .basic
    public var responseLength: BonjourServicePromptBuilder.ResponseLength = .standard

    // MARK: - OpenAI-Specific State

    private let client: any OpenAIClientProtocol
    private let credentialsStore: any AICloudCredentialsStore

    /// API identifier of the model to send. See
    /// ``OpenAIBonjourChatSession/selectedModel``.
    public var selectedModel: String = OpenAIModel.default.rawValue

    // MARK: - Init

    public init(
        client: any OpenAIClientProtocol,
        credentialsStore: any AICloudCredentialsStore
    ) {
        self.client = client
        self.credentialsStore = credentialsStore
    }

    // MARK: - Limits

    /// Per-explanation output budget. Insights answers are shorter
    /// than chat turns, but on reasoning models the budget also
    /// covers hidden reasoning — see
    /// ``OpenAIBonjourChatSession/maximumResponseTokensPerTurn``.
    static let maximumResponseTokensPerExplanation = 3072

    // MARK: - Explain (Service)

    public func explain(service: BonjourService, isPublished: Bool = false) async {
        let prompt = BonjourServicePromptBuilder.buildPrompt(
            service: service,
            isPublished: isPublished,
            expertiseLevel: expertiseLevel,
            responseLength: responseLength
        )
        await stream(prompt: prompt, systemText: BonjourServicePromptBuilder.systemInstructions)
    }

    // MARK: - Explain (Service Type)

    public func explain(serviceType: BonjourServiceType) async {
        let prompt = BonjourServicePromptBuilder.buildPrompt(
            serviceType: serviceType,
            expertiseLevel: expertiseLevel,
            responseLength: responseLength
        )
        await stream(prompt: prompt, systemText: BonjourServicePromptBuilder.serviceTypeSystemInstructions)
    }

    // MARK: - Explain (Release Highlight)

    public func explain(releaseHighlight: String, version: String) async {
        let prompt = BonjourServicePromptBuilder.buildPrompt(
            releaseHighlight: releaseHighlight,
            version: version,
            expertiseLevel: expertiseLevel,
            responseLength: responseLength
        )
        await stream(prompt: prompt, systemText: BonjourServicePromptBuilder.releaseHighlightSystemInstructions)
    }

    // MARK: - Private

    /// Streams the response into ``explanation``. Errors land in
    /// ``error``.
    private func stream(prompt: String, systemText: String) async {
        explanation = ""
        error = nil
        isGenerating = true
        defer { isGenerating = false }

        guard let apiKey = readAPIKey() else { return }

        let request = OpenAIResponseRequest.make(
            model: selectedModel,
            instructions: systemText,
            input: [OpenAIInputMessage(role: .user, content: prompt)],
            maxOutputTokens: Self.maximumResponseTokensPerExplanation
        )

        do {
            for try await chunk in client.streamMessage(request: request, apiKey: apiKey) {
                if Task.isCancelled { break }
                explanation += chunk
            }
        } catch is CancellationError {
            // User dismissed the Insights sheet mid-stream.
        } catch {
            let description = error.localizedDescription
            logger.error("OpenAI explainer stream failed: \(description)")
            self.error = description
        }
    }

    private func readAPIKey() -> String? {
        do {
            guard let storedKey = try credentialsStore.apiKey(for: .openai),
                  !storedKey.isEmpty else {
                self.error = AICloudError.missingCredentials(provider: .openai).errorDescription
                return nil
            }
            return storedKey
        } catch {
            logger.error("Failed to read OpenAI API key: \(error.localizedDescription)")
            self.error = error.localizedDescription
            return nil
        }
    }
}
