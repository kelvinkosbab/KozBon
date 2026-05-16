//
//  AnthropicBonjourChatSession.swift
//  BonjourAIAnthropic
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourAICore
import BonjourCore
import BonjourLocalization

// MARK: - Logger

/// Subsystem-scoped logger. Errors from the streaming client
/// surface in Console.app under `com.kozinga.KozBon` with category
/// `AnthropicBonjourChatSession`. Used purely for diagnostics —
/// users see the localized error text in the chat surface.
private let logger = Logger(
    subsystem: "com.kozinga.KozBon",
    category: "AnthropicBonjourChatSession"
)

// MARK: - AnthropicBonjourChatSession

/// Anthropic-Claude-backed implementation of
/// ``BonjourChatSessionProtocol``.
///
/// Mirrors the on-device ``BonjourChatSession`` semantics so the
/// SwiftUI chat surface treats both backends interchangeably:
///
/// - Multi-turn — every user turn and assistant response is
///   appended to ``messages`` and to a parallel
///   ``conversationHistory`` of `AnthropicMessage` values. The
///   history is sent on every send so Claude has full context;
///   the system block carries `cache_control: ephemeral` so the
///   static instructions are reused across requests without
///   repeated encoding cost.
/// - Streaming — text deltas arrive through
///   `AnthropicClient.streamMessage(...)` and are appended to a
///   placeholder assistant message in real time.
/// - Cancellation — task cancellation propagates to the
///   underlying `URLSessionDataTask`, so navigating away from
///   the chat surface aborts the in-flight request.
/// - Recreation — flipping the response-length preference
///   regenerates the system instructions and resets
///   ``conversationHistory``; the same surface-level reset the
///   on-device session does, for the same reason (the cached
///   prefix would no longer match).
///
/// The `intentBroker` is held for protocol conformance but stays
/// inert: tool calling lives on the on-device backend only for
/// now. Anthropic supports tools too, but reusing the existing
/// `BonjourChatIntent` schema requires a separate adapter, which
/// is out of scope for v1.
@MainActor
@Observable
public final class AnthropicBonjourChatSession: BonjourChatSessionProtocol {

    // MARK: - Protocol-Required Properties

    public private(set) var messages: [BonjourChatMessage] = []
    public private(set) var isGenerating: Bool = false
    public var error: String?
    public private(set) var errorAction: ChatErrorAction?
    public var responseLength: BonjourServicePromptBuilder.ResponseLength = .standard
    public let intentBroker: BonjourChatIntentBroker

    // MARK: - Anthropic-Specific State

    /// The Anthropic API client. Real `AnthropicClient` in
    /// production, `MockAnthropicClient` in tests / previews.
    /// Held as `any` rather than the concrete type so the chat
    /// session itself stays test-friendly.
    private let client: any AnthropicClientProtocol

    /// Credentials store the session reads the API key from on
    /// every send. Reading per call (rather than capturing at
    /// init) means the user can sign out and back in mid-app-
    /// session without the chat surface holding a stale key.
    private let credentialsStore: any AICloudCredentialsStore

    /// Snapshot of the Claude model selected when the current
    /// system block was built. If the user flips this preference
    /// mid-conversation we recreate the cached prefix.
    private var currentModel: AnthropicModel?

    /// Snapshot of the response-length preference baked into the
    /// current system instructions. Same recreation policy as
    /// ``currentModel``.
    private var currentResponseLengthSnapshot: BonjourServicePromptBuilder.ResponseLength?

    /// The cached, ephemeral system instructions block sent on
    /// every request. Built lazily on the first send (or
    /// `prewarm()`) and rebuilt only when the underlying
    /// preferences change.
    private var systemBlock: AnthropicSystemBlock?

    /// The user / assistant turn history sent to Anthropic on
    /// every request, in chronological order. The final element
    /// is always the user's latest message. Distinct from
    /// ``messages`` (which renders for SwiftUI) because we don't
    /// send the streaming assistant placeholder back to the API.
    private var conversationHistory: [AnthropicMessage] = []

    /// Tracks whether a fresh `<context>` block has been sent on
    /// this session. After the first turn, only changed contexts
    /// trigger a re-injection — keeps the prompt cache stable
    /// for the static parts of the conversation.
    private var lastContextBlock: String?

    // MARK: - Init

    public init(
        client: any AnthropicClientProtocol,
        credentialsStore: any AICloudCredentialsStore,
        intentBroker: BonjourChatIntentBroker = BonjourChatIntentBroker()
    ) {
        self.client = client
        self.credentialsStore = credentialsStore
        self.intentBroker = intentBroker
    }

    // MARK: - Limits

