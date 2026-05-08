//
//  BonjourChatViewModel.swift
//  BonjourUI
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

// MARK: - BonjourChatViewModel

/// View model for ``BonjourChatView`` and its companion files
/// (`+EmptyState`, `+InputBar`, `+MessageList`, `+Sheets`). Owns
/// every piece of mutable state the chat surface previously held
/// directly on the SwiftUI struct except `@FocusState
/// isInputFocused` (which has to stay on the view since it binds
/// to the view's focus chain, which can't traverse a class
/// boundary).
///
/// Concentrating the state here:
///
/// - lets the four extension files read `viewModel.x` and call
///   `viewModel.method()` without forcing every shared property
///   off `private` for cross-file visibility (the previous
///   workaround documented at the top of `BonjourChatView.swift`)
/// - makes the chat coordination logic — send pipeline, fresh-scan
///   detection, intent-broker handling, scroll state machine —
///   testable as plain Swift without a SwiftUI host
/// - keeps the View struct as a thin presenter that wires
///   `@Environment` values, focus, and view bindings into VM
///   method calls
///
/// The class declaration, state, init, lifecycle, and session
/// factory live in this file. Larger concerns are split across
/// companion `BonjourChatViewModel+*.swift` files mirroring the
/// View's own split:
///
/// - `+Send.swift` — send pipeline, validation, accessibility
///   hint helpers
/// - `+Scroll.swift` — scroll coordination + animation factories
/// - `+Intents.swift` — assistant-intent handling + destructive-
///   confirmation question strings
@MainActor
@Observable
final class BonjourChatViewModel {

    // MARK: - Compose Bindings

    /// Current draft message. The compose `TextField` binds to
    /// `$viewModel.inputText` (via `@Bindable`), so two-way
    /// editing flows here directly.
    var inputText: String = ""

    /// Counter incremented synchronously the instant the user
    /// taps Send (in the suggestion button's action, the send
    /// button's action, or the `TextField.onSubmit` closure).
    /// Drives `.sensoryFeedback(.impact(weight: .medium),
    /// trigger: submitCount)` on the chat surface so the haptic
    /// fires the same render as the press animation instead of
    /// a few render cycles later from inside the async send
    /// path.
    var submitCount: Int = 0

    /// Sentence-detector that fires a lighter `.sensoryFeedback`
    /// at the end of each completed sentence in the streamed
    /// assistant response. Owns its own state machine; the chat
    /// surface forwards `messages.last?.id` and `isGenerating`
    /// change events into it via
    /// ``forwardStreamingStateToHapticTracker(injectedSession:)``.
    var sentenceHapticTracker = SentenceHapticTracker()

    // MARK: - Scroll Coordination

    /// Set once the user's first message in a fresh chat has
    /// been animated to the top of the viewport. Drives the
    /// "suggestions scroll up out of view" UX on first send —
    /// instead of swapping the empty state for a populated
    /// message list, the unified ScrollView animates the user's
    /// bubble to land just below the navigation bar.
    ///
    /// Reset to `false` when the chat is cleared, so the
    /// suggestions reveal again and the next first send re-runs
    /// the same animation.
    var hasScrolledFirstUserMessage = false

    /// Set when the user taps the Clear toolbar button. Bridges
    /// the toolbar (in `body`) and the scroll handlers in
    /// `messageList(session:)` — the toolbar can't reach
    /// `ScrollViewProxy` directly, so we drive the
    /// scroll-up-then-clear sequence through this flag.
    var pendingClear = false

    // MARK: - Pending Intents

    /// Active "create custom service type" intent surfaced from
    /// the chat assistant's `prepareCustomServiceType` tool.
    /// Setting this presents a pre-filled
    /// `CreateOrUpdateBonjourServiceTypeView` sheet via
    /// `.sheet(item:)`. Cleared when the sheet dismisses so
    /// the same intent can't re-fire on subsequent re-renders.
    var pendingCreateTypeIntent: PendingCreateTypeIntent?

    /// Active "broadcast a service" intent surfaced from the
    /// chat assistant's `prepareBroadcast` tool. Setting this
    /// presents a pre-filled `BroadcastBonjourServiceView`
    /// sheet via `.sheet(item:)`.
    var pendingBroadcastIntent: PendingBroadcastIntent?

    /// Active "edit custom service type" payload — the draft
    /// type (with model-suggested edits applied) the form will
    /// bind to. `BonjourServiceType` is `Identifiable` (via
    /// its `fullType`), so `.sheet(item:)` picks it up directly.
    var pendingEditServiceType: BonjourServiceType?

    /// Custom service type the user has been asked to confirm
    /// deletion of. When non-nil, a destructive
    /// `.confirmationDialog` is presented; the user taps
    /// Delete or Cancel.
    var pendingDeleteCustomServiceType: BonjourServiceType?

    /// Currently-broadcasting service the user has been asked
    /// to confirm stopping. When non-nil, a destructive
    /// `.confirmationDialog` is presented; the user taps Stop
    /// or Cancel. Holds the `BonjourService` rather than just
    /// the `fullType` so the destructive callback has the
    /// same instance to pass to
    /// `publishManager.unPublish(service:)`.
    var pendingStopBroadcastService: BonjourService?

