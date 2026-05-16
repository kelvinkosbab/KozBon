//
//  GitHubBonjourChatSession.swift
//  BonjourAIGitHub
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourAICore
import BonjourCore
import BonjourLocalization

// MARK: - GitHubBonjourChatSession

/// GitHub-Models-backed implementation of
/// ``BonjourChatSessionProtocol``.
///
/// Mirrors the Anthropic + on-device sessions so the SwiftUI chat
/// surface treats all backends interchangeably:
///
/// - Multi-turn — every user turn and assistant response is
///   appended to ``messages`` and to a parallel
///   ``conversationHistory`` of ``GitHubMessage`` values. The
///   history is sent on every send so GPT-4o has full context.
///   Unlike Anthropic there is no prompt cache; every request
///   re-sends the full system + history payload.
/// - Streaming — text deltas arrive through
///   `GitHubModelsClient.streamChat(...)` and are appended to a
///   placeholder assistant message in real time.
/// - Cancellation — task cancellation propagates to the
///   underlying `URLSessionDataTask`.
/// - Recreation — flipping the response-length preference
///   regenerates the system instructions and resets
///   ``conversationHistory`` (same surface-level reset the other
///   sessions do).
///
/// The `intentBroker` is held for protocol conformance but stays
/// inert: tool calling lives on the on-device backend only for now.
@MainActor
@Observable
public final class GitHubBonjourChatSession: BonjourChatSessionProtocol {

    // MARK: - Protocol-Required Properties

    public private(set) var messages: [BonjourChatMessage] = []
    public private(set) var isGenerating: Bool = false
    public var error: String?
    public private(set) var errorAction: ChatErrorAction?
    public var responseLength: BonjourServicePromptBuilder.ResponseLength = .standard
    public let intentBroker: BonjourChatIntentBroker

    // MARK: - Diagnostics

    /// Subsystem-scoped logger. Errors from the streaming
    /// client surface in Console.app under `com.kozinga.KozBon`
    /// with category `GitHubBonjourChatSession`. Users see the
    /// localized error text in the chat surface; this is for
    /// log triage only.
    private let logger = Logger(
        subsystem: "com.kozinga.KozBon",
        category: "GitHubBonjourChatSession"
    )

    // MARK: - GitHub-Specific State

    /// The GitHub Models API client. Real ``GitHubModelsClient`` in
    /// production, ``MockGitHubModelsClient`` in tests / previews.
    private let client: any GitHubModelsClientProtocol

    /// Credentials store the session reads the PAT from on every
    /// send. Reading per call (rather than capturing at init) means
    /// the user can sign out and back in mid-app-session without
    /// the chat surface holding a stale token.
    private let credentialsStore: any AICloudCredentialsStore

    /// Static configuration — captured at init so subsequent
    /// preference changes don't mutate an in-flight session.
    private let configuration: GitHubConfiguration

    /// Snapshot of the response-length preference baked into the
    /// current system instructions.
    private var currentResponseLengthSnapshot: BonjourServicePromptBuilder.ResponseLength?

    /// The cached system instructions text. Built lazily on the
    /// first send (or `prewarm()`) and rebuilt only when the
    /// underlying response-length preference changes.
    private var systemText: String?

    /// The user / assistant turn history sent to GitHub Models on
    /// every request, in chronological order. The final element is
    /// always the user's latest message. Distinct from
    /// ``messages`` (which renders for SwiftUI) because we don't
    /// send the streaming assistant placeholder back to the API.
    private var conversationHistory: [GitHubMessage] = []

    /// Tracks whether a fresh `<context>` block has been sent on
    /// this session. After the first turn, only changed contexts
    /// trigger a re-injection — keeps the wire payload small for
    /// the static parts of the conversation.
    private var lastContextBlock: String?

    // MARK: - Init

    public init(
        client: any GitHubModelsClientProtocol,
        credentialsStore: any AICloudCredentialsStore,
        configuration: GitHubConfiguration = GitHubConfiguration(),
        intentBroker: BonjourChatIntentBroker = BonjourChatIntentBroker()
    ) {
        self.client = client
        self.credentialsStore = credentialsStore
        self.configuration = configuration
        self.intentBroker = intentBroker
    }

    // MARK: - Limits

    /// Same in-memory bubble cap as the other sessions — kept
    /// identical so all backends produce indistinguishable
    /// scrollback behavior.
    static let maxInMemoryMessageCount = 500

    /// Max tokens per GPT-4o response. Sized to match the
    /// Anthropic side; the GitHub Models free tier caps slightly
    /// lower per request than Anthropic but 1024 fits comfortably
    /// inside that ceiling.
    static let maximumResponseTokensPerTurn = 1024

    // MARK: - Prewarm