    /// Same in-memory bubble cap as the on-device session — see
    /// ``BonjourChatSession.maxInMemoryMessageCount`` for the
    /// rationale. Kept identical so the two backends produce
    /// indistinguishable scrollback behavior.
    static let maxInMemoryMessageCount = 500

    /// Max tokens per Claude response. Sized generously — Claude's
    /// 200K context window doesn't pressure the chat surface the
    /// way Apple Foundation Models' ~4K does, so the runaway-
    /// generation hardening (token cap, ENUMERATION RULES) that
    /// matters on-device is less critical here. Still bound the
    /// response so a model glitch can't run a single chat turn
    /// for thousands of tokens.
    static let maximumResponseTokensPerTurn = 1024

    // MARK: - Prewarm

    /// Builds the system instructions block ahead of the user's
    /// first send so suggestion-tap latency doesn't include the
    /// cost of constructing the prompt. Idempotent — once the
    /// block exists and matches current preferences, subsequent
    /// calls are no-ops.
    ///
    /// Network calls don't happen here; the system block isn't
    /// sent to Anthropic until the user actually sends a message.
    /// Prompt caching kicks in on the *second* request after the
    /// session lives long enough for Anthropic's cache to retain
    /// the prefix.
    public func prewarm() {
        guard systemBlock == nil
                || currentResponseLengthSnapshot != responseLength
                || currentModel != selectedModel else {
            return
        }

        let instructions = BonjourChatPromptBuilder.systemInstructions(
            responseLength: responseLength
        )
        systemBlock = AnthropicSystemBlock(
            text: instructions,
            cacheControl: .ephemeral
        )
        currentResponseLengthSnapshot = responseLength
        currentModel = selectedModel
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
        // session, even though Anthropic doesn't drive tool calls
        // in v1.
        intentBroker.resetToolCallCount()

        prewarm()
        guard let apiKey = readAPIKey() else { return }
        let systemBlock = cachedSystemBlock()
        let turnText = composeTurn(trimmed: trimmed, context: context)

        conversationHistory.append(AnthropicMessage(role: .user, content: turnText))
        let assistantId = UUID()
        messages.append(BonjourChatMessage(id: assistantId, role: .assistant, content: ""))

        let request = AnthropicMessageRequest(
            model: selectedModel.rawValue,
            maxTokens: Self.maximumResponseTokensPerTurn,
            stream: true,
            system: [systemBlock],
            messages: conversationHistory
        )

        await drainStream(request: request, apiKey: apiKey, assistantId: assistantId)
    }

    // MARK: - Send Helpers

    /// Reads the Anthropic API key from the credentials store,
    /// surfacing a localized `.missingCredentials` error on
    /// `self.error` and returning `nil` when the user has
    /// signed out mid-session.
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

    /// Returns the current cached system block, building a
    /// fallback one if `prewarm()` somehow didn't run first.
    /// `prewarm()` is always called by `send`, so the fallback
    /// is defensive — the type system can't verify the
    /// assignment so we coalesce rather than force-unwrap.
    private func cachedSystemBlock() -> AnthropicSystemBlock {
        systemBlock ?? AnthropicSystemBlock(
            text: BonjourChatPromptBuilder.systemInstructions(responseLength: responseLength),
            cacheControl: .ephemeral
        )
    }

    /// Composes the user-turn text via
    /// `BonjourChatPromptBuilder.userTurn(...)` — the same shape
    /// the on-device session uses, so context injection /
    /// referenced descriptions / numbering rules behave
    /// identically across backends.
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

