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

    /// Stable ID for the empty-state section. Used as a scroll
    /// anchor when the chat is cleared so the ScrollView jumps
    /// back to the top and the suggestions are immediately
    /// visible again.
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
    /// helper on `BonjourChatViewModel`. That keeps this
    /// function a thin assembly of declarative bindings instead
    /// of a nest of inline closures, and lets each scroll
    /// behavior be documented next to the rule that triggers it.
    /// The helpers mutate VM state
    /// (`hasScrolledFirstUserMessage`, `pendingClear`) and so
    /// live on the VM where they're testable.
    ///
    /// `function_body_length` is disabled locally because the
    /// six `.onChange` modifiers are an intrinsically chained
    /// expression — splitting just for line count would shatter
    /// the modifier chain into per-handler helpers that thread
    /// `proxy` through generics for no structural benefit.
    @ViewBuilder
    // swiftlint:disable:next function_body_length
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
            // `scrollDismissesKeyboard` is unavailable on visionOS
            // — the Vision Pro uses a floating virtual keyboard
            // that doesn't need an in-scroll-view dismiss gesture.
            #if !os(visionOS)
            .scrollDismissesKeyboard(.interactively)
            #endif
            .onChange(of: session.messages.first?.id) { _, firstId in
                viewModel.scrollFirstUserMessageToTop(
                    firstId: firstId,
                    proxy: proxy,
                    reduceMotion: reduceMotion
                )
            }
            .onChange(of: session.messages.last?.id) { _, _ in
                viewModel.scrollLatestMessageToBottom(
                    session: session,
                    proxy: proxy,
                    duration: 0.3,
                    reduceMotion: reduceMotion
                )
            }
            .onChange(of: session.messages.last?.content) {
                viewModel.scrollLatestMessageToBottom(
                    session: session,
                    proxy: proxy,
                    duration: 0.15,
                    reduceMotion: reduceMotion
                )
            }
            .onChange(of: isInputFocused) { _, focused in
                viewModel.scrollLatestMessageAboveKeyboard(
                    focused: focused,
                    session: session,
                    proxy: proxy,
                    reduceMotion: reduceMotion
                )
            }
            .onChange(of: viewModel.pendingClear) { _, pending in
                viewModel.runPendingClearSequence(
                    pending: pending,
                    session: session,
                    proxy: proxy,
                    anchorID: Self.emptyStateAnchorID,
                    reduceMotion: reduceMotion
                )
            }
            .onChange(of: session.messages.isEmpty) { _, isEmpty in
                viewModel.snapToEmptyStateIfNeeded(
                    isEmpty: isEmpty,
                    proxy: proxy,
                    anchorID: Self.emptyStateAnchorID
                )
            }
        }
        .animation(
            viewModel.messageTransitionAnimation(reduceMotion: reduceMotion),
            value: session.messages.count
        )
    }

    /// The scrollable content of the chat surface. Always contains
    /// the empty-state intro + suggestions (so they're available
    /// as a scroll target both before the first send and after a
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
                    insertion: viewModel.messageInsertionTransition(
                        for: message.role,
                        reduceMotion: reduceMotion
                    ),
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
                    // the error signal are excluded.
                    .accessibilityLabel(Strings.Accessibility.error(error))
            }
        }
        .padding()
    }

    // MARK: - Long-Conversation Banner

    /// Subtle informational pill rendered at the top of the
    /// message list once the accumulated transcript crosses the
    /// `isLongConversation` heuristic. Designed to be passive —
    /// no tap action, no dismiss button. The user already has
    /// the toolbar's Clear button as their action; this just
    /// signals "you're getting close to where the model may
    /// degrade".
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

                    // Always show the typing indicator while this
                    // assistant message is still being generated —
                    // even after the first tokens have arrived. The
                    // model can pause mid-response, and without a
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

    /// Returns whether the given message is the one currently
    /// being streamed. True when the session is actively
    /// generating and this is the last message in the
    /// conversation and it's from the assistant.
    fileprivate func isStreaming(
        _ message: BonjourChatMessage,
        in session: any BonjourChatSessionProtocol
    ) -> Bool {
        guard session.isGenerating else { return false }
        guard message.role == .assistant else { return false }
        return session.messages.last?.id == message.id
    }
}
