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

    /// Initialized synchronously at View-init time via
    /// ``init(viewModel:)``. Initializing eagerly (rather than
    /// in `.onAppear`) means the body's first render branch
    /// already has a non-nil session — no two-render path
    /// where the user sees the "requires Apple Intelligence"
    /// `ContentUnavailableView` flash to the chat surface.
    /// That flash was visible on tab activation as ~hundreds
    /// of milliseconds of perceived lag.
    @State private var localSession: (any BonjourChatSessionProtocol)?
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

    /// Set after the first appearance attempts to restore persisted
    /// chat history, so re-entering the tab (which runs `.task`
    /// again) doesn't clobber the user's in-progress conversation
    /// with a stale snapshot from disk.
    @State private var hasAttemptedRestore = false

    /// Set after the first time the message list lands on screen
    /// with a non-empty conversation. Drives the initial
    /// scroll-to-bottom — without it, a user opening the Chat
    /// tab after the persisted history has been restored would
    /// see the TOP of the conversation, which is rarely what
    /// they want. Subsequent tab re-entries don't re-scroll, so
    /// a user who scrolled up to read older context isn't
    /// jumped back to the bottom on every tab switch.
    @State private var hasPerformedInitialScrollToBottom = false

    /// Active "create custom service type" intent surfaced from the
    /// chat assistant's `prepareCustomServiceType` tool. Setting
    /// this presents a pre-filled
    /// `CreateOrUpdateBonjourServiceTypeView` sheet via
    /// `.sheet(item:)`. Cleared when the sheet dismisses so the
    /// same intent can't re-fire on subsequent re-renders.
    @State private var pendingCreateTypeIntent: PendingCreateTypeIntent?

    /// Active "broadcast a service" intent surfaced from the chat
    /// assistant's `prepareBroadcast` tool. Setting this presents a
    /// pre-filled `BroadcastBonjourServiceView` sheet via
    /// `.sheet(item:)`. Cleared when the sheet dismisses.
    @State private var pendingBroadcastIntent: PendingBroadcastIntent?

    /// Active "edit custom service type" payload — the draft type
    /// (with model-suggested edits applied) the form will bind to.
    /// `BonjourServiceType` is `Identifiable` (via its `fullType`),
    /// so `.sheet(item:)` picks it up directly.
    @State private var pendingEditServiceType: BonjourServiceType?

    /// Custom service type the user has been asked to confirm
    /// deletion of. When non-nil, a destructive `.confirmationDialog`
    /// is presented; the user taps Delete or Cancel.
    @State private var pendingDeleteCustomServiceType: BonjourServiceType?

    /// Currently-broadcasting service the user has been asked to
    /// confirm stopping. When non-nil, a destructive
    /// `.confirmationDialog` is presented; the user taps Stop or
    /// Cancel. Holds the `BonjourService` rather than just the
    /// `fullType` so the destructive callback has the same instance
    /// to pass to `publishManager.unPublish(service:)`.
    @State private var pendingStopBroadcastService: BonjourService?

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
    ///
    /// Initializes ``localSession`` eagerly using the publish manager
    /// from `viewModel`. Doing this here (rather than deferring to
    /// `.onAppear`) collapses two SwiftUI render passes into one on
    /// first tab activation — the body's `if let session` branch
    /// resolves to the populated chat surface immediately, instead
    /// of momentarily landing on the empty `ContentUnavailableView`.
    public init(viewModel: BonjourServicesViewModel) {
        self.viewModel = viewModel
        // `State.init(initialValue:)` is consulted exactly once
        // when SwiftUI first allocates this view's state storage;
        // subsequent `init` calls (during parent rebuilds) discard
        // the new factory result. So `Self.makeSession(...)`
        // happens once per Chat-tab lifetime — same cost as the
        // previous lazy path, just paid earlier so the user
        // doesn't see the empty-state flash.
        self._localSession = State(
            initialValue: Self.makeSession(publishManager: viewModel.publishManager)
        )
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
            // mental model as Messages, Notes, etc. By default the
            // conversation is cleared when the OS reclaims the app
            // from memory (cold launch), but the user can opt into
            // cross-launch persistence via the "Persist chat history"
            // toggle in Preferences — in which case the messages are
            // restored once on first appear (see `restoreChatHistoryIfNeeded`).
            //
            // `viewModel.load()` keeps the network scanner running so
            // the chat context has fresh data for the next user turn;
            // it has its own `isProcessing` guard, so calling it while
            // Discover is already scanning is a no-op.
            .onAppear {
                // Session construction has already happened in
                // `init(viewModel:)` — see the doc comment on
                // `localSession` for why eager init avoids the
                // first-render flash. `.onAppear` only runs the
                // ancillary work that's safe to defer until the
                // tab is actually visible.
                //
                // Defer to a Task with `Task.yield()` so the
                // first frame paints before we kick off the
                // scanner load (~150 NetServiceBrowser inits
                // worst case) and JSON decode of any persisted
                // chat history. Both can run after the empty
                // state lands on screen — the user wants to see
                // the suggestion buttons immediately, not wait
                // for restore to land first.
                Task { @MainActor in
                    await Task.yield()
                    viewModel.load()
                    restoreChatHistoryIfNeeded()
                }
            }
            // Save the current conversation when the user sends or
            // when an assistant turn completes. Saving on every token
            // would write to disk ~100 times a second; gating on
            // `messages.count` (changes only on user-send/assistant-
            // placeholder/reset) and `isGenerating` flipping false
            // (the end of an assistant turn) keeps writes to ~2 per
            // turn. Both checks are no-ops when the persistence
            // preference is off.
            .onChange(of: session?.messages.count) { _, _ in
                persistChatHistoryIfNeeded()
            }
            .onChange(of: session?.isGenerating) { _, isGenerating in
                if isGenerating == false {
                    persistChatHistoryIfNeeded()
                }
            }
            // Watch the assistant's intent broker. When a tool call
            // publishes a drafted form, hydrate it into the matching
            // `PendingCreateTypeIntent` / `PendingBroadcastIntent`
            // and clear the broker so the same intent doesn't
            // re-trigger on the next render. The `.sheet(item:)`
            // modifiers below pick up the local state and present
            // the pre-filled form. Sheet dismissal nils out the
            // local state automatically.
            .onChange(of: session?.intentBroker.pendingIntent) { _, newIntent in
                handlePendingIntent(newIntent)
            }
            // Pre-filled "create custom service type" sheet.
            // Reused from the Library tab — same view, same
            // validation, same Core Data persistence path.
            .sheet(item: $pendingCreateTypeIntent) { intent in
                CreateOrUpdateBonjourServiceTypeView(
                    isPresented: Binding(
                        get: { pendingCreateTypeIntent != nil },
                        set: { if !$0 { pendingCreateTypeIntent = nil } }
                    ),
                    prefilledName: intent.name,
                    prefilledType: intent.type,
                    prefilledDetails: intent.details
                )
            }
            // Pre-filled "broadcast a service" sheet. Reused from
            // the Discover tab. Sharing
            // `viewModel.customPublishedServices` with Discover means
            // a broadcast started from chat shows up in the Discover
            // list immediately on dismissal — the same shared state
            // both surfaces already use.
            .sheet(item: $pendingBroadcastIntent) { intent in
                // `@Bindable` on a local var inside the sheet
                // closure produces a binding source from the
                // `@Observable` view model without changing the
                // chat view's stored property to `@Bindable` (which
                // would force the init signature to take a
                // `Bindable<BonjourServicesViewModel>` and ripple
                // through the call sites in `AppCore`).
                @Bindable var bindableViewModel = viewModel
                NavigationStack {
                    BroadcastBonjourServiceView(
                        isPresented: Binding(
                            get: { pendingBroadcastIntent != nil },
                            set: { if !$0 { pendingBroadcastIntent = nil } }
                        ),
                        customPublishedServices: $bindableViewModel.customPublishedServices,
                        prefilledServiceType: intent.serviceType,
                        prefilledPort: intent.port,
                        prefilledDomain: intent.domain,
                        prefilledDataRecords: intent.dataRecords
                    )
                }
            }
            // Pre-filled edit-mode sheet for an existing custom
            // service type. The form's existing edit-init disables
            // the type field but keeps name + description editable;
            // on Done it deletes the (type, transport)-keyed Core
            // Data record and re-saves with the revised values, so
            // a renamed draft cleanly replaces the existing record.
            .sheet(item: $pendingEditServiceType) { _ in
                NavigationStack {
                    CreateOrUpdateBonjourServiceTypeView(
                        isPresented: Binding(
                            get: { pendingEditServiceType != nil },
                            set: { if !$0 { pendingEditServiceType = nil } }
                        ),
                        serviceToUpdate: Binding(
                            get: {
                                // The optional should always be non-nil while
                                // this sheet is presented; the `??` fallback
                                // only fires during the brief dismiss
                                // animation between the user tapping Done
                                // and the sheet collapsing.
                                pendingEditServiceType ?? BonjourServiceType(
                                    name: "",
                                    type: "",
                                    transportLayer: .tcp,
                                    detail: ""
                                )
                            },
                            set: { pendingEditServiceType = $0 }
                        )
                    )
                }
            }
            // Destructive confirmation: delete a custom service
            // type. Phrased as a question matching the established
            // pattern ("Are you sure you want to delete the <name>
            // service type?") so destructive intent reads
            // unambiguously before the user taps red. The dialog's
            // role-based buttons render Delete in red on every
            // platform.
            .confirmationDialog(
                deleteCustomServiceTypeQuestion,
                isPresented: deleteCustomServiceTypeBinding,
                titleVisibility: .visible,
                presenting: pendingDeleteCustomServiceType
            ) { type in
                Button(role: .destructive) {
                    type.deletePersistentCopy()
                    pendingDeleteCustomServiceType = nil
                } label: {
                    Text(Strings.Buttons.delete)
                }
                Button(role: .cancel) {
                    pendingDeleteCustomServiceType = nil
                } label: {
                    Text(Strings.Buttons.cancel)
                }
            }
            // Destructive confirmation: stop an active broadcast.
            // Same phrasing pattern: "Are you sure you want to stop
            // broadcasting <name>?" so the user reads what's about
            // to happen before tapping the red button.
            .confirmationDialog(
                stopBroadcastQuestion,
                isPresented: stopBroadcastBinding,
                titleVisibility: .visible,
                presenting: pendingStopBroadcastService
            ) { service in
                Button(role: .destructive) {
                    let target = service
                    Task {
                        // `unPublish(service:)` is async because the
                        // underlying `NetService.stop()` flushes through
                        // the run loop. Capture the target so we don't
                        // race the @State clearing below.
                        await viewModel.publishManager.unPublish(service: target)
                        // Mirror what the broadcast sheet does on
                        // success — keep the in-memory list aligned
                        // with the publish manager's authoritative state.
                        viewModel.customPublishedServices.removeAll {
                            $0.serviceType.fullType == target.serviceType.fullType
                        }
                    }
                    pendingStopBroadcastService = nil
                } label: {
                    Text(Strings.Buttons.stop)
                }
                Button(role: .cancel) {
                    pendingStopBroadcastService = nil
                } label: {
                    Text(Strings.Buttons.cancel)
                }
            }
            // Page-level handle for UI tests so a test can find the
            // Chat tab without needing to know its current nav title
            // (which is platform-dependent: "Chat" on iOS, "Explore"
            // on macOS/visionOS).
            .accessibilityIdentifier("chat_page")
        }
    }

    // MARK: - Chat History Persistence

    /// Restores a previously-persisted conversation into the active
    /// session, if the user has opted in via the "Persist chat
    /// history" preference and a saved blob exists. No-ops in every
    /// other case (preference off, no saved blob, decoder failure,
    /// session already populated, or restore already attempted in
    /// this view's lifetime).
    ///
    /// The underlying `LanguageModelSession` is intentionally not
    /// pre-loaded — see the doc comment on
    /// `BonjourChatSessionProtocol.restore(messages:)` for the
    /// rationale and the user-facing trade-off.
    private func restoreChatHistoryIfNeeded() {
        guard !hasAttemptedRestore else { return }
        hasAttemptedRestore = true

        guard preferencesStore.persistChatHistory,
              let data = preferencesStore.chatHistory,
              let messages = try? JSONDecoder().decode([BonjourChatMessage].self, from: data),
              !messages.isEmpty,
              let session,
              session.messages.isEmpty else { return }

        session.restore(messages: messages)
    }

    /// Saves the current conversation to user preferences when
    /// persistence is enabled. Triggered from `.onChange` hooks on
    /// `messages.count` and `isGenerating`, both of which change
    /// only on meaningful turn boundaries (not on every streamed
    /// token), so disk I/O stays bounded to ~2 saves per turn.
    ///
    /// Messages are trimmed to the persistence caps
    /// (``UserPreferences/maxStoredChatMessages`` and
    /// ``UserPreferences/maxStoredChatBytes``) before encoding, so
    /// the saved blob can't grow unbounded across long
    /// conversations. The in-memory session is left intact — the
    /// user keeps full scrollback during the launch; only the
    /// next-launch restore is bounded.
    private func persistChatHistoryIfNeeded() {
        guard preferencesStore.persistChatHistory,
              let messages = session?.messages else { return }

        let encoder = JSONEncoder()
        let trimmed = BonjourChatMessage.trimmed(
            messages: messages,
            maxCount: UserPreferences.maxStoredChatMessages,
            maxBytes: UserPreferences.maxStoredChatBytes,
            encoder: encoder
        )

        do {
            preferencesStore.chatHistory = try encoder.encode(trimmed)
        } catch {
            // Encoding failure is non-fatal — there's nowhere
            // meaningful for the user to act on it. The next
            // turn's encode attempt will retry.
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
                            // Passive "long conversation" advisory at
                            // the top of the message list. Surfaces
                            // when the accumulated transcript is
                            // approaching the on-device model's
                            // context budget (per the heuristic in
                            // `Array<BonjourChatMessage>.isLongConversation`).
                            // Honest framing: the model still works,
                            // the user just gets a hint that
                            // responses might degrade and they can
                            // clear if they want a fresh start.
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
                    // First time the populated message list lands
                    // on screen, jump to the most recent message
                    // so the user sees where the conversation
                    // left off — opening Chat after the persisted
                    // history was restored otherwise lands on
                    // the FIRST message, which is rarely what
                    // the user wants.
                    //
                    // No animation: the user just navigated INTO
                    // this view, so an animated scroll would
                    // feel like the chat is moving away from
                    // them rather than greeting them at the
                    // last message.
                    //
                    // 50 ms gives the ScrollView one layout pass
                    // to position its content before we ask it
                    // to scroll — calling `scrollTo` synchronously
                    // in `.onAppear` runs against pre-layout
                    // geometry and silently no-ops on some
                    // platforms.
                    .onAppear {
                        guard !hasPerformedInitialScrollToBottom,
                              let last = session.messages.last else { return }
                        hasPerformedInitialScrollToBottom = true
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(50))
                            proxy.scrollTo(last.id, anchor: .bottom)
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
    private var longConversationBanner: some View {
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
                    suggestionButton(
                        text: String(localized: Strings.Chat.suggestion6),
                        identifier: "chat_suggestion_6",
                        session: session
                    )
                }
            }
            .padding()
        }
        // Same Messages-style interactive keyboard dismiss the
        // populated message list uses. The empty state has its own
        // `ScrollView` for the suggested-prompt buttons, so it
        // needs the same modifier — otherwise typing in the compose
        // bar on the landing screen produces a keyboard the user
        // can't dismiss by swiping. visionOS uses a floating
        // virtual keyboard that doesn't pair with this gesture, so
        // gate it out the same way.
        #if !os(visionOS)
        .scrollDismissesKeyboard(.interactively)
        #endif
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

    // MARK: - Assistant Intent Handling

    /// Hydrate a freshly-published broker intent into the matching
    /// local `@State` so a `.sheet(item:)` modifier picks it up and
    /// presents the pre-filled form. The broker is consumed
    /// immediately so a re-render with the same `pendingIntent`
    /// doesn't re-fire the sheet — once the local state has the
    /// payload, the broker has done its job.
    ///
    /// Each intent case dispatches to a per-case handler so this
    /// method stays a thin switch (see SwiftLint
    /// `cyclomatic_complexity`). The handlers may bail without
    /// publishing local state when a lookup fails (e.g. the user
    /// deleted the referenced type between the tool call and this
    /// handler running) — in that case the broker is still consumed
    /// at the end so the failed intent doesn't keep re-firing.
    private func handlePendingIntent(_ newIntent: BonjourChatIntent?) {
        guard let newIntent else { return }
        guard let session else {
            // No session means no broker either — nothing to consume.
            return
        }

        switch newIntent {
        case let .createCustomServiceType(name, type, _, details):
            handleCreateIntent(name: name, type: type, details: details)
        case let .broadcastService(fullType, port, domain, txtRecords):
            handleBroadcastIntent(
                fullType: fullType,
                port: port,
                domain: domain,
                txtRecords: txtRecords,
                session: session
            )
        case let .editCustomServiceType(currentFullType, suggestedName, suggestedDetails):
            handleEditIntent(
                currentFullType: currentFullType,
                suggestedName: suggestedName,
                suggestedDetails: suggestedDetails,
                session: session
            )
        case let .deleteCustomServiceType(fullType):
            handleDeleteIntent(fullType: fullType, session: session)
        case let .stopBroadcast(fullType):
            handleStopBroadcastIntent(fullType: fullType, session: session)
        }

        session.intentBroker.consume()
    }

    private func handleCreateIntent(name: String, type: String, details: String) {
        // The intent's `transport` field is captured for future
        // form expansion (UDP support); the create-service-type
        // form is currently TCP-only, so it isn't surfaced here.
        pendingCreateTypeIntent = PendingCreateTypeIntent(
            name: name,
            type: type,
            details: details
        )
    }

    private func handleBroadcastIntent(
        fullType: String,
        port: Int?,
        domain: String,
        txtRecords: [TxtRecordDraft],
        session: any BonjourChatSessionProtocol
    ) {
        // Resolve the service type from the user's library
        // (built-ins + custom types). The tool gated on the same
        // lookup, so a missing match here only happens in
        // pathological cases; bail rather than present a useless
        // form so the user isn't left wondering why the type
        // they expected isn't filled in.
        let library = BonjourServiceType.fetchAll()
        guard let resolvedType = library.first(where: { $0.fullType == fullType }) else {
            session.intentBroker.consume()
            return
        }
        let dataRecords = txtRecords.map {
            BonjourService.TxtDataRecord(key: $0.key, value: $0.value)
        }
        pendingBroadcastIntent = PendingBroadcastIntent(
            serviceType: resolvedType,
            port: port,
            domain: domain,
            dataRecords: dataRecords
        )
    }

    private func handleEditIntent(
        currentFullType: String,
        suggestedName: String?,
        suggestedDetails: String?,
        session: any BonjourChatSessionProtocol
    ) {
        // Look up the existing custom type, then construct a
        // "draft" with the model's suggestions applied. The form
        // reads the draft's name/detail into its `@State`
        // properties on init; on Done it deletes the (type,
        // transport)-keyed Core Data record and re-saves with
        // the revised name/detail. Because the lookup is by
        // (type, transport) — not by name — a renamed draft
        // correctly replaces the existing record rather than
        // creating a duplicate.
        let library = BonjourServiceType.fetchAll()
        guard let existing = library.first(where: { $0.fullType == currentFullType }) else {
            session.intentBroker.consume()
            return
        }
        pendingEditServiceType = BonjourServiceType(
            name: suggestedName ?? existing.name,
            type: existing.type,
            transportLayer: existing.transportLayer,
            detail: suggestedDetails ?? existing.detail
        )
    }

    private func handleDeleteIntent(fullType: String, session: any BonjourChatSessionProtocol) {
        // Resolve the existing type so the confirmation dialog
        // can name it ("Delete <name>?"). If lookup fails we
        // bail — the dialog without a name would just be
        // confusing.
        let library = BonjourServiceType.fetchAll()
        guard let existing = library.first(where: { $0.fullType == fullType }) else {
            session.intentBroker.consume()
            return
        }
        pendingDeleteCustomServiceType = existing
    }

    private func handleStopBroadcastIntent(fullType: String, session: any BonjourChatSessionProtocol) {
        // Resolve to the live `BonjourService` instance so we
        // can call `unPublish(service:)` on confirm. Reading
        // from the view model keeps the lookup consistent with
        // what the Discover tab is actually showing — the
        // session's stop-broadcast tool used the same source.
        guard let active = viewModel.publishManager.publishedServices
            .first(where: { $0.serviceType.fullType == fullType }) else {
            session.intentBroker.consume()
            return
        }
        pendingStopBroadcastService = active
    }

    // MARK: - Destructive Confirmation Helpers

    /// Localized "Are you sure you want to delete the <name> service
    /// type?" string. Uses the format-string accessor in
    /// `Strings.Chat.confirmDeleteServiceTypeFormat`. Empty when the
    /// pending state is nil — the binding gating the dialog ensures
    /// it isn't read in that case.
    private var deleteCustomServiceTypeQuestion: String {
        guard let target = pendingDeleteCustomServiceType else { return "" }
        return Strings.Chat.confirmDeleteServiceType(target.name)
    }

    /// Localized "Are you sure you want to stop broadcasting
    /// <service_name>?" string. The "service_name" is the user-given
    /// name of the broadcast (e.g. "Living Room Speaker"), not the
    /// raw DNS-SD type — the dialog reads as a sentence about the
    /// thing the user knows by name.
    private var stopBroadcastQuestion: String {
        guard let active = pendingStopBroadcastService else { return "" }
        return Strings.Chat.confirmStopBroadcast(active.service.name)
    }

    /// Boolean binding the destructive-confirmation modifier needs.
    /// Mirrors the optional state — opening the dialog is implied by
    /// the optional being non-nil. Tapping outside the dialog or the
    /// Cancel button nils the state.
    private var deleteCustomServiceTypeBinding: Binding<Bool> {
        Binding(
            get: { pendingDeleteCustomServiceType != nil },
            set: { if !$0 { pendingDeleteCustomServiceType = nil } }
        )
    }

    private var stopBroadcastBinding: Binding<Bool> {
        Binding(
            get: { pendingStopBroadcastService != nil },
            set: { if !$0 { pendingStopBroadcastService = nil } }
        )
    }

    // MARK: - Pending Intent Payloads

    /// Local payload for the create-custom-service-type sheet.
    /// Conforms to `Identifiable` so `.sheet(item:)` can pick it up;
    /// the `id` is a fresh UUID per intent so two consecutive
    /// "create the same type" requests still re-present the sheet
    /// (rather than the second being deduped because the payload
    /// equals the first).
    private struct PendingCreateTypeIntent: Identifiable {
        let id = UUID()
        let name: String
        let type: String
        let details: String
    }

    /// Local payload for the broadcast sheet. Holds the resolved
    /// `BonjourServiceType` (already looked up against the library)
    /// and the rest of the form pre-fills.
    private struct PendingBroadcastIntent: Identifiable {
        let id = UUID()
        let serviceType: BonjourServiceType
        let port: Int?
        let domain: String
        let dataRecords: [BonjourService.TxtDataRecord]
    }

    // MARK: - Session Factory

    /// Creates a chat session for this device.
    ///
    /// In the iOS Simulator, returns a mock that streams lorem ipsum responses
    /// so the chat UI can be tested end-to-end without a real AI device.
    ///
    /// - Parameter publishManager: Live publish manager from the
    ///   shared dependency container. Threaded into the production
    ///   session so the stop-broadcast tool can query the active
    ///   broadcasts. The simulator and pre-iOS-26 stubs ignore it.
    private static func makeSession(
        publishManager: BonjourPublishManagerProtocol
    ) -> (any BonjourChatSessionProtocol)? {
        #if targetEnvironment(simulator)
        return SimulatorBonjourChatSession()
        #elseif canImport(FoundationModels)
        if #available(iOS 26, macOS 26, visionOS 26, *) {
            return BonjourChatSession(publishManager: publishManager)
        }
        return nil
        #else
        return nil
        #endif
    }
}