    // MARK: - Session

    /// Local fallback chat session, eagerly created at init so
    /// the chat tab's first body render already has a populated
    /// session — avoids the empty-state flash that would
    /// otherwise show for a few frames before lazy
    /// construction completed.
    ///
    /// Pre-empted by the environment-injected session when one
    /// exists. `AppCore` injects an app-level session at launch
    /// so it can prewarm in the background; that injected
    /// instance always wins via ``activeSession(injected:)``.
    var localSession: (any BonjourChatSessionProtocol)?

    // MARK: - Long-Lived Dependencies

    /// Services view model shared with the Discover tab. The
    /// chat surface reads `flatActiveServices`,
    /// `sortedPublishedServices`, `lastScanTime`,
    /// `serviceScanner.isProcessing`, and `publishManager`
    /// off this. Captured at init so all VM methods have access
    /// without threading the reference through every call.
    let services: BonjourServicesViewModel

    // MARK: - Init

    /// Creates the chat view model bound to the supplied
    /// services view model. Eagerly constructs the local
    /// session via ``makeSession(publishManager:)``.
    init(services: BonjourServicesViewModel) {
        self.services = services
        self.localSession = Self.makeSession(publishManager: services.publishManager)
    }

    // MARK: - Session Resolution

    /// Returns the chat session that should drive the surface,
    /// preferring the environment-injected session (which
    /// `AppCore` warms up at launch) over the local fallback.
    ///
    /// Methods on this VM that need a session take it as a
    /// parameter rather than calling this helper internally —
    /// the view is the single owner of the
    /// `@Environment(\.chatSession)` read, so it resolves the
    /// active session once per body evaluation and forwards it
    /// to the VM. That keeps tests trivial: tests inject any
    /// session they want without having to plumb an environment.
    func activeSession(
        injected: (any BonjourChatSessionProtocol)?
    ) -> (any BonjourChatSessionProtocol)? {
        injected ?? localSession
    }

    // MARK: - Lifecycle

    /// Two-phase deferred startup that runs after the chat tab
    /// has landed on screen.
    ///
    /// Both calls below are deferred to a Task with
    /// `Task.yield()` so the first frame paints before we run
    /// them. They're then issued in sequence:
    ///
    ///   1. `services.load()` — refreshes the network scanner
    ///      so the chat context has fresh data for the next
    ///      user turn. Has its own `isProcessing` guard, so
    ///      calling it while Discover is already scanning is
    ///      a no-op. Worst case: ~150 `NetServiceBrowser`
    ///      inits on the user's first tab visit.
    ///
    ///   2. `activeSession(...)?.prewarm()` — builds the
    ///      underlying `LanguageModelSession` ahead of the
    ///      user's first tap. Without this, the cost of
    ///      model-instruction compilation lands inside the
    ///      suggestion-button-tap latency and the whole UI
    ///      feels stuck for a beat.
    ///
    /// A second `Task.yield()` between the two lets SwiftUI
    /// process any layout work the scanner start triggered
    /// before we hand main back to the model for instruction
    /// compilation.
    func onAppear(injectedSession: (any BonjourChatSessionProtocol)?) {
        Task { @MainActor in
            await Task.yield()
            services.load()
            await Task.yield()
            activeSession(injected: injectedSession)?.prewarm()
        }
    }

    // MARK: - Haptic Tracker Forwarding

    /// Forwards the current streaming state into
    /// ``sentenceHapticTracker``. Bails when the last message
    /// isn't an assistant turn so user-submitted messages
    /// don't accidentally fire sentence haptics (the submit
    /// action has its own dedicated haptic via ``submitCount``).
    func forwardStreamingStateToHapticTracker(
        injectedSession: (any BonjourChatSessionProtocol)?
    ) {
        guard let session = activeSession(injected: injectedSession),
              let lastMessage = session.messages.last,
              lastMessage.role == .assistant else { return }
        sentenceHapticTracker.onStreamingStateChanged(
            content: lastMessage.content,
            isFinal: !session.isGenerating
        )
    }

    // MARK: - Pending Intent Payloads

    /// Local payload for the create-custom-service-type sheet.
    /// Conforms to `Identifiable` so `.sheet(item:)` can pick
    /// it up; the `id` is a fresh UUID per intent so two
    /// consecutive "create the same type" requests still
    /// re-present the sheet.
    struct PendingCreateTypeIntent: Identifiable {
        let id = UUID()
        let name: String
        let type: String
        let details: String
    }

    /// Local payload for the broadcast sheet. Holds the
    /// resolved `BonjourServiceType` (already looked up
    /// against the library) and the rest of the form
    /// pre-fills.
    struct PendingBroadcastIntent: Identifiable {
        let id = UUID()
        let serviceType: BonjourServiceType
        let port: Int?
        let domain: String
        let dataRecords: [BonjourService.TxtDataRecord]
    }

    // MARK: - Session Factory

    /// Creates a chat session for this device.
    ///
    /// In the iOS Simulator, returns a mock that streams
    /// random lorem ipsum responses so the chat UI can be
    /// tested end-to-end without a real AI device.
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