    /// Consumes the Anthropic stream into the placeholder
    /// assistant message. Persists the completed text into
    /// `conversationHistory` on success; rolls the placeholder
    /// (and the matching user turn) back on error or
    /// cancellation so a retry doesn't submit a doubled
    /// history.
    private func drainStream(
        request: AnthropicMessageRequest,
        apiKey: String,
        assistantId: UUID
    ) async {
        var collectedAssistantText = ""
        do {
            for try await chunk in client.streamMessage(request: request, apiKey: apiKey) {
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
                Anthropic stream failed — \
                kind: \(String(describing: error)), \
                description: \(error.localizedDescription)
                """
            )
            self.error = error.localizedDescription
            self.errorAction = Self.makeErrorAction(for: error)
            rollBackTurn(assistantId: assistantId)
        }
    }

    /// Maps a stream failure to an optional user-facing remediation.
    ///
    /// Six cases produce an action; everything else returns `nil`
    /// because there's no URL or in-app affordance that would help
    /// (the banner still renders the message, just without a
    /// button). Routing per case:
    /// - ``AICloudError/creditBalanceTooLow`` → billing console.
    /// - ``AICloudError/invalidCredentials`` → in-app sign-in
    ///   sheet (which itself links to the keys console).
    /// - ``AICloudError/permissionDenied`` → plans console.
    /// - ``AICloudError/contextWindowExceeded`` → clear chat.
    /// - ``AICloudError/serviceOverloaded`` → status page.
    /// - ``AICloudError/networkUnavailable`` → in-app retry.
    private static func makeErrorAction(for error: Error) -> ChatErrorAction? {
        guard let aiError = error as? AICloudError else { return nil }
        switch aiError {
        case .creditBalanceTooLow:
            return urlAction(
                "https://console.anthropic.com/settings/billing",
                label: Strings.Chat.openBilling,
                hint: Strings.Accessibility.chatOpenBillingHint
            )
        case .invalidCredentials:
            return ChatErrorAction(
                kind: .openSignIn,
                label: Strings.Chat.signInAgain,
                accessibilityHint: Strings.Accessibility.chatSignInAgainHint
            )
        case .permissionDenied:
            return urlAction(
                "https://console.anthropic.com/settings/plans",
                label: Strings.Chat.openPlans,
                hint: Strings.Accessibility.chatOpenPlansHint
            )
        case .contextWindowExceeded:
            return ChatErrorAction(
                kind: .clearChat,
                label: Strings.Chat.clearHistory,
                accessibilityHint: Strings.Accessibility.chatErrorClearChatHint
            )
        case .serviceOverloaded:
            return urlAction(
                "https://status.anthropic.com",
                label: Strings.Chat.openStatusPage,
                hint: Strings.Accessibility.chatOpenStatusPageHint
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
                .invalidRequest,
                .decodingFailure,
                .keychainFailure,
                .cancelled,
                .unexpectedStatus:
            return nil
        }
    }

    /// Builds a ``ChatErrorAction`` from a hard-coded URL string.
    /// The URLs in `makeErrorAction(for:)` are all known-valid
    /// Anthropic console paths, so a missing `URL(string:)` result
    /// would be a programming error — but we coalesce to `nil`
    /// rather than force-unwrap so a typo in a future addition
    /// can't crash the chat surface.
    private static func urlAction(
        _ urlString: String,
        label: LocalizedStringResource,
        hint: LocalizedStringResource
    ) -> ChatErrorAction? {
        guard let url = URL(string: urlString) else { return nil }
        return ChatErrorAction(url: url, label: label, accessibilityHint: hint)
    }

    /// Either persists the completed assistant text into
    /// `conversationHistory`, or — when the response was empty
    /// — rolls the no-op exchange out of both queues so the
    /// next send doesn't accumulate a hollow turn.
    private func finalizeAssistantTurn(text: String, assistantId: UUID) {
        if text.isEmpty {
            rollBackTurn(assistantId: assistantId)
        } else {
            conversationHistory.append(AnthropicMessage(role: .assistant, content: text))
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
    /// ``error`` — the two are a paired surface and must
    /// disappear together when the user commits to a follow-up
    /// send. Without this override, the protocol's default would
    /// clear only ``error``; the banner would briefly render
    /// message-less-but-still-actionable, which reads as a
    /// rendering bug.
    public func clearError() {
        error = nil
        errorAction = nil
    }

    // MARK: - Reset

    public func reset() {
        messages.removeAll()
        conversationHistory.removeAll()
        systemBlock = nil
        currentResponseLengthSnapshot = nil
        currentModel = nil
        lastContextBlock = nil
        error = nil
        errorAction = nil
        isGenerating = false
        intentBroker.consume()
    }

    // MARK: - Restore

    public func restore(messages: [BonjourChatMessage]) {
        self.messages = messages
        // We do NOT reconstruct the Anthropic-side history from
        // these messages — they may carry locally-rejected turns
        // we deliberately kept out of the model's context, and
        // re-running them through the API would re-bill the user.
        // Same trade-off the on-device session documents.
        conversationHistory.removeAll()
        systemBlock = nil
        currentResponseLengthSnapshot = nil
        currentModel = nil
        lastContextBlock = nil
        error = nil
        errorAction = nil
        isGenerating = false
    }

    // MARK: - Model Selection

    /// The model the session sends to. Reads through to the
    /// `currentModel` snapshot — set by ``prewarm()`` — falling
    /// back to ``AnthropicModel/default`` for the first turn.
    ///
    /// Held as a stored snapshot rather than reading
    /// `PreferencesStore` directly so the session stays
    /// preferences-store-agnostic; the consumer
    /// (`BonjourChatSessionFactory` or its cloud-aware future
    /// sibling) decides when to inject which model.
    public var selectedModel: AnthropicModel = .default
}
