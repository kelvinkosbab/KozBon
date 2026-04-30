//
//  BonjourChatSession.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import OSLog
import BonjourModels
import BonjourScanning

/// Subsystem-scoped logger. Errors thrown by the on-device model
/// surface in Console.app under the `com.kozinga.KozBon` subsystem
/// with category `BonjourChatSession`. Used purely for diagnostics —
/// users see the localized error text in the chat surface, not the
/// raw error description.
private let chatSessionLogger = Logger(
    subsystem: "com.kozinga.KozBon",
    category: "BonjourChatSession"
)

#if canImport(FoundationModels)
import FoundationModels

// MARK: - BonjourChatSession

/// On-device chat session for asking questions about the user's network and the KozBon app.
///
/// Uses Apple's FoundationModels framework with a strict system prompt that
/// refuses off-topic queries. Supports **multi-turn conversation** by keeping a
/// single `LanguageModelSession` alive across messages so the model remembers
/// prior turns.
///
/// The system prompt contains only the static rules (scope, refusal, language,
/// tone, length). Live service context is injected into each user turn via a
/// `<context>` preamble when it has materially changed, so follow-up questions
/// always have an up-to-date view of the network without losing conversation
/// history.
@available(iOS 26, macOS 26, visionOS 26, *)
@MainActor
@Observable
public final class BonjourChatSession: BonjourChatSessionProtocol {

    // MARK: - Properties

    public private(set) var messages: [BonjourChatMessage] = []
    public private(set) var isGenerating: Bool = false
    public var error: String?
    public var responseLength: BonjourServicePromptBuilder.ResponseLength = .standard

    /// Side channel through which the assistant's tool calls publish
    /// drafted forms (custom service types, broadcasts) for the chat
    /// view to present. Held by the session so its lifetime matches
    /// the conversation's: the broker survives session recreation
    /// (see ``send(_:context:)``) so a pending unconsumed intent
    /// isn't dropped when, for example, the response-length
    /// preference flips mid-conversation.
    public let intentBroker: BonjourChatIntentBroker

    /// The current session. Created lazily on first send and kept alive across turns
    /// so conversation history is preserved.
    private var session: LanguageModelSession?

    /// The response length used when the current session was created. If it changes,
    /// the session is recreated (history is lost).
    private var sessionResponseLengthSnapshot: BonjourServicePromptBuilder.ResponseLength?

    /// The last context block sent to the model. Used to detect when the live
    /// service context has materially changed.
    private var lastContextBlock: String?

    /// The service-type library snapshot used when constructing the
    /// current session's tools. Re-snapshotted on session recreation
    /// so the broadcast tool's library check sees newly-added custom
    /// types without forcing a re-create on every send.
    private var librarySnapshot: [BonjourServiceType] = []

    /// Optional reference to the app's publish manager. When non-nil,
    /// the stop-broadcast tool reads its live `publishedServices`
    /// set to validate which broadcast the user wants to stop. When
    /// nil (e.g. in tests that don't drive the broadcast tool), the
    /// stop tool reports an empty broadcast list and the model is
    /// instructed to relay the lack of active broadcasts to the user.
    ///
    /// Held weakly to avoid extending the publish manager's lifetime
    /// past the chat session — the manager is owned by the app's
    /// dependency container, not by the session.
    private weak var publishManager: BonjourPublishManagerProtocol?

    public init(
        intentBroker: BonjourChatIntentBroker = BonjourChatIntentBroker(),
        publishManager: BonjourPublishManagerProtocol? = nil
    ) {
        self.intentBroker = intentBroker
        self.publishManager = publishManager
    }

    /// Hard ceiling on the number of messages held in `messages`.
    /// Pure memory hygiene — a marathon conversation can't grow
    /// unbounded RAM accumulation. The underlying FoundationModels
    /// transcript is managed by the framework, not by us.
    static let maxInMemoryMessageCount = 500

    // MARK: - Prewarm