    /// Builds the system instructions ahead of the user's first
    /// send so suggestion-tap latency doesn't include the cost of
    /// constructing the prompt. Idempotent — once the text exists
    /// and matches current preferences, subsequent calls are
    /// no-ops.
    ///
    /// Network calls don't happen here; the system text isn't
    /// sent until the user actually sends a message. Unlike
    /// Anthropic there is no prompt cache to warm — this is
    /// purely a CPU prewarm of the builder output.
    public func prewarm() {
        guard systemText == nil
                || currentResponseLengthSnapshot != responseLength else {
            return
        }

        systemText = BonjourChatPromptBuilder.systemInstructions(
            responseLength: responseLength
        )
        currentResponseLengthSnapshot = responseLength
        lastContextBlock = nil
    }

    // MARK: - Append User Message

    /// Appends the user's message to ``messages`` synchronously.
    /// The chat view calls this the instant the user taps Send
    /// so the bubble lands on screen before the network awaits.
    /// `send(_:context:)` will NOT re-append.
    public func appendUserMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if messages.count >= Self.maxInMemoryMessageCount {
            messages = Array(messages.suffix(Self.maxInMemoryMessageCount - 1))
        }

        messages.append(BonjourChatMessage(role: .user, content: trimmed))
    }

    // MARK: - Send

    public func send(_ text: String, context: BonjourChatPromptBuilder.ChatContext) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        error = nil
        errorAction = nil
        isGenerating = true
        defer { isGenerating = false }
        // Reset tool-call counter for symmetry with the on-device
        // session, even though GitHub Models doesn't drive tool
        // calls in v1.
        intentBroker.resetToolCallCount()

        prewarm()
        guard let apiKey = readAPIKey() else { return }
        let systemMessage = makeSystemMessage()
        let turnText = composeTurn(trimmed: trimmed, context: context)

        conversationHistory.append(GitHubMessage(role: .user, content: turnText))
        let assistantId = UUID()
        messages.append(BonjourChatMessage(id: assistantId, role: .assistant, content: ""))

        let request = GitHubMessageRequest(
            model: configuration.model,
            messages: [systemMessage] + conversationHistory,
            stream: true,
            maxTokens: Self.maximumResponseTokensPerTurn
        )

        await drainStream(request: request, apiKey: apiKey, assistantId: assistantId)
    }

    // MARK: - Send Helpers

    /// Reads the GitHub PAT from the credentials store, surfacing
    /// a localized `.missingCredentials` error on `self.error` and
    /// returning `nil` when the user has signed out mid-session.
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

    /// Returns the current system message, building a fallback
    /// one if `prewarm()` somehow didn't run first. `prewarm()` is
    /// always called by `send`, so the fallback is defensive — the
    /// type system can't verify the assignment so we coalesce
    /// rather than force-unwrap.
    private func makeSystemMessage() -> GitHubMessage {
        let text = systemText ?? BonjourChatPromptBuilder.systemInstructions(
            responseLength: responseLength
        )
        return GitHubMessage(role: .system, content: text)
    }

    /// Composes the user-turn text via
    /// `BonjourChatPromptBuilder.userTurn(...)` — the same shape
    /// the other sessions use, so context injection / referenced
    /// descriptions / numbering rules behave identically across
    /// backends.
    private func composeTurn(
        trimmed: String,
        context: BonjourChatPromptBuilder.ChatContext
    ) -> String {
        let currentContextBlock = BonjourChatPromptBuilder.contextBlock(context: context)
        let isFirstTurn = (lastContextBlock == nil)
        let contextChanged = lastContextBlock != currentContextBlock
        let turnText = BonjourChatPromptBuilder.userTurn(
            message: trimmed,
            context: context,
            isFirstTurn: isFirstTurn,
            contextChanged: contextChanged
        )
        lastContextBlock = currentContextBlock
        return turnText
    }

    /// Consumes the GitHub Models stream into the placeholder
    /// assistant message. Persists the completed text into
    /// `conversationHistory` on success; rolls the placeholder
    /// (and the matching user turn) back on error or cancellation
    /// so a retry doesn't submit a doubled history.
    private func drainStream(
        request: GitHubMessageRequest,
        apiKey: String,
        assistantId: UUID
    ) async {
        var collectedAssistantText = ""
        do {
            for try await chunk in client.streamChat(request: request, apiKey: apiKey) {
                if Task.isCancelled { break }
                collectedAssistantText += chunk
                if let index = messages.firstIndex(where: { $0.id == assistantId }) {
                    messages[index].content += chunk
                }
            }
            finalizeAssistantTurn(text: collectedAssistantText, assistantId: assistantId)
        } catch is CancellationError {
            rollBackTurn(assistantId: assistantId)
        } catch {
            logger.error(
                """
                GitHub Models stream failed — \
                kind: \(String(describing: error)), \
                description: \(error.localizedDescription)
                """
            )
            self.error = error.localizedDescription
            self.errorAction = Self.makeErrorAction(for: error)
            rollBackTurn(assistantId: assistantId)
        }
    }

    /// Maps a stream failure to an optional user-facing
    /// remediation.
    ///
    /// Four cases produce an action; everything else returns `nil`
    /// because there's no URL or in-app affordance that would help
    /// (the banner still renders the message, just without a
    /// button). Routing per case:
    /// - ``AICloudError/invalidCredentials`` → in-app sign-in
    ///   sheet (which itself links to the GitHub tokens page).
    /// - ``AICloudError/permissionDenied`` → GitHub Models
    ///   marketplace page.
    /// - ``AICloudError/contextWindowExceeded`` → clear chat.
    /// - ``AICloudError/networkUnavailable`` → in-app retry.
    private static func makeErrorAction(for error: Error) -> ChatErrorAction? {
        guard let aiError = error as? AICloudError else { return nil }
        switch aiError {
        case .invalidCredentials:
            return ChatErrorAction(
                kind: .openSignIn,
                label: Strings.Chat.signInAgain,
                accessibilityHint: Strings.Accessibility.chatSignInAgainHint
            )
        case .permissionDenied:
            return urlAction(
                "https://github.com/marketplace/models",
                label: Strings.Chat.openPlans,
                hint: Strings.Accessibility.chatOpenPlansHint
            )
        case .contextWindowExceeded:
            return ChatErrorAction(
                kind: .clearChat,
                label: Strings.Chat.clearHistory,
                accessibilityHint: Strings.Accessibility.chatErrorClearChatHint
            )
        case .networkUnavailable:
            return ChatErrorAction(
                kind: .retry,
                label: Strings.Chat.tryAgain,
                accessibilityHint: Strings.Accessibility.chatTryAgainHint
            )
        case .missingCredentials,
                .rateLimited,
                .serverError,
                .serviceOverloaded,
                .invalidRequest,
                .creditBalanceTooLow,
                .decodingFailure,
                .keychainFailure,
                .cancelled,
                .unexpectedStatus:
            return nil
        }
    }

    /// Builds a ``ChatErrorAction`` from a hard-coded URL string.
    /// The URLs in `makeErrorAction(for:)` are all known-valid so
    /// a missing `URL(string:)` would be a programming error — but
    /// we coalesce to `nil` rather than force-unwrap so a typo in
    /// a future addition can't crash the chat surface.
    private static func urlAction(
        _ urlString: String,
        label: LocalizedStringResource,
        hint: LocalizedStringResource
    ) -> ChatErrorAction? {
        guard let url = URL(string: urlString) else { return nil }
        return ChatErrorAction(url: url, label: label, accessibilityHint: hint)
    }

    /// Either persists the completed assistant text into
    /// `conversationHistory`, or — when the response was empty —
    /// rolls the no-op exchange out of both queues so the next
    /// send doesn't accumulate a hollow turn.
    private func finalizeAssistantTurn(text: String, assistantId: UUID) {
        if text.isEmpty {
            rollBackTurn(assistantId: assistantId)
        } else {
            conversationHistory.append(GitHubMessage(role: .assistant, content: text))
        }
    }

    /// Removes the placeholder assistant bubble and the matching
    /// user turn so the next send doesn't carry an orphaned
    /// history.
    private func rollBackTurn(assistantId: UUID) {
        messages.removeAll { $0.id == assistantId }
        if !conversationHistory.isEmpty {
            conversationHistory.removeLast()
        }
    }

    // MARK: - Local Rejection

    public func appendLocalRejection(userMessage: String, refusalText: String) {
        // Render the exchange as real chat turns so the UI treats
        // them like any other back-and-forth. We deliberately do
        // NOT append to `conversationHistory` — the model
        // shouldn't see rejected content in its history.
        messages.append(BonjourChatMessage(role: .user, content: userMessage))
        messages.append(BonjourChatMessage(role: .assistant, content: refusalText))
    }

    // MARK: - Clear Error

    /// Overrides the protocol default so the actionable
    /// remediation (``errorAction``) clears in the same call as
    /// ``error``.
    public func clearError() {
        error = nil
        errorAction = nil
    }

    // MARK: - Reset

    public func reset() {
        messages.removeAll()
        conversationHistory.removeAll()
        systemText = nil
        currentResponseLengthSnapshot = nil
        lastContextBlock = nil
        error = nil
        errorAction = nil
        isGenerating = false
        intentBroker.consume()
    }

    // MARK: - Restore

    public func restore(messages: [BonjourChatMessage]) {
        self.messages = messages
        // We do NOT reconstruct the GitHub-side history from these
        // messages — they may carry locally-rejected turns we
        // deliberately kept out of the model's context, and
        // re-running them through the API would re-bill the
        // user's free-tier quota. Same trade-off the other
        // sessions document.
        conversationHistory.removeAll()
        systemText = nil
        currentResponseLengthSnapshot = nil
        lastContextBlock = nil
        error = nil
        errorAction = nil
        isGenerating = false
    }
}
