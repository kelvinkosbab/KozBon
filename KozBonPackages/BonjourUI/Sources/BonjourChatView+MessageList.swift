//
//  BonjourChatView+MessageList.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourAI
import BonjourCore
import BonjourLocalization
import BonjourModels

// MARK: - Message List

extension BonjourChatView {

    /// Stable ID for the empty-state section. Used as a scroll anchor
    /// when the chat is cleared so the ScrollView jumps back to the
    /// top and the suggestions are immediately visible again.
    static let emptyStateAnchorID = "chat_empty_state_anchor"

    /// The chat surface is a single ScrollView that ALWAYS contains
    /// the empty-state content (intro + suggestion buttons) plus
    /// any messages. On first send the ScrollView animates the
    /// user's bubble to the top of the viewport — the suggestions
    /// scroll out above. There's no branch swap between an "empty"
    /// and a "populated" surface anymore, so the transition feels
    /// continuous instead of an instant page change.
    ///
    /// Each `.onChange` handler delegates to a small per-event
    /// helper below. That keeps this function a thin assembly of
    /// declarative bindings instead of a nest of inline closures,
    /// and lets each scroll behavior be documented next to the
    /// rule that triggers it.
    @ViewBuilder
    func messageList(session: any BonjourChatSessionProtocol) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                messageListContent(session: session)
            }
            // Announce the scroll region to VoiceOver users as
            // "Conversation" so they know what they're entering
            // when they swipe into it. Also gives UI tests a
            // stable handle on the messages collection.
            .accessibilityLabel(String(localized: Strings.Accessibility.chatConversation))
            .accessibilityIdentifier("chat_message_list")
            // `scrollDismissesKeyboard` is unavailable on visionOS —
            // the Vision Pro uses a floating virtual keyboard that
            // doesn't need an in-scroll-view dismiss gesture.
            #if !os(visionOS)
            .scrollDismissesKeyboard(.interactively)
            #endif
            .onChange(of: session.messages.first?.id) { _, firstId in
                scrollFirstUserMessageToTop(firstId: firstId, proxy: proxy)
            }
            .onChange(of: session.messages.last?.id) { _, _ in
                scrollLatestMessageToBottom(session: session, proxy: proxy, duration: 0.3)
            }
            .onChange(of: session.messages.last?.content) {
                scrollLatestMessageToBottom(session: session, proxy: proxy, duration: 0.15)
            }
            .onChange(of: isInputFocused) { _, focused in
                scrollLatestMessageAboveKeyboard(focused: focused, session: session, proxy: proxy)
            }
            .onChange(of: pendingClear) { _, pending in
                runPendingClearSequence(pending: pending, session: session, proxy: proxy)
            }
            .onChange(of: session.messages.isEmpty) { _, isEmpty in
                snapToEmptyStateIfNeeded(isEmpty: isEmpty, proxy: proxy)
            }
        }
        .animation(messageTransitionAnimation, value: session.messages.count)
    }

    /// The scrollable content of the chat surface. Always contains
    /// the empty-state intro + suggestions (so they're available as
    /// a scroll target both before the first send and after a
    /// Clear), the optional long-conversation banner, the message
    /// bubbles themselves, and any error string.
    @ViewBuilder
    fileprivate func messageListContent(session: any BonjourChatSessionProtocol) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Empty-state intro and suggestion buttons. Always
            // present in the layout so they're available as a
            // scroll target both before the user has sent
            // anything and after a Clear. The `id` lets
            // `proxy.scrollTo` jump back here when the chat is
            // cleared.
            emptyStateContent(session: session)
                .id(Self.emptyStateAnchorID)

            // Passive "long conversation" advisory between the
            // suggestions and the messages, only when the
            // accumulated transcript is approaching the on-device
            // model's context budget.
            if session.messages.isLongConversation {
                longConversationBanner
                    .transition(.opacity)
            }

            ForEach(session.messages) { message in
                messageBubble(
                    message: message,
                    isStreaming: isStreaming(message, in: session)
                )
                .id(message.id)
                .transition(.asymmetric(
                    insertion: messageInsertionTransition(for: message.role),
                    removal: .opacity
                ))
            }

            if let error = session.error {
                Text(error)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
                    .transition(.opacity)
                    // Without this, VoiceOver reads the raw error
                    // text and users relying on the red color as
                    // the error signal are excluded. Matches the
                    // `Strings.Accessibility.error` format used
                    // throughout the rest of the app
                    // (CreateTxtRecordView, BroadcastView).
                    .accessibilityLabel(Strings.Accessibility.error(error))
            }
        }
        .padding()
    }

    // MARK: - Scroll Coordination

    /// Animates the user's FIRST message in a fresh chat to the top
    /// of the viewport, so the suggestion buttons scroll off above.
    /// This is the "browsing → chatting" transition; gated on
    /// `hasScrolledFirstUserMessage` so it fires exactly once per
    /// fresh-chat lifetime.
    fileprivate func scrollFirstUserMessageToTop(firstId: UUID?, proxy: ScrollViewProxy) {
        guard let firstId, !hasScrolledFirstUserMessage else { return }
        hasScrolledFirstUserMessage = true
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.5)) {
            proxy.scrollTo(firstId, anchor: .top)
        }
    }

    /// Scroll-to-bottom for subsequent message arrivals and
    /// streaming token updates. Gated on `count > 2` so the FIRST
    /// exchange (user msg + placeholder, possibly streaming) keeps
    /// the user's bubble pinned at the top — without that gate,
    /// every streamed token would tug the latest content down into
    /// view and the user's question would scroll off-screen during
    /// the first response.
    fileprivate func scrollLatestMessageToBottom(
        session: any BonjourChatSessionProtocol,
        proxy: ScrollViewProxy,
        duration: Double
    ) {
        guard session.messages.count > 2,
              let last = session.messages.last else { return }
        withAnimation(reduceMotion ? nil : .easeOut(duration: duration)) {
            proxy.scrollTo(last.id, anchor: .bottom)
        }
    }

    /// When the user taps into the compose field, scroll the latest
    /// message to the bottom of the visible region so it sits right
    /// above the keyboard. A ~300 ms delay lets the keyboard's
    /// safe-area insets propagate before we compute the scroll
    /// position; scrolling synchronously with the focus change
    /// would use the pre-keyboard layout and leave the last message
    /// clipped under the keyboard.
    fileprivate func scrollLatestMessageAboveKeyboard(
        focused: Bool,
        session: any BonjourChatSessionProtocol,
        proxy: ScrollViewProxy
    ) {
        guard focused, let last = session.messages.last else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }

    /// Runs the toolbar's two-step Clear sequence:
    ///
    ///   1. Animate the ScrollView up to the empty-state anchor
    ///      *while messages are still in place*. The scroll has
    ///      actual distance to cover (the bubbles are still
    ///      occupying the layout above the viewport's current
    ///      position), so the user sees a continuous, smooth
    ///      scroll up instead of bubbles disappearing in place.
    ///
    ///   2. Once the scroll animation has played out, call
    ///      `session.reset()` to wipe `messages`. The bubbles'
    ///      opacity-removal transitions overlap with the tail
    ///      end of the scroll, so the conversation fades away as
    ///      the suggestions land at the top.
    ///
    /// The 450 ms wait matches the scroll animation duration;
    /// tightening it would clip the scroll's tail, lengthening it
    /// would leave a perceptible pause before the bubbles finally
    /// clear.
    fileprivate func runPendingClearSequence(
        pending: Bool,
        session: any BonjourChatSessionProtocol,
        proxy: ScrollViewProxy
    ) {
        guard pending else { return }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.45)) {
            proxy.scrollTo(Self.emptyStateAnchorID, anchor: .top)
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(450))
            session.reset()
            hasScrolledFirstUserMessage = false
            pendingClear = false
        }
    }

    /// Defensive fallback for any path that clears `messages`
    /// directly (rather than going through the toolbar's
    /// `pendingClear` flow). Resets the first-message flag and
    /// snaps the ScrollView back to the top — at this point the
    /// bubbles are already gone, so this scroll is effectively a
    /// no-op visually but keeps the state consistent.
    fileprivate func snapToEmptyStateIfNeeded(isEmpty: Bool, proxy: ScrollViewProxy) {
        guard isEmpty, !pendingClear else { return }
        hasScrolledFirstUserMessage = false
        proxy.scrollTo(Self.emptyStateAnchorID, anchor: .top)
    }

    /// Returns the insertion transition for a newly-inserted message
    /// bubble. Both user and assistant bubbles slide in from the top
    /// edge (motion direction: top → bottom) so the chat surface
    /// reads as a single vertical stream rather than the previous
    /// asymmetric trailing/leading slide which felt jarring next to
    /// the typing indicator.
    ///
    /// User and assistant differ in scale-anchor side only: user
    /// bubbles scale from the trailing edge so the corner closest
    /// to the right-aligned bubble grows last, assistant bubbles
    /// scale from the leading edge for the same effect on the
    /// left. The motion vector is identical for both so streaming
    /// content (the typing indicator inside the assistant bubble)
    /// inherits the same direction without any extra transition
    /// overrides on the inner views.
    fileprivate func messageInsertionTransition(for role: BonjourChatMessage.Role) -> AnyTransition {
        if reduceMotion {
            return .opacity
        }
        let scaleAnchor: UnitPoint = (role == .user) ? .topTrailing : .topLeading
        return .move(edge: .top)
            .combined(with: .opacity)
            .combined(with: .scale(scale: 0.95, anchor: scaleAnchor))
    }

    // MARK: - Long-Conversation Banner

    /// Subtle informational pill rendered at the top of the
    /// message list once the accumulated transcript crosses the
    /// `isLongConversation` heuristic. Designed to be passive —
    /// no tap action, no dismiss button. The user already has
    /// the toolbar's Clear button as their action; this just
    /// signals "you're getting close to where the model may
    /// degrade".
    ///
    /// Uses `.regularMaterial` for a quiet inline-banner feel
    /// rather than the loud red-error style — the situation is
    /// informational, not actually broken.
    fileprivate var longConversationBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            Image.chatEllipsis
                .font(.title3)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(Strings.Chat.longConversationBannerTitle)
                    .font(.subheadline).bold()
                Text(Strings.Chat.longConversationBannerDetail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: .rect(cornerRadius: 12))
        .padding(.horizontal, 4)
        // Combine into a single VoiceOver element with both
        // strings read together — otherwise users hear "Long
        // conversation" first, then have to swipe to discover
        // the explanation.
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }

    // MARK: - Message Bubble

    @ViewBuilder
    fileprivate func messageBubble(message: BonjourChatMessage, isStreaming: Bool) -> some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 40)
                Text(message.content)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.kozBonBlue)
                    .foregroundStyle(.white)
                    .cornerRadius(16)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(Strings.Accessibility.chatUserMessage(message.content))
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    if !message.content.isEmpty {
                        MarkdownContentView(message.content)
                    }

                    // Always show the typing indicator while this assistant message
                    // is still being generated — even after the first tokens have
                    // arrived. The model can pause mid-response, and without a
                    // visible indicator the chat looks frozen.
                    if isStreaming {
                        TypingIndicator()
                            .accessibilityLabel(String(localized: Strings.Accessibility.chatAssistantThinking))
                            .transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
                .accessibilityElement(children: message.content.isEmpty ? .contain : .combine)
                .accessibilityLabel(
                    message.content.isEmpty
                        ? String(localized: Strings.Accessibility.chatAssistantThinking)
                        : Strings.Accessibility.chatAssistantMessage(message.content)
                )
                Spacer(minLength: 40)
            }
        }
    }

    /// Returns whether the given message is the one currently being streamed.
    ///
    /// True when the session is actively generating and this is the last message
    /// in the conversation and it's from the assistant.
    fileprivate func isStreaming(_ message: BonjourChatMessage, in session: any BonjourChatSessionProtocol) -> Bool {
        guard session.isGenerating else { return false }
        guard message.role == .assistant else { return false }
        return session.messages.last?.id == message.id
    }
}