    /// Builds the underlying `LanguageModelSession` ahead of the user's
    /// first send so that tap latency on a recommended-prompt button
    /// (or a hand-typed first message) doesn't include the cost of
    /// model-instruction compilation. Subsequent calls are a no-op:
    /// once the session exists, ``send(_:context:)`` reuses it until
    /// the user changes the response-length preference.
    ///
    /// Safe to call from `.onAppear` — if the user changes the
    /// response-length preference between this call and the first
    /// send, ``send(_:context:)`` notices the snapshot mismatch and
    /// rebuilds the session, paying the cost it just saved. That's
    /// acceptable because preference flips are rare; the common path
    /// (open tab → tap suggestion) gets the win.
    ///
    /// The work is `@MainActor` because `LanguageModelSession` itself
    /// is. Callers should still wrap this in a `Task { @MainActor in
    /// await Task.yield(); session.prewarm() }` so the first frame
    /// paints before the model loads — instruction compilation can
    /// stall main for a noticeable beat on the first call after a
    /// cold launch.
    public func prewarm() {
        guard session == nil || sessionResponseLengthSnapshot != responseLength else { return }
        let instructions = BonjourChatPromptBuilder.systemInstructions(
            responseLength: responseLength
        )
        librarySnapshot = BonjourServiceType.fetchAll()
        session = LanguageModelSession(instructions: instructions)
        sessionResponseLengthSnapshot = responseLength
        lastContextBlock = nil
    }

    // MARK: - Send

    public func send(_ text: String, context: BonjourChatPromptBuilder.ChatContext) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        error = nil
        isGenerating = true
        // `defer` guarantees the flag flips back even if we add an early
        // return in the future. The send button's enabled state depends
        // on `!isGenerating`, so a stuck flag locks the user out of the
        // chat until they leave and re-enter the tab. The previous
        // end-of-function `isGenerating = false` covered the happy
        // path; `defer` covers every path, including any thrown errors
        // that escape the `do { ... } catch { ... }` (none today, but
        // cheap insurance).
        defer { isGenerating = false }

        // Reset the per-turn tool-call quota before we start
        // streaming. Each user turn gets a fresh slot count; if
        // the model exhausts it within the turn (e.g. a runaway
        // create→broadcast→edit loop), subsequent tool calls
        // bounce back with a relayable error.
        intentBroker.resetToolCallCount()

        // Defensive in-memory cap on visible chat history. Disk
        // persistence already trims to 200 messages via
        // `BonjourChatMessage.trimmed(...)`; this trims the
        // in-memory `messages` array to a higher cap so a
        // marathon conversation can't grow unbounded RAM
        // accumulation. Trimming the in-memory array doesn't
        // shrink the underlying `LanguageModelSession` transcript
        // (FoundationModels manages that internally) — it just
        // bounds the SwiftUI list scrollback.
        if messages.count > Self.maxInMemoryMessageCount {
            messages = Array(messages.suffix(Self.maxInMemoryMessageCount))
        }

        // Append the user message as it appears to the user (without the context
        // preamble — the preamble is internal guidance for the model).
        messages.append(BonjourChatMessage(role: .user, content: trimmed))

        // Build or reuse the session. Only recreate when the response-length
        // preference changes (since it affects the static instructions).
        // Changes to the live context do NOT recreate the session — that
        // would destroy conversation history.
        //
        // The same compile-instructions-and-create-session logic is
        // exposed as `prewarm()` for `.onAppear` to call ahead of the
        // user's first tap, so the cost of model-instruction loading
        // doesn't land inside the suggestion-tap latency.
        //
        // Tool registration is intentionally OMITTED. The 5-tool
        // surface (create / edit / delete / broadcast / stop) was
        // costing ~1500 tokens of schema metadata in every model turn
        // — combined with the system prompt and context block, that
        // pushed the on-device Foundation Model past its ~4K context
        // window on fresh first messages, producing
        // `exceededContextWindowSize` errors immediately. The tool
        // *implementations* (`BonjourChatIntent`,
        // `BonjourChatIntentBroker`, `Prepare*Tool.swift`) are kept
        // in source so re-enabling is one line when the context
        // budget allows (newer model generations, or a slimmer
        // per-tool schema). For now the chat is pure Q&A — actions
        // live in the existing in-app UI.
        prewarm()

