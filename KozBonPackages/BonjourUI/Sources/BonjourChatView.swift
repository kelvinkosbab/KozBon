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

// swiftlint:disable type_body_length file_length
// Chat is a single cohesive surface — message list, empty-state suggestions,
// streaming typing indicator, platform-gated keyboard handling, compose bar,
// send logic, and haptic forwarding all share tightly-coupled view state
// (`inputText`, `isInputFocused`, `reduceMotion`, `session`,
// `sentenceHapticTracker`). Splitting across multiple types would force
// that state into bindings and parameter drilling for no structural
// benefit. The detection logic that *can* stand alone (completed-sentence
// counting and its state machine) has already been extracted to
// `SentenceHapticTracker`.

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

    /// Incremented on every successful send. Drives the `.sensoryFeedback`
    /// modifier below so each submit produces a tactile tap confirming the
    /// message was dispatched. Tracked as a monotonic counter rather than a
    /// boolean so consecutive sends reliably trigger the feedback — the
    /// modifier only fires on an actual value change.
    @State private var submitCount: Int = 0

    /// Drives the light per-sentence haptic that plays while the assistant
    /// streams a response. All detection and bookkeeping lives inside
    /// `SentenceHapticTracker` so this view can stay focused on
    /// presentation. The view just forwards content/id/isGenerating
    /// changes in via `.onChange` and binds `.sensoryFeedback` to the
    /// tracker's `tickCount`.
    @State private var sentenceHapticTracker = SentenceHapticTracker()

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
            Group {
                if let session {
                    // `.safeAreaInset(edge: .bottom)` attaches the compose bar
                    // to the bottom of the scroll view *without* clipping the
                    // scrollable content above it. The system keeps extending
                    // the scroll region under the inset view, so messages
                    // flow behind the input bar as the user scrolls.
                    //
                    // On iOS 26+ the text field and send button apply their
                    // own Liquid Glass backgrounds, so the outer bar must
                    // stay transparent — otherwise an extra `.bar` material
                    // layer sits behind the inner glass and the effect
                    // reads as frosted material instead of clear glass.
                    // `.composeBarBackgroundForLegacySystems()` keeps `.bar`
                    // on older iOS/macOS and on visionOS (where there's no
                    // Liquid Glass) so content still has visual separation
                    // from the compose area.
                    messageList(session: session)
                        .safeAreaInset(edge: .bottom, spacing: 0) {
                            inputBar(session: session)
                                .composeBarBackgroundForLegacySystems()
                        }
                } else {
                    ContentUnavailableView(
                        String(localized: Strings.Chat.emptyTitle),
                        systemImage: Iconography.chat,
                        description: Text(Strings.Chat.emptySubtitle)
                    )
                }
            }
            // Declaring a navigation title — even in inline mode — gives iOS
            // a real navigation bar to render. Without it the scroll view
            // rides all the way to the top of the screen, which on iPhone
            // clips the Dynamic Island and bleeds into the status bar.
            // With an inline title the iOS 26 Liquid Glass material fades
            // content behind the bar cleanly as the user scrolls up.
            .navigationTitle(chatNavigationTitle)
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            // Trailing "Clear" affordance — only surfaces once the
            // user has actually started a conversation. On the
            // empty landing screen there's nothing to clear, and
            // the button would just be visual noise.
            //
            // Implemented as a `Menu` (not a `confirmationDialog`)
            // so the popover anchors to the trash icon itself
            // rather than floating in arbitrary list positions on
            // iPad/Mac/visionOS — and so the destructive role on
            // the inner button gives the user a clear "this is
            // serious" cue. The two-tap gesture (open menu →
            // tap "Clear chat") IS the confirmation step; an
            // additional dialog on top would just be modal noise.
            .toolbar {
                if let session, !session.messages.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button(role: .destructive) {
                                // Resetting the session clears
                                // `messages`, which flips the
                                // `messages.isEmpty` branch in
                                // `messageList(...)` and animates
                                // the user back to the empty-state
                                // landing view with the suggested
                                // prompts.
                                session.reset()
                                isInputFocused = false
                            } label: {
                                Label(
                                    String(localized: Strings.Chat.clearHistory),
                                    systemImage: Iconography.clearChat
                                )
                            }
                        } label: {
                            Label(
                                String(localized: Strings.Chat.clearHistory),
                                systemImage: Iconography.clearChat
                            )
                        }
                        // `Color.red` resolves to `systemRed`, which
                        // adapts to increase-contrast and dark-mode
                        // automatically. Tints the toolbar glyph so
                        // the destructive intent reads at a glance,
                        // before the menu is even opened.
                        .tint(.red)
                        .accessibilityHint(String(localized: Strings.Accessibility.chatClearHistoryHint))
                        .accessibilityIdentifier("chat_clear_button")
                    }
                }
            }
            // Tactile confirmation that a message was dispatched, plus a
            // lighter tap for each sentence the model completes while
            // streaming. The hierarchy is: `.medium` for submit (discrete
            // action) > `.light` for sentence tick (ambient progress), so
            // the user can feel both without them competing.
            //
            // `.sensoryFeedback(_:trigger:)` is iOS 17+ / macOS 14+ but
            // visionOS-26-only, and our visionOS deployment target is 2.0.
            // Vision Pro devices don't have a taptic engine anyway, so
            // gating these out on visionOS costs nothing in practice.
            #if !os(visionOS)
            .sensoryFeedback(.impact(weight: .medium), trigger: submitCount)
            .sensoryFeedback(.impact(weight: .light), trigger: sentenceHapticTracker.tickCount)
            #endif
            .onChange(of: session?.messages.last?.id) { _, newId in
                sentenceHapticTracker.onMessageIdChanged(newId)
            }
            .onChange(of: session?.messages.last?.content) { _, _ in
                forwardStreamingStateToHapticTracker()
            }
            .onChange(of: session?.isGenerating) { _, _ in
                forwardStreamingStateToHapticTracker()
            }
            // The Chat conversation persists for the lifetime of the
            // app process. Switching tabs and coming back lands the
            // user back on whatever exchange they had going — the same
            // mental model as Messages, Notes, etc. The conversation
            // is only cleared when the OS reclaims the app from
            // memory (cold launch).
            //
            // We deliberately don't call `session?.reset()` here. The
            // only thing this hook now does is make sure the network
            // scanner is running so the chat context has fresh data
            // for the next user turn. `viewModel.load()` has its own
            // `isProcessing` guard, so calling it while Discover is
            // already scanning is a no-op.
            .onAppear {
                viewModel.load()
            }
            // Page-level handle for UI tests so a test can find the
            // Chat tab without needing to know its current nav title
            // (which is platform-dependent: "Chat" on iOS, "Explore"
            // on macOS/visionOS).
            .accessibilityIdentifier("chat_page")
        }
    }

    /// Forwards the current streaming state into the sentence-haptic
    /// tracker. Bails when the last message isn't an assistant turn so
    /// user-submitted messages don't accidentally fire sentence haptics
    /// (the submit action has its own dedicated haptic above).
    private func forwardStreamingStateToHapticTracker() {
        guard let session,
              let lastMessage = session.messages.last,
              lastMessage.role == .assistant else { return }
        sentenceHapticTracker.onStreamingStateChanged(
            content: lastMessage.content,
            isFinal: !session.isGenerating
        )
    }

    /// The localized title shown in the inline navigation bar.
    ///
    /// Matches the tab label: "Chat" on iOS, "Explore" on macOS and visionOS
    /// (where the surface is positioned as a discovery tool rather than a
    /// messaging thread). Keeping this in sync with `TopLevelDestination.chat`
    /// is important so the nav bar title and the tab bar label don't disagree.
    private var chatNavigationTitle: String {
        #if os(macOS) || os(visionOS)
        String(localized: Strings.Tabs.explore)
        #else
        String(localized: Strings.Tabs.chat)
        #endif
    }

    // MARK: - Message List

    // The three `.onChange` handlers below all coordinate scroll position
    // through the same `ScrollViewProxy` captured by `ScrollViewReader`.
    // Extracting any of them would push the proxy through another
    // function for no structural benefit, so we disable the length rule
    // locally — same precedent as the file-level `type_body_length` and
    // `file_length` disables above.
    @ViewBuilder
    // swiftlint:disable:next function_body_length
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
                                    // Without this, VoiceOver reads the raw
                                    // error text and users relying on the red
                                    // color as the error signal are excluded.
                                    // Matches the `Strings.Accessibility.error`
                                    // format used throughout the rest of the
                                    // app (CreateTxtRecordView, BroadcastView).
                                    .accessibilityLabel(Strings.Accessibility.error(error))
                            }
                        }
                        .padding()
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
                    // When the user taps into the compose field, scroll the
                    // latest message to the bottom of the visible region so
                    // it sits right above the keyboard — without this the
                    // keyboard slides up and covers whatever the user was
                    // reading, leaving no context as they type.
                    //
                    // A ~300ms delay lets the keyboard's safe-area insets
                    // propagate before we compute the scroll position;
                    // scrolling synchronously with the focus change would
                    // use the pre-keyboard layout and leave the last
                    // message clipped under the keyboard.
                    .onChange(of: isInputFocused) { _, focused in
                        guard focused, let last = session.messages.last else { return }
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(300))
                            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) {
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
                // Combine the icon + title + subtitle into one VoiceOver
                // element so swipe navigation doesn't treat them as three
                // unrelated fragments. The icon is decorative (hidden),
                // the title carries the `.isHeader` trait so rotor
                // navigation lets users jump to it, and the combined
                // element's label is the title + subtitle read together.
                VStack(alignment: .leading, spacing: 8) {
                    Image.appleIntelligence
                        .font(.largeTitle)
                        .foregroundStyle(Color.kozBonBlue)
                        .accessibilityHidden(true)
                    Text(Strings.Chat.emptyTitle)
                        .font(.title2).bold()
                        .accessibilityAddTraits(.isHeader)
                    Text(Strings.Chat.emptySubtitle)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("chat_empty_state")

                VStack(spacing: 8) {
                    suggestionButton(
                        text: String(localized: Strings.Chat.suggestion1),
                        identifier: "chat_suggestion_1",
                        session: session
                    )
                    suggestionButton(
                        text: String(localized: Strings.Chat.suggestion2),
                        identifier: "chat_suggestion_2",
                        session: session
                    )
                    suggestionButton(
                        text: String(localized: Strings.Chat.suggestion3),
                        identifier: "chat_suggestion_3",
                        session: session
                    )
                    suggestionButton(
                        text: String(localized: Strings.Chat.suggestion4),
                        identifier: "chat_suggestion_4",
                        session: session
                    )
                    suggestionButton(
                        text: String(localized: Strings.Chat.suggestion5),
                        identifier: "chat_suggestion_5",
                        session: session
                    )
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private func suggestionButton(
        text: String,
        identifier: String,
        session: any BonjourChatSessionProtocol
    ) -> some View {
        Button {
            Task { await sendMessage(text, using: session) }
        } label: {
            HStack {
                Text(text)
                    .multilineTextAlignment(.leading)
                Spacer()
                Image.arrowUpRight
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding()
            .background(Color.kozBonBlue.opacity(0.1))
            .cornerRadius(12)
            // Explicitly set the hit-test shape to match the visible
            // pill. `.buttonStyle(.plain)` otherwise follows the label's
            // intrinsic bounds, which with multi-line text + spacer is
            // usually correct but can miss tall empty regions on
            // wrapped suggestions. Matching the shape to the background
            // keeps the whole card tappable.
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(text)
        .accessibilityHint(String(localized: Strings.Accessibility.chatSuggestionHint))
        .accessibilityIdentifier(identifier)
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
            // `.roundedBorder` renders a system-fixed height that looked too
            // thin for a chat surface. Switch to `.plain` and draw our own
            // padded capsule so the field has the same comfortable touch
            // depth as an iMessage compose bar, and so it grows cleanly
            // when the user types a multi-line message.
            //
            // On iOS 26+ the `.glassOrMaterialBackground` helper applies
            // Liquid Glass; older systems get `.ultraThinMaterial` instead.
            // Either way there is no solid tinted fill — the field
            // visually rides on top of whatever sits behind the compose
            // bar (the streaming chat messages blur through it cleanly).
            // Single-line (no `axis: .vertical`). iOS treats return as a
            // newline on a vertical TextField even with `.submitLabel(.send)`,
            // which is why the keyboard's Send key was producing a stray
            // `\n` in the input instead of submitting. Without the vertical
            // axis, `.onSubmit` fires on return as expected and the Send
            // label on the keyboard actually submits. Users who need to
            // send a long question can still type one — the field scrolls
            // horizontally and the send button remains reachable.
            TextField(
                String(localized: Strings.Chat.inputPlaceholder),
                text: $inputText
            )
            .textFieldStyle(.plain)
            .padding(.horizontal, .space14)
            .padding(.vertical, .space10)
            .glassOrMaterialBackground(
                in: RoundedRectangle(cornerRadius: .radius20, style: .continuous)
            )
            .submitLabel(.send)
            .focused($isInputFocused)
            .disabled(session.isGenerating)
            .accessibilityLabel(String(localized: Strings.Chat.inputPlaceholder))
            .accessibilityHint(String(localized: Strings.Accessibility.chatInputHint))
            .accessibilityIdentifier("chat_input_field")
            .onSubmit {
                Task { await sendMessage(inputText, using: session) }
            }
            // No keyboard-accessory "Done" button. The `scrollDismissesKeyboard
            // (.interactively)` modifier on the message list already lets the
            // user dismiss the keyboard by dragging the chat downward, and
            // tapping `return` / the send button both dispatch the message.
            // A persistent "Done" bar above the keyboard was redundant and
            // competed visually with the compose UI.

            // Fixed-size capsule send button. The height matches the single-
            // line text field height (`.size40` ≈ vertical padding + body line
            // height), so in the common one-line case the field and the button
            // read as a matched pair. The HStack's `alignment: .bottom` then
            // pins the button to the bottom of the text field when the user
            // composes a multi-line message — same behavior as iMessage.
            //
            // Width is deliberately larger than height (`.size56` × `.size40`,
            // ~1.4:1) to give the capsule its horizontal pill shape rather
            // than appearing as a circle.
            //
            // On iOS 26+ the background is a *tinted* Liquid Glass capsule
            // (`.glassEffect(.regular.tint(.kozBonBlue).interactive())`),
            // which preserves the brand color while participating in the
            // glass layer hierarchy and getting system press/hover
            // feedback for free. Older systems fall back to the solid
            // `.kozBonBlue` fill so the primary action still reads.
            Button {
                Task { await sendMessage(inputText, using: session) }
            } label: {
                Image.arrowUp
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    // The glyph is purely decorative — the Button's own
                    // a11y label ("Send") is what VoiceOver should
                    // announce. Hiding the Image keeps the tree clean
                    // and prevents the SF Symbol default name from ever
                    // leaking through in edge cases.
                    .accessibilityHidden(true)
                    .frame(width: .size56, height: .size40)
                    .glassOrTintedBackground(tint: .kozBonBlue, in: Capsule())
                    // Make the entire `.size56 × .size40` capsule tappable,
                    // not just the tiny intrinsic-size arrow glyph at its
                    // center. `.buttonStyle(.plain)` defaults to hit-
                    // testing the label's intrinsic content — with a small
                    // `Image` inside a much larger `.frame`, most of the
                    // visually-filled pill was NOT tappable, and taps near
                    // the capsule edges silently missed. This was the
                    // "follow-up send doesn't work" symptom: users were
                    // hitting the pill, not the glyph.
                    .contentShape(Capsule())
                    .opacity(sendDisabled(session: session) ? 0.4 : 1.0)
                    .animation(
                        reduceMotion ? nil : .easeInOut(duration: 0.15),
                        value: sendDisabled(session: session)
                    )
            }
            .buttonStyle(.plain)
            .disabled(sendDisabled(session: session))
            .accessibilityLabel(String(localized: Strings.Chat.send))
            .accessibilityHint(
                sendDisabled(session: session)
                    ? String(localized: Strings.Accessibility.chatSendDisabledHint)
                    : String(localized: Strings.Accessibility.chatSendHint)
            )
            .accessibilityIdentifier("chat_send_button")
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

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // EVERY send tap gets tactile + visual feedback BEFORE validation
        // runs. Previously a client-side validator rejection silently
        // dropped the input — no haptic, input stayed, keyboard stayed,
        // and on an empty chat the `session.error` that was set was
        // invisible behind the empty-state view. The tap read as broken.
        // Now every tap: fires the submit haptic, clears the input,
        // dismisses the keyboard. What happens next depends on
        // validation, but the tap is never lost.
        submitCount &+= 1
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
            inputText = ""
        }
        isInputFocused = false

        // Client-side pre-filter catches obvious prompt-injection and
        // off-topic patterns without paying model latency. On rejection
        // we render the exchange as a normal chat turn (user message +
        // assistant refusal) — identical to how the model itself would
        // refuse — so the Chat surface stays coherent and the refusal
        // is visible even on a previously-empty chat.
        switch ChatInputValidator.validate(trimmed) {
        case .allowed:
            break
        case .rejected(let reason):
            session.appendLocalRejection(
                userMessage: trimmed,
                refusalText: Self.errorMessage(for: reason)
            )
            return
        }

        let context = BonjourChatPromptBuilder.ChatContext(
            discoveredServices: viewModel.flatActiveServices,
            publishedServices: viewModel.sortedPublishedServices,
            serviceTypeLibrary: BonjourServiceType.fetchAll(),
            lastScanTime: viewModel.lastScanTime,
            isScanning: viewModel.serviceScanner.isProcessing
        )

        // Response length is derived from the user's Detail level
        // preference now — the standalone "Response length" picker was
        // removed because users found the two settings confusing
        // (both seemed to control "how much detail you get"). Basic
        // pairs with .standard, Technical pairs with .thorough.
        let detailLevel = BonjourServicePromptBuilder.ExpertiseLevel(
            rawValue: preferencesStore.aiExpertiseLevel
        ) ?? .basic
        session.responseLength = detailLevel.responseLength

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
