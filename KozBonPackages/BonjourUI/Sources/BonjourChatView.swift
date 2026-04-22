//
//  BonjourChatView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourAI
import BonjourCore
import BonjourLocalization
import BonjourModels
import BonjourScanning
import BonjourStorage

#if canImport(UIKit)
import UIKit
#endif

// MARK: - BonjourChatView

/// Chat interface for asking the on-device Apple Intelligence assistant about
/// Bonjour services and the KozBon app.
public struct BonjourChatView: View {

    @Environment(\.dependencies) private var dependencies
    @Environment(\.chatSession) private var injectedSession
    @Environment(\.preferencesStore) private var preferencesStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var localSession: (any BonjourChatSessionProtocol)? = Self.makeSession()
    @State private var inputText: String = ""
    @FocusState private var isInputFocused: Bool

    private var messageTransitionAnimation: Animation? {
        reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.75)
    }

    private let viewModel: BonjourServicesViewModel

    /// Creates the Chat view bound to the shared services view model.
    ///
    /// The view model is owned by the app root so that the Chat tab observes the
    /// same scanner delegate as the Discover tab. See ``BonjourServicesViewModel``
    /// for the rationale — two separate view models would race for the single
    /// `weak var delegate` on `BonjourServiceScanner`.
    public init(viewModel: BonjourServicesViewModel) {
        self.viewModel = viewModel
    }

    /// The active session — injected if available, otherwise a local instance.
    private var session: (any BonjourChatSessionProtocol)? {
        injectedSession ?? localSession
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let session {
                    messageList(session: session)
                    Divider()
                    inputBar(session: session)
                } else {
                    ContentUnavailableView(
                        String(localized: Strings.Chat.emptyTitle),
                        systemImage: Iconography.chat,
                        description: Text(Strings.Chat.emptySubtitle)
                    )
                }
            }
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            // No clear-history toolbar button: the chat is intentionally
            // presented as a continuous conversation where earlier turns are
            // remembered. A prominent "clear" affordance in the primary toolbar
            // position undermined that chatbot feel. The session still resets
            // on app launch, which is the expected lifetime for on-device
            // multi-turn chats with no persistence.
        }
    }

    // MARK: - Message List

    @ViewBuilder
    private func messageList(session: any BonjourChatSessionProtocol) -> some View {
        ZStack {
            if session.messages.isEmpty {
                emptyState(session: session)
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
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
                            }
                        }
                        .padding()
                    }
                    // `scrollDismissesKeyboard` is unavailable on visionOS —
                    // the Vision Pro uses a floating virtual keyboard that
                    // doesn't need an in-scroll-view dismiss gesture.
                    #if !os(visionOS)
                    .scrollDismissesKeyboard(.interactively)
                    #endif
                    .transition(.opacity)
                    .onChange(of: session.messages.last?.id) {
                        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.3)) {
                            if let last = session.messages.last {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: session.messages.last?.content) {
                        if let last = session.messages.last {
                            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.15)) {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
        .animation(messageTransitionAnimation, value: session.messages.isEmpty)
        .animation(messageTransitionAnimation, value: session.messages.count)
    }

    /// Returns an asymmetric insertion transition that visually distinguishes
    /// user messages (slide in from trailing) from assistant messages (fade in from leading).
    private func messageInsertionTransition(for role: BonjourChatMessage.Role) -> AnyTransition {
        if reduceMotion {
            return .opacity
        }
        switch role {
        case .user:
            return .move(edge: .trailing)
                .combined(with: .opacity)
                .combined(with: .scale(scale: 0.9, anchor: .bottomTrailing))
        case .assistant:
            return .move(edge: .leading)
                .combined(with: .opacity)
                .combined(with: .scale(scale: 0.95, anchor: .bottomLeading))
        }
    }

    // MARK: - Empty State with Suggestions

    @ViewBuilder
    private func emptyState(session: any BonjourChatSessionProtocol) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: Iconography.appleIntelligence)
                        .font(.largeTitle)
                        .foregroundStyle(Color.kozBonBlue)
                    Text(Strings.Chat.emptyTitle)
                        .font(.title2).bold()
                    Text(Strings.Chat.emptySubtitle)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 8) {
                    suggestionButton(text: String(localized: Strings.Chat.suggestion1), session: session)
                    suggestionButton(text: String(localized: Strings.Chat.suggestion2), session: session)
                    suggestionButton(text: String(localized: Strings.Chat.suggestion3), session: session)
                    suggestionButton(text: String(localized: Strings.Chat.suggestion4), session: session)
                    suggestionButton(text: String(localized: Strings.Chat.suggestion5), session: session)
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private func suggestionButton(text: String, session: any BonjourChatSessionProtocol) -> some View {
        Button {
            Task { await sendMessage(text, using: session) }
        } label: {
            HStack {
                Text(text)
                    .multilineTextAlignment(.leading)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding()
            .background(Color.kozBonBlue.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(text)
        .accessibilityHint(String(localized: Strings.Accessibility.chatSuggestionHint))
    }

    // MARK: - Message Bubble

    @ViewBuilder
    private func messageBubble(message: BonjourChatMessage, isStreaming: Bool) -> some View {
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
    private func isStreaming(_ message: BonjourChatMessage, in session: any BonjourChatSessionProtocol) -> Bool {
        guard session.isGenerating else { return false }
        guard message.role == .assistant else { return false }
        return session.messages.last?.id == message.id
    }

    // MARK: - Input Bar

    @ViewBuilder
    private func inputBar(session: any BonjourChatSessionProtocol) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField(
                String(localized: Strings.Chat.inputPlaceholder),
                text: $inputText,
                axis: .vertical
            )
            .textFieldStyle(.roundedBorder)
            .lineLimit(1...5)
            .submitLabel(.send)
            .focused($isInputFocused)
            .disabled(session.isGenerating)
            .accessibilityLabel(String(localized: Strings.Chat.inputPlaceholder))
            .accessibilityHint(String(localized: Strings.Accessibility.chatInputHint))
            .onSubmit {
                Task { await sendMessage(inputText, using: session) }
            }
            // Only iOS has a hardware/software keyboard toolbar placement.
            // macOS has the menu bar, visionOS uses a floating virtual
            // keyboard with its own built-in dismiss affordance — both
            // reject `ToolbarItemPlacement.keyboard`.
            #if os(iOS)
            .toolbar {
                if isInputFocused {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button(String(localized: Strings.Buttons.done)) {
                            isInputFocused = false
                        }
                    }
                }
            }
            #endif

            Button {
                Task { await sendMessage(inputText, using: session) }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
            }
            .disabled(sendDisabled(session: session))
            .accessibilityLabel(String(localized: Strings.Chat.send))
            .accessibilityHint(
                sendDisabled(session: session)
                    ? String(localized: Strings.Accessibility.chatSendDisabledHint)
                    : String(localized: Strings.Accessibility.chatSendHint)
            )
        }
        .padding()
    }

    private func sendDisabled(session: any BonjourChatSessionProtocol) -> Bool {
        session.isGenerating
            || inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Send

    private func sendMessage(_ text: String, using session: any BonjourChatSessionProtocol) async {
        guard !session.isGenerating else { return }

        // Pre-validate the input before sending to the model.
        switch ChatInputValidator.validate(text) {
        case .allowed:
            break
        case .rejected(.empty):
            return
        case .rejected(let reason):
            session.error = Self.errorMessage(for: reason)
            return
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Clear input and dismiss keyboard with animation.
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
            inputText = ""
        }
        isInputFocused = false

        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif

        let context = BonjourChatPromptBuilder.ChatContext(
            discoveredServices: viewModel.flatActiveServices,
            publishedServices: viewModel.sortedPublishedServices,
            serviceTypeLibrary: BonjourServiceType.fetchAll()
        )

        session.responseLength = BonjourServicePromptBuilder.ResponseLength(
            rawValue: preferencesStore.aiResponseLength
        ) ?? .standard

        await session.send(trimmed, context: context)
    }

    /// Returns a localized error message for the given validation rejection reason.
    private static func errorMessage(for reason: ChatInputValidator.Reason) -> String {
        switch reason {
        case .empty:
            return ""
        case .tooLong(let limit):
            return String(format: String(localized: Strings.Chat.errorTooLong), limit)
        case .promptInjection:
            return String(localized: Strings.Chat.errorPromptInjection)
        case .offTopic:
            return String(localized: Strings.Chat.errorOffTopic)
        }
    }

    // MARK: - Session Factory

    /// Creates a chat session for this device.
    ///
    /// In the iOS Simulator, returns a mock that streams lorem ipsum responses
    /// so the chat UI can be tested end-to-end without a real AI device.
    private static func makeSession() -> (any BonjourChatSessionProtocol)? {
        #if targetEnvironment(simulator)
        return SimulatorBonjourChatSession()
        #elseif canImport(FoundationModels)
        if #available(iOS 26, macOS 26, visionOS 26, *) {
            return BonjourChatSession()
        }
        return nil
        #else
        return nil
        #endif
    }
}
