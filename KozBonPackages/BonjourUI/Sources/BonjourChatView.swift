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

// MARK: - BonjourChatView
//
// The chat surface is split across companion files via
// `BonjourChatView+*.swift` extensions. State, init, and the top-
// level `body` live here; large concerns (message list + scroll
// coordination, empty-state suggestions, compose bar + send,
// sheets + destructive confirmations) each have their own file.
//
// Stored properties on the struct are declared without `private`
// because Swift extensions in different files can't see each
// other's `private` declarations, and the chat view's state is a
// single cohesive surface that needs to read/write across those
// files. The struct itself is `public` (it's an entry point from
// the app target) but its stored state is module-internal.

/// Chat interface for asking the on-device Apple Intelligence assistant about
/// Bonjour services and the KozBon app.
public struct BonjourChatView: View {

    @Environment(\.chatSession) var injectedSession
    @Environment(\.preferencesStore) var preferencesStore
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    /// Initialized synchronously at View-init time via
    /// ``init(viewModel:)``. Initializing eagerly (rather than
    /// in `.onAppear`) means the body's first render branch
    /// already has a non-nil session — no two-render path
    /// where the user sees the "requires Apple Intelligence"
    /// `ContentUnavailableView` flash to the chat surface.
    /// That flash was visible on tab activation as ~hundreds
    /// of milliseconds of perceived lag.
    @State var localSession: (any BonjourChatSessionProtocol)?
    @State var inputText: String = ""
    @FocusState var isInputFocused: Bool

    /// Incremented on every successful send. Drives the `.sensoryFeedback`
    /// modifier below so each submit produces a tactile tap confirming the
    /// message was dispatched. Tracked as a monotonic counter rather than a
    /// boolean so consecutive sends reliably trigger the feedback — the
    /// modifier only fires on an actual value change.
    @State var submitCount: Int = 0

    /// Drives the light per-sentence haptic that plays while the assistant
    /// streams a response. All detection and bookkeeping lives inside
    /// `SentenceHapticTracker` so this view can stay focused on
    /// presentation. The view just forwards content/id/isGenerating
    /// changes in via `.onChange` and binds `.sensoryFeedback` to the
    /// tracker's `tickCount`.
    @State var sentenceHapticTracker = SentenceHapticTracker()

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
    @State var hasScrolledFirstUserMessage = false

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
    @State var pendingClear = false

    /// Active "create custom service type" intent surfaced from the
    /// chat assistant's `prepareCustomServiceType` tool. Setting
    /// this presents a pre-filled
    /// `CreateOrUpdateBonjourServiceTypeView` sheet via
    /// `.sheet(item:)`. Cleared when the sheet dismisses so the
    /// same intent can't re-fire on subsequent re-renders.
    @State var pendingCreateTypeIntent: PendingCreateTypeIntent?

    /// Active "broadcast a service" intent surfaced from the chat
    /// assistant's `prepareBroadcast` tool. Setting this presents a
    /// pre-filled `BroadcastBonjourServiceView` sheet via
    /// `.sheet(item:)`. Cleared when the sheet dismisses.
    @State var pendingBroadcastIntent: PendingBroadcastIntent?

    /// Active "edit custom service type" payload — the draft type
    /// (with model-suggested edits applied) the form will bind to.
    /// `BonjourServiceType` is `Identifiable` (via its `fullType`),
    /// so `.sheet(item:)` picks it up directly.
    @State var pendingEditServiceType: BonjourServiceType?

    /// Custom service type the user has been asked to confirm
    /// deletion of. When non-nil, a destructive `.confirmationDialog`
    /// is presented; the user taps Delete or Cancel.
    @State var pendingDeleteCustomServiceType: BonjourServiceType?

    /// Currently-broadcasting service the user has been asked to
    /// confirm stopping. When non-nil, a destructive
    /// `.confirmationDialog` is presented; the user taps Stop or
    /// Cancel. Holds the `BonjourService` rather than just the
    /// `fullType` so the destructive callback has the same instance
    /// to pass to `publishManager.unPublish(service:)`.
    @State var pendingStopBroadcastService: BonjourService?

