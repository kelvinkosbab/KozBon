//
//  GitHubBonjourServiceExplainer.swift
//  BonjourAIGitHub
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import OSLog
import BonjourAICore
import BonjourCore
import BonjourModels

// MARK: - Logger

// `BonjourCore`'s `Exports.swift` re-exports the `Core` package
// which ships its own `Logger` type. Spell the OSLog one fully so
// the imports don't fight over the unqualified name.
private let logger = os.Logger(
    subsystem: "com.kozinga.KozBon",
    category: "GitHubBonjourServiceExplainer"
)

// MARK: - GitHubBonjourServiceExplainer

/// GitHub-Models-backed implementation of
/// ``BonjourServiceExplainerProtocol``.
///
/// Used for the Insights surface — long-press a discovered service
/// (or a library entry) and the explainer streams a per-service
/// explanation through GPT-4o. Mirrors the on-device + Anthropic
/// explainers so the long-press flow doesn't change shape across
/// backends:
///
/// - One-shot per invocation — `explain(service:)` /
///   `explain(serviceType:)` creates a fresh request each call.
///   There's no multi-turn history; the explainer is a stateless
///   function from "show me what this is" to a single response.
/// - Streaming — text deltas append to ``explanation`` as they
///   arrive. The UI binds to ``explanation`` and re-renders on
///   every chunk.
/// - Reuses the same prompt builder — system instructions and
///   per-service prompts come from `BonjourServicePromptBuilder`
///   so the explanation tone / format / hedging behavior is
///   identical across backends.
@MainActor
@Observable
public final class GitHubBonjourServiceExplainer: BonjourServiceExplainerProtocol {

    // MARK: - Protocol-Required Properties

    public var explanation: String = ""
    public private(set) var isGenerating: Bool = false
    public var error: String?

    /// Whether the explainer can currently issue a request.
    ///
    /// Returns `true` when there's a stored PAT for GitHub, `false`
    /// otherwise. The Insights long-press uses this to decide
    /// whether to surface the action.
    public var isAvailable: Bool {
        credentialsStore.hasAPIKey(for: .github)
    }

    public var expertiseLevel: BonjourServicePromptBuilder.ExpertiseLevel = .basic
    public var responseLength: BonjourServicePromptBuilder.ResponseLength = .standard

    // MARK: - GitHub-Specific State

    private let client: any GitHubModelsClientProtocol
    private let credentialsStore: any AICloudCredentialsStore
    private let configuration: GitHubConfiguration

    // MARK: - Init

    public init(
        client: any GitHubModelsClientProtocol,
        credentialsStore: any AICloudCredentialsStore,
        configuration: GitHubConfiguration = GitHubConfiguration()
    ) {
        self.client = client
        self.credentialsStore = credentialsStore
        self.configuration = configuration
    }

    // MARK: - Limits

    /// Per-explanation token cap. Lower than the chat surface's
    /// cap because Insights answers are by nature shorter — one
    /// service, two or three paragraphs at most. Larger responses
    /// are usually a model glitch.
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
    /// Resets state, fetches the PAT, builds a one-shot request,
    /// and consumes the stream. Errors land in ``error`` and end
    /// with an empty ``explanation`` so the UI can render either /
    /// both.
    private func stream(prompt: String, systemText: String) async {
        explanation = ""
        error = nil
        isGenerating = true
        defer { isGenerating = false }

        guard let apiKey = readAPIKey() else { return }

        let request = GitHubMessageRequest(
            model: configuration.model,
            messages: [
                GitHubMessage(role: .system, content: systemText),
                GitHubMessage(role: .user, content: prompt)
            ],
            stream: true,
            maxTokens: Self.maximumResponseTokensPerExplanation
        )

        do {
            for try await chunk in client.streamChat(request: request, apiKey: apiKey) {
                if Task.isCancelled { break }
                explanation += chunk
            }
        } catch is CancellationError {
            // User dismissed the Insights sheet mid-stream. Leave
            // whatever's accumulated so the next surface can
            // decide whether to keep or discard.
        } catch {
            let description = error.localizedDescription
            logger.error("GitHub Models explainer stream failed: \(description, privacy: .public)")
            self.error = description
        }
    }

    /// Fetches the GitHub PAT from the credentials store,
    /// surfacing a localized `.missingCredentials` error on
    /// `self.error` and returning `nil` when the user has signed
    /// out mid-app-session.
    private func readAPIKey() -> String? {
        do {
            guard let storedKey = try credentialsStore.apiKey(for: .github),
                  !storedKey.isEmpty else {
                self.error = AICloudError.missingCredentials(provider: .github).errorDescription
                return nil
            }
            return storedKey
        } catch {
            logger.error("Failed to read GitHub PAT: \(error.localizedDescription)")
            self.error = error.localizedDescription
            return nil
        }
    }
}
