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

    /// Set once the user's first message in a fresh chat has been
    /// animated to the top of the viewport. Drives the
    /// "suggestions scroll up out of view" UX on first send —
    /// instead of swapping the empty state for a populated
    /// message list, the unified ScrollView animates the user's
    /// bubble to land just below the navigation bar.
    ///
    /// Reset to `false` when the chat is cleared, so the
    /// suggestions reveal again and the next first send
    /// re-runs the same animation.
    @State private var hasScrolledFirstUserMessage = false

    /// Set when the user taps the Clear toolbar button. Bridges
    /// the toolbar button (in `body`) and the scroll handlers
    /// in `messageList(session:)` — the toolbar can't reach
    /// `ScrollViewProxy` directly, so we drive the
    /// scroll-up-then-clear sequence through this flag.
    ///
    /// The orchestration runs in `messageList`'s `.onChange`
    /// for `pendingClear`: animate the ScrollView up to the
    /// empty-state anchor *while messages are still in place*,
    /// then call `session.reset()` once the scroll has played
    /// out. Without this ordering, `session.reset()` would wipe
    /// the bubbles before the scroll ran, leaving nothing to
    /// scroll from — the user would see bubbles vanish
    /// abruptly and the suggestions appear in place rather
    /// than a continuous scroll-up.
    @State private var pendingClear = false

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
            // The chat surface uses the page's own intro headline
            // ("Ask about your network") as its navigation title.
            // Display mode is `.large` so the title renders at full
            // height when the user lands on the tab and gracefully
            // collapses to an inline bar as they scroll up — same
            // behavior as Mail / Messages. The empty-state intro
            // section in `emptyStateContent` therefore omits the
            // title (it would duplicate what the nav bar already
            // shows) and leads with the subtitle + suggestions.
            .navigationTitle(String(localized: Strings.Chat.emptyTitle))
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.large)
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
                                // Setting `pendingClear` triggers the
                                // animated-scroll-then-clear sequence
                                // in `messageList`. Calling
                                // `session.reset()` directly here
                                // would wipe the bubbles before the
                                // scroll animation could play out —
                                // the user would see content vanish
                                // abruptly instead of a continuous
                                // scroll back up to the suggestions.
                                isInputFocused = false
                                pendingClear = true
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
            // The Chat conversation lives only for the lifetime of
            // the app process. Switching tabs and coming back lands
            // the user back on whatever exchange they had going —
            // the same mental model as Messages, Notes, etc. — but
            // the conversation is intentionally NOT persisted to
            // disk: a cold launch (or the user killing the app from
            // the multitasking switcher) starts a fresh chat. This
            // keeps the on-device model's transcript memory and the
            // visible UI history aligned, so the assistant never
            // has to apologize for "not remembering" earlier turns.
            //
            // `viewModel.load()` keeps the network scanner running
            // so the chat context has fresh data for the next user
            // turn; it has its own `isProcessing` guard, so calling
            // it while Discover is already scanning is a no-op.
            .onAppear {
                // Session construction has already happened in
                // `init(viewModel:)` — see the doc comment on
                // `localSession` for why eager init avoids the
                // first-render flash. `.onAppear` only runs the
                // ancillary work that's safe to defer until the
                // tab is actually visible.
                //
                // Both calls are deferred to a Task with
                // `Task.yield()` so the first frame paints
                // before we run them. They're then issued in
                // sequence:
                //
                //   1. `viewModel.load()` — refreshes the network
                //      scanner so the chat context has fresh data
                //      for the next user turn. Has its own
                //      `isProcessing` guard, so calling it while
                //      Discover is already scanning is a no-op.
                //      Worst case: ~150 NetServiceBrowser inits
                //      on the user's first tab visit.
                //
                //   2. `session?.prewarm()` — builds the underlying
                //      `LanguageModelSession` ahead of the user's
                //      first tap. Without this, the cost of
                //      model-instruction compilation lands inside
                //      the suggestion-button-tap latency and the
                //      whole UI feels stuck for a beat. Doing it
                //      here, after the empty state has rendered,
                //      keeps the cost off the critical
                //      perceived-latency path.
                //
                // A second `Task.yield()` between the two lets
                // SwiftUI process any layout work the scanner
                // start triggered (tab toolbar, scan-status
                // updates) before we hand main back to the model
                // for instruction compilation. Without the gap
                // both costs cluster into one ~hundreds-of-ms
                // stutter visible on tab activation.
                Task { @MainActor in
                    await Task.yield()
                    viewModel.load()
                    await Task.yield()
                    session?.prewarm()
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

    // MARK: - Message List

    /// Stable ID for the empty-state section. Used as a scroll
    /// anchor when the chat is cleared so the ScrollView jumps
    /// back to the top and the suggestions are immediately
    /// visible again.
    private static let emptyStateAnchorID = "chat_empty_state_anchor"

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
    private func messageList(session: any BonjourChatSessionProtocol) -> some View {
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

    // MARK: - Message List Content

    /// The scrollable content of the chat surface. Always contains
    /// the empty-state intro + suggestions (so they're available as
    /// a scroll target both before the first send and after a
    /// Clear), the optional long-conversation banner, the message
    /// bubbles themselves, and any error string.
    @ViewBuilder
    private func messageListContent(session: any BonjourChatSessionProtocol) -> some View {
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
    private func scrollFirstUserMessageToTop(firstId: UUID?, proxy: ScrollViewProxy) {
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
    private func scrollLatestMessageToBottom(
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
    private func scrollLatestMessageAboveKeyboard(
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
    private func runPendingClearSequence(
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
    private func snapToEmptyStateIfNeeded(isEmpty: Bool, proxy: ScrollViewProxy) {
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
    private func messageInsertionTransition(for role: BonjourChatMessage.Role) -> AnyTransition {
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

    // MARK: - Empty State Content

    /// The intro + suggestion buttons rendered at the top of the
    /// chat ScrollView. Always present in the layout (never
    /// conditionally swapped) so a fresh chat shows them first
    /// and a populated chat keeps them as scrolled-off-above
    /// content the user can scroll back to. The wrapping
    /// ScrollView and its `scrollDismissesKeyboard` modifier live
    /// on `messageList(session:)` — this function returns just
    /// the body of the section.
    ///
    /// The page title ("Ask about your network") lives in the
    /// navigation bar, not in this content block — duplicating it
    /// here would push the suggestions off the first viewport on
    /// compact iPhones and read as visual noise once the title
    /// collapses inline. A single subtitle line is the lead-in
    /// above the suggestions so they have one concise hint; the
    /// previous Apple-Intelligence sparkle glyph was removed
    /// because the chat surface is the obvious AI surface — the
    /// glyph was redundant signaling that ate the first ~40 pt
    /// of the empty-state viewport.
    @ViewBuilder
    private func emptyStateContent(session: any BonjourChatSessionProtocol) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(Strings.Chat.emptySubtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func suggestionButton(
        text: String,
        identifier: String,
        session: any BonjourChatSessionProtocol
    ) -> some View {
        Button {
            // Focus the compose field BEFORE dispatching the send.
            // Setting focus is synchronous; doing it first means
            // the keyboard slides up alongside the
            // suggestions-scroll-up animation rather than after
            // the response has already started streaming. Once
            // the suggestion's reply lands, the user has the
            // keyboard already up and the cursor blinking — they
            // can type a follow-up immediately without first
            // tapping the input.
            isInputFocused = true
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
        }
        // Custom ButtonStyle (instead of `.plain`) so the card gets
        // a tactile press animation: subtle scale-down + dimmed tint
        // + slightly darker background while the finger is down,
        // snapping back on release. Without this, taps on the
        // recommended-prompt cards land instantly with no visual
        // confirmation, which on a chat surface where the
        // streaming response takes a beat to start can read as
        // "did I tap it?". The press feedback closes that gap.
        .buttonStyle(SuggestionCardButtonStyle(reduceMotion: reduceMotion))
        // Cap Dynamic Type on the suggestion cards. The card's HStack
        // is `Text + Spacer + chevron`, so at sizes above
        // `.accessibility2` the multi-line text wraps tall enough
        // that the trailing chevron either truncates or pushes
        // off-screen on compact iPhones. Capping at `.accessibility2`
        // keeps both readable; users at the very largest text sizes
        // still see scaled-up text and a visible chevron, just not
        // the full system-max scaling. The rest of the chat surface
        // (subtitle, bubbles, input) keeps full Dynamic Type.
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
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
            // Hint flips to the busy variant while the assistant is
            // streaming a response. Without this, VoiceOver still
            // announced the generic "type a question" hint after
            // the field went disabled, leaving users with no
            // explanation for why their typing wasn't being
            // accepted. The Send button below uses the same flag
            // so both controls read consistently.
            .accessibilityHint(
                session.isGenerating
                    ? String(localized: Strings.Accessibility.chatBusyHint)
                    : String(localized: Strings.Accessibility.chatInputHint)
            )
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
            // Three-way hint so VoiceOver can explain *why* the
            // button is in its current state:
            //
            //   - generating: "Wait for the response to finish…"
            //   - empty input: "Type a message to enable this button"
            //   - enabled: "Sends your message and asks the assistant"
            //
            // Previously both disabled cases shared the empty-input
            // hint, which was actively misleading while the
            // assistant was still streaming — the user had typed
            // and submitted, then heard "type a message to
            // enable" when they tried to fire a follow-up.
            .accessibilityHint(sendButtonAccessibilityHint(session: session))
            .accessibilityIdentifier("chat_send_button")
        }
        .padding()
    }

    private func sendDisabled(session: any BonjourChatSessionProtocol) -> Bool {
        session.isGenerating
            || inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Returns the localized VoiceOver hint that matches the Send
    /// button's current state. Split out so the three-way logic
    /// (busy vs empty vs enabled) reads as a single guarded switch
    /// rather than a nested ternary at the call site.
    private func sendButtonAccessibilityHint(session: any BonjourChatSessionProtocol) -> String {
        if session.isGenerating {
            return String(localized: Strings.Accessibility.chatBusyHint)
        }
        let trimmedInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedInput.isEmpty {
            return String(localized: Strings.Accessibility.chatSendDisabledHint)
        }
        return String(localized: Strings.Accessibility.chatSendHint)
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

        let context = await buildChatContext(forMessage: trimmed)

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

    /// Builds the `ChatContext` the assistant sees for the user's
    /// current message. When the message looks like a question about
    /// live network state ("what's on my network?", "list devices",
    /// "scan", and similar), runs a fresh `BonjourOneShotScanner`
    /// pass first so the assistant answers from current data instead
    /// of whatever the continuous scanner happened to have collected.
    /// Otherwise — for concept questions ("what is Matter?", "explain
    /// HomeKit") — passes through the cached
    /// ``BonjourServicesViewModel/flatActiveServices`` snapshot,
    /// which is what the chat used before fresh-scan-on-demand
    /// existed.
    ///
    /// The fresh-scan path takes ~3 s of additional latency before the
    /// model starts streaming — the typing indicator covers it. The
    /// detector ``ChatScanIntentDetector/wantsFreshScan(message:)`` is
    /// deliberately lenient because a false positive only costs that
    /// 3 s, while a false negative means the assistant answers a live-
    /// state question with stale data. We err toward more scanning.
    ///
    /// A fresh `BonjourServiceScanner` instance is used per scan
    /// rather than the shared one driving Discover, so the chat's
    /// snapshot doesn't disturb Discover's continuous observation —
    /// they run in parallel for the ~3 s window. Same isolation
    /// pattern the Siri intents (`ScanForServicesIntent`,
    /// `ListDiscoveredServicesIntent`) use.
    private func buildChatContext(
        forMessage message: String
    ) async -> BonjourChatPromptBuilder.ChatContext {
        let library = BonjourServiceType.fetchAll()
        let publishedServices = viewModel.sortedPublishedServices

        if ChatScanIntentDetector.wantsFreshScan(message: message) {
            let runner = BonjourOneShotScanner(scanner: BonjourServiceScanner())
            let freshServices = await runner.run(
                publishedServices: viewModel.publishManager.publishedServices
            )
            return BonjourChatPromptBuilder.ChatContext(
                discoveredServices: freshServices,
                publishedServices: publishedServices,
                serviceTypeLibrary: library,
                // The just-completed scan is by definition the most
                // recent; pin `lastScanTime` to now so the assistant's
                // freshness-aware phrasing reads as "data is fresh"
                // rather than "data may be stale."
                lastScanTime: Date(),
                isScanning: false
            )
        }

        return BonjourChatPromptBuilder.ChatContext(
            discoveredServices: viewModel.flatActiveServices,
            publishedServices: publishedServices,
            serviceTypeLibrary: library,
            lastScanTime: viewModel.lastScanTime,
            isScanning: viewModel.serviceScanner.isProcessing
        )
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

// MARK: - SuggestionCardButtonStyle

/// Press feedback for the recommended-prompt cards on the chat empty
/// state. The card scales down to ~97%, the background tint deepens,
/// and the whole label dims slightly while the finger is down — all
/// snapping back on release. Tuned to feel like a single press of a
/// physical key: enough visual difference to confirm the tap, brief
/// enough not to delay the user's perception of the response
/// starting to stream.
///
/// The `reduceMotion` flag swaps the spring scale for an opacity-only
/// flicker so users with the system Reduce Motion preference still
/// get press confirmation without the transform.
///
/// On iOS / iPadOS / visionOS the style additionally applies the
/// system `.hoverEffect()` so pointer-driven (iPad with trackpad)
/// and gaze-driven (Vision Pro) input gets the same lift/highlight
/// that the rest of Apple's UI uses on those platforms. Native
/// macOS doesn't expose `hoverEffect`, so the modifier is gated
/// out there — mouse hover on macOS still works because the
/// underlying `Button` provides its own focus ring and a hand
/// cursor by default.
///
/// `.contentShape(...)` on the inner background pins the hit area to
/// the visible pill rather than the label's intrinsic bounds, so
/// taps near the multi-line text's empty trailing region still
/// register on the card. The previous `.plain` button style passed
/// through the label's bounds, which on wrapped suggestions
/// silently missed tall empty regions.
private struct SuggestionCardButtonStyle: ButtonStyle {

    let reduceMotion: Bool

    @ViewBuilder
    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let card = configuration.label
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.kozBonBlue.opacity(pressed ? 0.2 : 0.1))
            )
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .scaleEffect(reduceMotion ? 1.0 : (pressed ? 0.97 : 1.0))
            .opacity(pressed ? 0.85 : 1.0)
            .animation(
                reduceMotion
                    ? .easeOut(duration: 0.12)
                    : .spring(response: 0.25, dampingFraction: 0.65),
                value: pressed
            )

        #if !os(macOS)
        card.hoverEffect(.highlight)
        #else
        card
        #endif
    }
}
