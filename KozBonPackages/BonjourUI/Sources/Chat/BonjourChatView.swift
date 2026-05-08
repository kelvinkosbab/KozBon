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
// Thin presenter over ``BonjourChatViewModel``. The chat surface
// is split across companion files via `BonjourChatView+*.swift`
// extensions for layout (`+EmptyState`, `+InputBar`,
// `+MessageList`, `+Sheets`); every piece of mutable state and
// every coordination method lives on the view model. The view
// itself only holds:
//
//   - `@Environment` reads (chat session, preferences, reduce
//     motion) — short-lived per-render dependencies the VM stays
//     free of so it remains testable.
//   - `@FocusState isInputFocused` — has to stay on the view
//     because it binds to the view's focus chain, which can't
//     traverse a class boundary.
//   - `@State viewModel: BonjourChatViewModel` — the single
//     piece of "view-owned" state.
//
// Extension files declare their methods on `BonjourChatView` and
// reach the VM via `viewModel`. Bindings to the VM are produced
// per-call-site with `@Bindable var bindable = viewModel`.

/// Chat interface for asking the on-device Apple Intelligence assistant about
/// Bonjour services and the KozBon app.
public struct BonjourChatView: View {

    @Environment(\.chatSession) var injectedSession
    @Environment(\.preferencesStore) var preferencesStore
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    @FocusState var isInputFocused: Bool

    /// The chat view model — owner of every mutable piece of
    /// chat state. Initialized synchronously in `init` so the
    /// body's first render branch already has a populated
    /// session and there's no empty-state flash on tab
    /// activation.
    @State var viewModel: BonjourChatViewModel

    /// Creates the Chat view bound to the shared services view model.
    ///
    /// The services view model is owned by the app root so that
    /// the Chat tab observes the same scanner delegate as the
    /// Discover tab. See ``BonjourServicesViewModel`` for the
    /// rationale — two separate view models would race for the
    /// single `weak var delegate` on `BonjourServiceScanner`.
    public init(viewModel servicesViewModel: BonjourServicesViewModel) {
        // `State.init(initialValue:)` is consulted exactly once
        // when SwiftUI first allocates this view's state storage;
        // subsequent `init` calls (during parent rebuilds) discard
        // the new factory result. So `BonjourChatViewModel.init`
        // happens once per Chat-tab lifetime — same cost as the
        // previous lazy path, just paid once at view-init time
        // so the local session is populated before the first
        // body render.
        self._viewModel = State(
            initialValue: BonjourChatViewModel(services: servicesViewModel)
        )
    }

    /// The active session — environment-injected wins over the
    /// VM's local fallback. Resolved once per body evaluation
    /// and forwarded to the VM and extension methods that need
    /// it.
    var session: (any BonjourChatSessionProtocol)? {
        viewModel.activeSession(injected: injectedSession)
    }

    public var body: some View {
        NavigationStack {
            chatPresentations(applyingTo: chatContent)
                // The chat surface uses the page's own intro headline
                // ("Ask about your network") as its navigation title.
                // Display mode is `.large` so the title renders at
                // full height when the user lands on the tab and
                // gracefully collapses to an inline bar as they
                // scroll up — same behavior as Mail / Messages.
                .navigationTitle(String(localized: Strings.Chat.emptyTitle))
                #if !os(macOS)
                .navigationBarTitleDisplayMode(.large)
                #endif
                .toolbar { clearChatToolbarItem }
                // Tactile confirmation that a message was dispatched, plus
                // a lighter tap for each sentence the model completes
                // while streaming. The hierarchy is: `.medium` for submit
                // (discrete action) > `.light` for sentence tick (ambient
                // progress), so the user can feel both without them
                // competing.
                //
                // `.sensoryFeedback(_:trigger:)` is iOS 17+ / macOS 14+
                // but visionOS-26-only; our visionOS deployment target
                // is 2.0 and Vision Pro doesn't have a taptic engine
                // anyway, so gating these out on visionOS costs
                // nothing in practice.
                #if !os(visionOS)
                .sensoryFeedback(.impact(weight: .medium), trigger: viewModel.submitCount)
                .sensoryFeedback(
                    .impact(weight: .light),
                    trigger: viewModel.sentenceHapticTracker.tickCount
                )
                #endif
                .onChange(of: session?.messages.last?.id) { _, newId in
                    viewModel.sentenceHapticTracker.onMessageIdChanged(newId)
                }
                .onChange(of: session?.messages.last?.content) { _, _ in
                    viewModel.forwardStreamingStateToHapticTracker(
                        injectedSession: injectedSession
                    )
                }
                .onChange(of: session?.isGenerating) { _, _ in
                    viewModel.forwardStreamingStateToHapticTracker(
                        injectedSession: injectedSession
                    )
                }
                .onAppear { viewModel.onAppear(injectedSession: injectedSession) }
                // Watch the assistant's intent broker. When a tool call
                // publishes a drafted form, the VM hydrates it into the
                // matching `pending*` state and consumes the broker so
                // the same intent doesn't re-trigger on the next render.
                // The `.sheet(item:)` modifiers on
                // `chatPresentations(applyingTo:)` pick up the local
                // state and present the pre-filled form.
                .onChange(of: session?.intentBroker.pendingIntent) { _, newIntent in
                    viewModel.handlePendingIntent(
                        newIntent,
                        injectedSession: injectedSession
                    )
                }
                // Page-level handle for UI tests so a test can find the
                // Chat tab without needing to know its current nav title.
                .accessibilityIdentifier("chat_page")
        }
    }

    /// Inner content of the chat surface — message list + compose
    /// bar when a session is available, fallback empty state
    /// otherwise. Pulled out of `body` so the heavy chain of
    /// modifiers doesn't drown it visually.
    @ViewBuilder
    private var chatContent: some View {
        if let session {
            // `.safeAreaInset(edge: .bottom)` attaches the compose
            // bar to the bottom of the scroll view *without*
            // clipping the scrollable content above it. The system
            // keeps extending the scroll region under the inset
            // view, so messages flow behind the input bar as the
            // user scrolls.
            //
            // On iOS 26+ the text field and send button apply
            // their own Liquid Glass backgrounds, so the outer
            // bar must stay transparent — otherwise an extra
            // `.bar` material layer sits behind the inner glass
            // and the effect reads as frosted material instead
            // of clear glass. `.composeBarBackgroundForLegacySystems()`
            // keeps `.bar` on older iOS/macOS and on visionOS.
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

    /// Trailing "Clear" affordance — only surfaces once the user
    /// has actually started a conversation. On the empty landing
    /// screen there's nothing to clear, and the button would just
    /// be visual noise.
    ///
    /// Implemented as a `Menu` (not a `confirmationDialog`) so the
    /// popover anchors to the trash icon itself rather than
    /// floating in arbitrary list positions on iPad/Mac/visionOS,
    /// and so the destructive role on the inner button gives the
    /// user a clear "this is serious" cue. The two-tap gesture
    /// (open menu → tap "Clear chat") IS the confirmation step;
    /// an additional dialog on top would just be modal noise.
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
                        // out.
                        isInputFocused = false
                        viewModel.pendingClear = true
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
                // automatically. Tints the toolbar glyph so the
                // destructive intent reads at a glance, before
                // the menu is even opened.
                .tint(.red)
                .accessibilityHint(String(localized: Strings.Accessibility.chatClearHistoryHint))
                .accessibilityIdentifier("chat_clear_button")
            }
        }
    }
}