        // Determine whether to prepend a context preamble.
        let currentContextBlock = BonjourChatPromptBuilder.contextBlock(context: context)
        let isFirstTurn = (lastContextBlock == nil)
        let contextChanged = lastContextBlock != currentContextBlock
        let turnToSend = BonjourChatPromptBuilder.userTurn(
            message: trimmed,
            context: context,
            isFirstTurn: isFirstTurn,
            contextChanged: contextChanged
        )
        lastContextBlock = currentContextBlock

        // Create a placeholder assistant message that we stream into.
        let assistantId = UUID()
        messages.append(BonjourChatMessage(id: assistantId, role: .assistant, content: ""))

        guard let session = session else { return }

        do {
            let stream = session.streamResponse(to: turnToSend)
            for try await partial in stream {
                if let index = messages.firstIndex(where: { $0.id == assistantId }) {
                    messages[index].content = partial.content
                }
            }
        } catch {
            // Diagnostics: capture the actual error in OSLog so we
            // can see what `LanguageModelSession` is throwing
            // under various failure modes (context overflow,
            // guardrail block, transient resource pressure,
            // assets-not-yet-downloaded, etc.). The user sees
            // only the localized description rendered as an
            // error banner.
            //
            // A previous iteration tried to auto-recover from
            // context-overflow errors by string-matching the
            // error description and silently resetting the
            // session. That misfired because the description
            // patterns we matched on overlap with unrelated
            // failure modes — every error ended up routed
            // through the recovery path, and users lost
            // the ability to chat at all. Until we have
            // empirical evidence about what overflow errors
            // actually look like (this OSLog will give us
            // that), we keep the catch path simple: surface
            // the error, let the user decide whether to retry
            // or clear the chat.
            chatSessionLogger.error(
                """
                streamResponse failed — \
                kind: \(String(describing: error), privacy: .public), \
                description: \(error.localizedDescription, privacy: .public)
                """
            )
            self.error = error.localizedDescription
            // Remove the empty assistant placeholder on error so
            // the chat doesn't show a perpetually-empty bubble.
            // The user's own message stays in `messages` — they
            // can see what they asked.
            messages.removeAll { $0.id == assistantId }
        }
        // `isGenerating = false` is handled by the `defer` at the top.
    }

    // MARK: - Local Rejection

    public func appendLocalRejection(userMessage: String, refusalText: String) {
        // Render the exchange as real chat turns so the UI treats it
        // like any other back-and-forth. We deliberately do NOT append
        // these to the underlying `LanguageModelSession` transcript —
        // the model shouldn't see rejected content in its history or
        // it may start drifting toward the rejected topic in follow-ups.
        messages.append(BonjourChatMessage(role: .user, content: userMessage))
        messages.append(BonjourChatMessage(role: .assistant, content: refusalText))
    }

    // MARK: - Reset

    public func reset() {
        messages.removeAll()
        session = nil
        sessionResponseLengthSnapshot = nil
        lastContextBlock = nil
        librarySnapshot = []
        error = nil
        isGenerating = false
        // Drop any pending intent so a stale draft doesn't snap
        // back open after the user clears the chat. The chat view
        // will re-publish if the user asks for the same thing again.
        intentBroker.consume()
    }

    // MARK: - Restore

    public func restore(messages: [BonjourChatMessage]) {
        // Replace the visible history. The underlying
        // `LanguageModelSession` is intentionally cleared — re-seeding
        // it would mean re-sending the prior turns through the model
        // (no public transcript API for direct injection), which is
        // both wasteful and would re-generate responses the user has
        // already seen. See `BonjourChatSessionProtocol.restore` for
        // the trade-off documentation.
        self.messages = messages
        session = nil
        sessionResponseLengthSnapshot = nil
        lastContextBlock = nil
        error = nil
        isGenerating = false
    }
}

#endif
