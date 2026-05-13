//
//  BonjourChatView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourAI
import BonjourAICloud
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
    @Environment(\.aiCloudCredentialsStore) var credentialsStore
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    @FocusState var isInputFocused: Bool

    /// Cached "is there an Anthropic API key in the Keychain
    /// right now?" flag. Refreshed on appearance and after the
    /// in-tab sign-in sheet dismisses. Same pattern Settings
    /// uses — `KeychainAICloudCredentialsStore` isn't
    /// `@Observable`, so we cache the answer in `@State` and
    /// refresh on the discrete moments the value might change
    /// rather than re-querying on every body evaluation.
    @State var hasAnthropicKey: Bool = false

    /// Presents the in-tab `AICloudSignInSheet` when the user
    /// taps the "Sign in to Claude" prompt below the chat tab's
    /// empty state.
    @State var isSignInSheetPresented: Bool = false

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

    /// Accent color for the chat surface, derived from the user's
    /// currently-selected AI backend. The send button, the user's
    /// message bubble background, and the suggestion-chip tints
    /// all bind to this so the active provider is visible at a
    /// glance — blue for the on-device Apple Intelligence path,
    /// Anthropic Cara orange for the cloud path.
    ///
    /// Resolved per-body so a runtime backend swap
    /// (`refreshAIBackend` in `AppCoreViewModel`) flows through
    /// to the chat surface without a manual refresh.
    var aiAccent: Color {
        preferencesStore.aiBackend.accentColor
    }

    /// Whether the chat surface should show the "Sign in to
    /// Claude" prompt in place of the normal message list +
    /// compose bar.
    ///
    /// Fires when the user has selected the Anthropic backend
    /// but the credentials store has no key for it. The cloud-
    /// aware factory will fall back to the Apple session in this
    /// case (so a session object exists), but routing the user's
    /// questions to a backend they didn't pick is surprising —
    /// the in-tab prompt makes the configuration step explicit
    /// before any messages go anywhere.
    var needsClaudeSignIn: Bool {
        preferencesStore.aiBackend == .anthropic && !hasAnthropicKey
    }

    /// Re-queries the credentials store and refreshes
    /// ``hasAnthropicKey``. Called on first appearance and after
    /// the in-tab sign-in sheet dismisses, mirroring the pattern
    /// `SettingsView` uses for the same property.
    func refreshAnthropicKeyState() {
        hasAnthropicKey = credentialsStore.hasAPIKey(for: .anthropic)
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
                .onAppear {
                    viewModel.onAppear(injectedSession: injectedSession)
                    refreshAnthropicKeyState()
                }
                // Animate the swap between the sign-in prompt
                // and the normal chat content (message list +
                // compose bar). Without this the swap is an
                // instant pop the moment `hasAnthropicKey`
                // flips after a successful sign-in; with it,
                // the prompt fades out as the chat fades in.
                // Honors Reduce Motion via the nil-animation
                // shortcut, same pattern the rest of the chat
                // surface uses.
                .animation(
                    reduceMotion ? nil : .default,
                    value: needsClaudeSignIn
                )
                // Animate the cross-backend swap. When the user
                // toggles the backend in Settings and navigates
                // back, the chat surface (active session, accent
                // color, tab icon highlight) all change at once.
                // Pairs with the `.id(aiBackend)` + `.transition`
                // on `chatContent` so the swap reads as a single
                // cohesive fade instead of a pop. Reduce Motion
                // honored via the nil-animation shortcut.
                .animation(
                    reduceMotion ? nil : .default,
                    value: preferencesStore.aiBackend
                )
                // In-tab sign-in sheet. Mounted at this level
                // (not on `ChatSignInPromptView` itself) so the
                // sheet survives if the prompt view ever needs
                // to be replaced mid-flow, and so the
                // `.onDisappear` refresh runs against the
                // chat view's `@State` rather than the prompt
                // view's transient one.
                .sheet(isPresented: $isSignInSheetPresented) {
                    AICloudSignInSheet(credentialsStore: credentialsStore)
                        .onDisappear { refreshAnthropicKeyState() }
                }
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
        // `.id(preferencesStore.aiBackend)` gives the chat
        // content a stable identity per backend so SwiftUI treats
        // a toggle between Apple Intelligence and Anthropic as a
        // mount/unmount rather than an in-place update. Paired
        // with the `.transition(.opacity)` below and the
        // `.animation(_:value: preferencesStore.aiBackend)` higher
        // up the chain, the swap fades cleanly when the user
        // returns to the chat tab after toggling backends in
        // Settings — without this the new content just pops into
        // place because the body's previous render was for a
        // hidden tab and SwiftUI has nothing to animate from.
        chatContentForActiveBackend
            .id(preferencesStore.aiBackend)
            .transition(.opacity)
    }

    /// Inner content of the chat surface — branches between the
    /// sign-in prompt, the active session's message list, or the
    /// fallback empty state. Split out so the outer
    /// ``chatContent`` can apply a single `.id` + `.transition`
    /// pair that drives the cross-backend fade animation.
    @ViewBuilder
    private var chatContentForActiveBackend: some View {
        if needsClaudeSignIn {
            // User picked Anthropic but hasn't configured a key.
            // The cloud-aware factory's silent Apple-fallback
            // would send their questions to the wrong backend;
            // this branch surfaces the configuration step
            // explicitly so the user knows why they aren't yet
            // talking to Claude.
            ChatSignInPromptView(onSignInTapped: {
                isSignInSheetPresented = true
            })
            // Fade in / out rather than popping when
            // `needsClaudeSignIn` flips. The transition pairs
            // with the `.animation(_:value:)` below on the
            // chatContent's container view; without both
            // halves, SwiftUI doesn't know to animate the swap.
            .transition(.opacity)
        } else if let session {
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