    var messageTransitionAnimation: Animation? {
        reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.75)
    }

    let viewModel: BonjourServicesViewModel

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
    var session: (any BonjourChatSessionProtocol)? {
        injectedSession ?? localSession
    }

    public var body: some View {
        NavigationStack {
            chatPresentations(applyingTo: chatContent)
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
                .toolbar { clearChatToolbarItem }
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
                .onAppear { onAppearTask() }
                // Watch the assistant's intent broker. When a tool call
                // publishes a drafted form, hydrate it into the matching
                // `PendingCreateTypeIntent` / `PendingBroadcastIntent`
                // and clear the broker so the same intent doesn't
                // re-trigger on the next render. The `.sheet(item:)`
                // modifiers on `chatPresentations(applyingTo:)` pick up
                // the local state and present the pre-filled form.
                // Sheet dismissal nils out the local state automatically.
                .onChange(of: session?.intentBroker.pendingIntent) { _, newIntent in
                    handlePendingIntent(newIntent)
                }
                // Page-level handle for UI tests so a test can find the
                // Chat tab without needing to know its current nav title.
                .accessibilityIdentifier("chat_page")
        }
    }

    /// Inner content of the chat surface — message list + compose bar
    /// when a session is available, fallback empty state otherwise.
    /// Pulled out of `body` so the heavy chain of modifiers doesn't
    /// drown it visually.
    @ViewBuilder
    private var chatContent: some View {
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

    /// Trailing "Clear" affordance — only surfaces once the user has
    /// actually started a conversation. On the empty landing screen
    /// there's nothing to clear, and the button would just be visual
    /// noise.
    ///
    /// Implemented as a `Menu` (not a `confirmationDialog`) so the
    /// popover anchors to the trash icon itself rather than floating
    /// in arbitrary list positions on iPad/Mac/visionOS — and so the
    /// destructive role on the inner button gives the user a clear
    /// "this is serious" cue. The two-tap gesture (open menu → tap
    /// "Clear chat") IS the confirmation step; an additional dialog
    /// on top would just be modal noise.
    @ToolbarContentBuilder
    private var clearChatToolbarItem: some ToolbarContent {
        if let session, !session.messages.isEmpty {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(role: .destructive) {
                        // Setting `pendingClear` triggers the
                        // animated-scroll-then-clear sequence in
                        // `messageList`. Calling `session.reset()`
                        // directly here would wipe the bubbles
                        // before the scroll animation could play
                        // out — the user would see content vanish
                        // abruptly instead of a continuous scroll
                        // back up to the suggestions.
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
                // `Color.red` resolves to `systemRed`, which adapts
                // to increase-contrast and dark-mode automatically.
                // Tints the toolbar glyph so the destructive intent
                // reads at a glance, before the menu is even opened.
                .tint(.red)
                .accessibilityHint(String(localized: Strings.Accessibility.chatClearHistoryHint))
                .accessibilityIdentifier("chat_clear_button")
            }
        }
    }

    /// Deferred startup work that runs once the chat tab has actually
    /// landed on screen.
    ///
    /// Both calls below are deferred to a Task with `Task.yield()` so
    /// the first frame paints before we run them. They're then issued
    /// in sequence:
    ///
    ///   1. `viewModel.load()` — refreshes the network scanner so the
    ///      chat context has fresh data for the next user turn. Has
    ///      its own `isProcessing` guard, so calling it while Discover
    ///      is already scanning is a no-op. Worst case: ~150
    ///      `NetServiceBrowser` inits on the user's first tab visit.
    ///
    ///   2. `session?.prewarm()` — builds the underlying
    ///      `LanguageModelSession` ahead of the user's first tap.
    ///      Without this, the cost of model-instruction compilation
    ///      lands inside the suggestion-button-tap latency and the
    ///      whole UI feels stuck for a beat. Doing it here, after
    ///      the empty state has rendered, keeps the cost off the
    ///      critical perceived-latency path.
    ///
    /// A second `Task.yield()` between the two lets SwiftUI process
    /// any layout work the scanner start triggered (tab toolbar,
    /// scan-status updates) before we hand main back to the model
    /// for instruction compilation. Without the gap both costs
    /// cluster into one ~hundreds-of-ms stutter visible on tab
    /// activation.
    private func onAppearTask() {
        Task { @MainActor in
            await Task.yield()
            viewModel.load()
            await Task.yield()
            session?.prewarm()
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
