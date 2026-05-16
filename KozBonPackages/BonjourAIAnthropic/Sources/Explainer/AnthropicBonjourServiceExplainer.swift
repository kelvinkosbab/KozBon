//
//  AnthropicBonjourServiceExplainer.swift
//  BonjourAIAnthropic
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourAICore
import BonjourCore
import BonjourModels

// MARK: - Logger

private let logger = Logger(
    subsystem: "com.kozinga.KozBon",
    category: "AnthropicBonjourServiceExplainer"
)

// MARK: - AnthropicBonjourServiceExplainer

/// Anthropic-Claude-backed implementation of
/// ``BonjourServiceExplainerProtocol``.
///
/// Used for the Insights surface — long-press a discovered
/// service (or a library entry) and the explainer streams a
/// per-service explanation through Anthropic's API. Mirrors the
/// on-device ``BonjourServiceExplainer`` semantics so the
/// long-press flow doesn't change shape across backends:
///
/// - One-shot per invocation — `explain(service:)` / `explain(serviceType:)`
///   creates a fresh request each call. There's no multi-turn
///   history (unlike the chat session); the explainer is a
///   stateless function from "show me what this is" to a single
///   response.
/// - Streaming — text deltas append to ``explanation`` as they
///   arrive. The UI binds to ``explanation`` and re-renders on
///   every chunk, matching the on-device experience.
/// - Reuses the same prompt builder — system instructions and
///   per-service prompts come from
///   `BonjourServicePromptBuilder` so the explanation tone /
///   format / hedging behavior is identical across backends.
@MainActor
@Observable
public final class AnthropicBonjourServiceExplainer: BonjourServiceExplainerProtocol {

    // MARK: - Protocol-Required Properties

    public var explanation: String = ""
    public private(set) var isGenerating: Bool = false
    public var error: String?

    /// Whether the explainer can currently issue a request.
    ///
    /// Mirrors the on-device side's `isAvailable` semantics —
    /// returns `true` when there's a stored API key for
    /// Anthropic, `false` otherwise. The Insights long-press
    /// uses this to decide whether to surface the action; with
    /// `false`, the menu omits the row entirely instead of
    /// showing a non-functional entry.
    public var isAvailable: Bool {
        credentialsStore.hasAPIKey(for: .anthropic)
    }

    public var expertiseLevel: BonjourServicePromptBuilder.ExpertiseLevel = .basic
    public var responseLength: BonjourServicePromptBuilder.ResponseLength = .standard

    // MARK: - Anthropic-Specific State

    private let client: any AnthropicClientProtocol
    private let credentialsStore: any AICloudCredentialsStore

    /// The model identifier the explainer sends to. Set by the
    /// factory based on the user's preference; defaults to
    /// ``AnthropicModel/default`` so previews and tests don't
    /// need to wire it explicitly.
    public var selectedModel: AnthropicModel = .default

    // MARK: - Init

    public init(
        client: any AnthropicClientProtocol,
        credentialsStore: any AICloudCredentialsStore
    ) {
        self.client = client
        self.credentialsStore = credentialsStore
    }

    // MARK: - Limits

    /// Per-explanation token cap. Lower than the chat surface's
    /// cap because Insights answers are by nature shorter — one
    /// service, two or three paragraphs at most. Larger
    /// responses are usually a model glitch.
    static let maximumResponseTokensPerExplanation = 768

    // MARK: - Explain (Service)

    public func explain(service: BonjourService, isPublished: Bool = false) async {
        let prompt = BonjourServicePromptBuilder.buildPrompt(
            service: service,
            isPublished: isPublished,
            expertiseLevel: expertiseLevel,
            responseLength: responseLength
        )
        let systemText = BonjourServicePromptBuilder.systemInstructions
        await stream(prompt: prompt, systemText: systemText)
    }

    // MARK: - Explain (Service Type)

    public func explain(serviceType: BonjourServiceType) async {
        let prompt = BonjourServicePromptBuilder.buildPrompt(
            serviceType: serviceType,
            expertiseLevel: expertiseLevel,
            responseLength: responseLength
        )
        let systemText = BonjourServicePromptBuilder.serviceTypeSystemInstructions
        await stream(prompt: prompt, systemText: systemText)
    }

    // MARK: - Private

    /// Streams the response into ``explanation``.
    ///
    /// Resets state, fetches the API key, builds a one-shot
    /// request, and consumes the stream. Errors land in
    /// ``error`` and end with an empty ``explanation`` so the
    /// UI can render either / both.
    private func stream(prompt: String, systemText: String) async {
        explanation = ""
        error = nil
        isGenerating = true
        defer { isGenerating = false }

        guard let apiKey = readAPIKey() else { return }

        let systemBlock = AnthropicSystemBlock(
            text: systemText,
            cacheControl: .ephemeral
        )
        let request = AnthropicMessageRequest(
            model: selectedModel.rawValue,
            maxTokens: Self.maximumResponseTokensPerExplanation,
            stream: true,
            system: [systemBlock],
            messages: [AnthropicMessage(role: .user, content: prompt)]
        )

        do {
            for try await chunk in client.streamMessage(request: request, apiKey: apiKey) {
                if Task.isCancelled { break }
                explanation += chunk
            }
        } catch is CancellationError {
            // User dismissed the Insights sheet mid-stream.
            // Leave whatever's accumulated so the next surface
            // can decide whether to keep or discard.
        } catch {
            let description = error.localizedDescription
            logger.error("Anthropic explainer stream failed: \(description)")
            self.error = description
        }
    }

    /// Fetches the Anthropic API key from the credentials store,
    /// surfacing a localized `.missingCredentials` error on
    /// `self.error` and returning `nil` when the user has signed
    /// out mid-app-session.
    private func readAPIKey() -> String? {
        do {
            guard let storedKey = try credentialsStore.apiKey(for: .anthropic),
                  !storedKey.isEmpty else {
                self.error = AICloudError.missingCredentials(provider: .anthropic).errorDescription
                return nil
            }
            return storedKey
        } catch {
            logger.error("Failed to read Anthropic API key: \(error.localizedDescription)")
            self.error = error.localizedDescription
            return nil
        }
    }
}
