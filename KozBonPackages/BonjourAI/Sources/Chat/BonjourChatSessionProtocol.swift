//
//  BonjourChatSessionProtocol.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - BonjourChatSessionProtocol

/// Protocol for an on-device chat session about Bonjour services and the app.
///
/// Provides an abstraction over `LanguageModelSession` so views can be
/// tested and previewed without requiring FoundationModels.
@MainActor
public protocol BonjourChatSessionProtocol: AnyObject, Observable {

    /// Side channel between assistant tool calls and the chat view's
    /// sheet presentation. Tools publish intents (drafted forms);
    /// the chat view observes ``BonjourChatIntentBroker/pendingIntent``
    /// and presents the matching pre-filled sheet.
    ///
    /// Mock and simulator implementations expose a broker too — they
    /// just don't emit anything into it. The view treats it as an
    /// opaque dependency.
    var intentBroker: BonjourChatIntentBroker { get }

    /// All messages in the current conversation, in chronological order.
    var messages: [BonjourChatMessage] { get }

    /// Whether the assistant is currently generating a response.
    var isGenerating: Bool { get }

    /// An error message if the last send failed.
    var error: String? { get set }

    /// User-actionable remediation paired with ``error`` —
    /// populated when the failure has a specific fix the user
    /// can take outside the app (e.g., add credits to their
    /// Anthropic account). `nil` for errors that are purely
    /// informational. The chat surface renders this as a button
    /// next to the error banner.
    ///
    /// Read-only at the protocol level. Sessions that surface
    /// actionable errors (currently just
    /// `AnthropicBonjourChatSession`) set it internally; Apple
    /// Foundation Models sessions always return `nil` because
    /// their failure modes don't translate to URL-based
    /// remediations.
    var errorAction: ChatErrorAction? { get }

    /// The desired verbosity of assistant responses.
    var responseLength: BonjourServicePromptBuilder.ResponseLength { get set }

    /// Builds the underlying model session ahead of the user's first
    /// send so suggestion-tap latency doesn't include the cost of
    /// model-instruction compilation. Idempotent — once the session
    /// exists, subsequent calls are no-ops until a preference change
    /// invalidates it. Mocks default-implement this as a no-op since
    /// they don't have a real model to warm.
    func prewarm()

    /// Appends a user message to ``messages`` synchronously, without
    /// triggering any model work or fresh-scan plumbing. The chat
    /// view calls this the instant the user taps a suggestion or hits
    /// Send, so the user's bubble shows up immediately — *before*
    /// any awaits that build the model context (e.g.
    /// `BonjourOneShotScanner.run` for live-state questions). The
    /// subsequent ``send(_:context:)`` call must NOT re-append; it
    /// adds the assistant placeholder and starts streaming.
    ///
    /// Implementations are expected to append a
    /// `BonjourChatMessage(role: .user, content: text)` to their
    /// `messages` array.
    func appendUserMessage(_ text: String)

    /// Streams the assistant's response to a user message that's
    /// already in ``messages``.
    ///
    /// Callers must invoke ``appendUserMessage(_:)`` first so the
    /// user's bubble is visible without waiting on this method's
    /// awaits. `send` then appends the assistant placeholder and
    /// runs the model.
    ///
    /// - Parameters:
    ///   - text: The user's message text (trimmed, non-empty), as
    ///     passed to ``appendUserMessage(_:)``. Used to compose the
    ///     model prompt; not appended to ``messages`` again.
    ///   - context: A snapshot of the user's current services and library.
    func send(_ text: String, context: BonjourChatPromptBuilder.ChatContext) async

    /// Appends a user message and an immediate assistant refusal to the
    /// conversation **without hitting the model**. Used when client-side
    /// validation (`ChatInputValidator`) rejects an input.
    ///
    /// Rendering the exchange as real chat turns — rather than silently
    /// dropping the input — keeps the Chat surface coherent: every user
    /// tap produces a visible outcome. Previously, on an empty chat, a
    /// client-rejected send would fall through to `session.error` which
    /// is only rendered once at least one real message exists, so the
    /// user saw nothing happen and reported the send button as broken.
    ///
    /// - Parameters:
    ///   - userMessage: The trimmed user text the validator rejected.
    ///   - refusalText: The localized refusal reason to display as the
    ///     assistant's reply.
    func appendLocalRejection(userMessage: String, refusalText: String)

    /// Clears the chat error banner state without touching the
    /// conversation. Called by the view model the instant the
    /// user commits to a follow-up send so the previous failure's
    /// banner fades out as the new user bubble lands, rather than
    /// lingering on screen until ``send(_:context:)`` finally
    /// runs (which can be ~3 seconds later on live-state questions
    /// that trigger a fresh-scan first).
    ///
    /// Resets both ``error`` and ``errorAction`` atomically — the
    /// two are documented as a paired surface so they must clear
    /// together. The default implementation clears just ``error``
    /// (sufficient for on-device sessions, which always return
    /// `nil` from ``errorAction``); sessions that surface
    /// actionable errors override to clear the action too.
    func clearError()

    /// Clears the conversation history and starts a new session.
    func reset()

    /// Replaces the visible message history with the supplied
    /// messages without contacting the model. Retained as a
    /// protocol affordance for tests and previews that want to seed
    /// a session into a non-empty state; the production app keeps
    /// chat purely in-memory and never calls this in normal use.
    ///
    /// The underlying `LanguageModelSession` is not pre-loaded with
    /// these messages — Apple's `FoundationModels` API doesn't
    /// expose a way to seed transcript content without re-running
    /// it through the model. The user therefore sees the supplied
    /// messages rendered above the compose bar, but the model
    /// itself starts fresh on the next send.
    ///
    /// - Parameter messages: The messages to display, in chronological
    ///   order. An empty array is equivalent to ``reset()``.
    func restore(messages: [BonjourChatMessage])
}

// MARK: - Default Implementations

@MainActor
public extension BonjourChatSessionProtocol {

    /// Mocks and stub implementations don't have a real model session
    /// to warm, so the protocol default no-ops. The production
    /// `BonjourChatSession` overrides this with an actual prewarm.
    func prewarm() {}

    /// Default implementation returns `nil` — only sessions whose
    /// failure modes have URL-based remediations
    /// (`AnthropicBonjourChatSession` and the credit-balance case)
    /// override this. Apple Foundation Models, simulator, and
    /// mock sessions inherit the nil default.
    var errorAction: ChatErrorAction? { nil }

    /// Default implementation clears just ``error`` — sufficient
    /// for sessions whose ``errorAction`` is always `nil`.
    /// `AnthropicBonjourChatSession` overrides to clear its own
    /// ``errorAction`` atomically alongside.
    func clearError() {
        error = nil
    }
}
