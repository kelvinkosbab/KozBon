//
//  GeminiBonjourServiceExplainer.swift
//  BonjourAIGemini
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourAICore
import BonjourCore
import BonjourModels

// MARK: - GeminiBonjourServiceExplainer

/// Google-Gemini-backed implementation of
/// ``BonjourServiceExplainerProtocol``.
///
/// Used for the Insights surface — long-press a discovered
/// service (or a library entry) and the explainer streams a
/// per-service explanation through Google's API. Mirrors the
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
public final class GeminiBonjourServiceExplainer: BonjourServiceExplainerProtocol {

    // MARK: - Protocol-Required Properties

    public var explanation: String = ""
    public private(set) var isGenerating: Bool = false
    public var error: String?

    // MARK: - Diagnostics

    /// Subsystem-scoped logger for explainer stream / auth
    /// failures. The user-facing error lives on ``error``;
    /// this is for log triage only.
    private let logger = Logger(
        subsystem: "com.kozinga.KozBon",
        category: "GeminiBonjourServiceExplainer"
    )

    /// Whether the explainer can currently issue a request.
    ///
    /// Mirrors the on-device side's `isAvailable` semantics —
    /// returns `true` when there's a stored API key for
    /// Gemini, `false` otherwise. The Insights long-press
    /// uses this to decide whether to surface the action; with
    /// `false`, the menu omits the row entirely instead of
    /// showing a non-functional entry.
    public var isAvailable: Bool {
        credentialsStore.hasAPIKey(for: .gemini)
    }

    public var expertiseLevel: BonjourServicePromptBuilder.ExpertiseLevel = .basic
    public var responseLength: BonjourServicePromptBuilder.ResponseLength = .standard

    // MARK: - Gemini-Specific State

    private let client: any GeminiClientProtocol
    private let credentialsStore: any AICloudCredentialsStore

    /// The model identifier the explainer sends to. Set by the
    /// factory based on the user's preference; defaults to
    /// ``GeminiModel/default`` so previews and tests don't
    /// need to wire it explicitly.
    /// API identifier of the model to send. See
    /// ``GeminiBonjourChatSession/selectedModel``.
    public var selectedModel: String = GeminiModel.default.rawValue

    // MARK: - Init

    public init(
        client: any GeminiClientProtocol,
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

    // MARK: - Explain (Release Highlight)

    public func explain(releaseHighlight: String, version: String) async {
        let prompt = BonjourServicePromptBuilder.buildPrompt(
            releaseHighlight: releaseHighlight,
            version: version,
            expertiseLevel: expertiseLevel,
            responseLength: responseLength
        )
        let systemText = BonjourServicePromptBuilder.releaseHighlightSystemInstructions
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

        // No role on the instructions block: Gemini takes system
        // instructions as their own top-level field rather than as
        // a turn in `contents`.
        let request = GeminiGenerateRequest(
            model: selectedModel,
            contents: [GeminiContent(role: .user, text: prompt)],
            systemInstruction: GeminiContent(role: nil, text: systemText),
            generationConfig: GeminiGenerationConfig(
                maxOutputTokens: Self.maximumResponseTokensPerExplanation
            )
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
            logger.error("Gemini explainer stream failed: \(description)")
            self.error = description
        }
    }

    /// Fetches the Google AI Studio API key from the credentials store,
    /// surfacing a localized `.missingCredentials` error on
    /// `self.error` and returning `nil` when the user has signed
    /// out mid-app-session.
    private func readAPIKey() -> String? {
        do {
            guard let storedKey = try credentialsStore.apiKey(for: .gemini),
                  !storedKey.isEmpty else {
                self.error = AICloudError.missingCredentials(provider: .gemini).errorDescription
                return nil
            }
            return storedKey
        } catch {
            logger.error("Failed to read Google AI Studio API key: \(error.localizedDescription)")
            self.error = error.localizedDescription
            return nil
        }
    }
}
