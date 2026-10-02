//
//  BonjourChatViewModel+Scroll.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourAI
import BonjourModels

// MARK: - Scroll Coordination & Animations

extension BonjourChatViewModel {

    // MARK: - Animations

    /// Top-level message-bubble enter/exit animation timing.
    /// `reduceMotion` is read from the view's `@Environment`
    /// and passed in; the VM stays free of any environment
    /// reads so it remains testable.
    func messageTransitionAnimation(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.75)
    }

    /// Returns the insertion transition for a newly-inserted
    /// message bubble. Both user and assistant bubbles slide
    /// in from the top edge so the chat surface reads as a
    /// single vertical stream rather than the previous
    /// asymmetric trailing/leading slide.
    ///
    /// User and assistant differ in scale-anchor side only:
    /// user bubbles scale from the trailing edge so the
    /// corner closest to the right-aligned bubble grows last,
    /// assistant bubbles scale from the leading edge for the
    /// same effect on the left.
    func messageInsertionTransition(
        for role: BonjourChatMessage.Role,
        reduceMotion: Bool
    ) -> AnyTransition {
        if reduceMotion {
            return .opacity
        }
        let scaleAnchor: UnitPoint = (role == .user) ? .topTrailing : .topLeading
        return .move(edge: .top)
            .combined(with: .opacity)
            .combined(with: .scale(scale: 0.95, anchor: scaleAnchor))
    }

    // MARK: - Scroll Coordination

    /// Animates the user's FIRST message in a fresh chat to
    /// the top of the viewport, so the suggestion buttons
    /// scroll off above. This is the "browsing → chatting"
    /// transition; gated on ``hasScrolledFirstUserMessage``
    /// so it fires exactly once per fresh-chat lifetime.
    func scrollFirstUserMessageToTop(
        firstId: UUID?,
        proxy: ScrollViewProxy,
        reduceMotion: Bool
    ) {
        guard let firstId, !hasScrolledFirstUserMessage else { return }
        hasScrolledFirstUserMessage = true
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.5)) {
            proxy.scrollTo(firstId, anchor: .top)
        }
    }

    /// Scroll-to-bottom for subsequent message arrivals and
    /// streaming token updates. Gated on `count > 2` so the
    /// FIRST exchange (user msg + placeholder, possibly
    /// streaming) keeps the user's bubble pinned at the top
    /// — without that gate, every streamed token would tug
    /// the latest content down into view and the user's
    /// question would scroll off-screen during the first
    /// response.
    func scrollLatestMessageToBottom(
        session: any BonjourChatSessionProtocol,
        proxy: ScrollViewProxy,
        duration: Double,
        reduceMotion: Bool
    ) {
        guard session.messages.count > 2,
              let last = session.messages.last else { return }
        withAnimation(reduceMotion ? nil : .easeOut(duration: duration)) {
            proxy.scrollTo(last.id, anchor: .bottom)
        }
    }

    /// What the transcript should scroll to when the compose
    /// field takes focus.
    ///
    /// Split out from the `ScrollViewProxy` call below so the
    /// choice of target is testable on its own —
    /// `ScrollViewProxy` has no public initializer, so anything
    /// holding one can't be unit-tested.
    enum KeyboardScrollTarget: Equatable {

        /// Ride the newest bubble up to sit above the keyboard.
        case message(UUID)

        /// No messages yet, so the empty-state block is the whole
        /// content. Scrolled to its *bottom*, which lifts the
        /// intro and suggestions above the keyboard instead of
        /// leaving them behind it.
        case emptyState
    }

    /// Where focus should send the transcript, or `nil` when it
    /// shouldn't move at all.
    ///
    /// The empty case is the one that matters: a fresh chat has
    /// no messages, and keying the scroll off `messages.last`
    /// alone meant focusing the field did nothing — the intro and
    /// suggestions stayed put under the keyboard.
    func keyboardScrollTarget(
        focused: Bool,
        messages: [BonjourChatMessage]
    ) -> KeyboardScrollTarget? {
        guard focused else { return nil }
        guard let last = messages.last else { return .emptyState }
        return .message(last.id)
    }

    /// When the user taps into the compose field, scroll the
    /// content up so the bottom of the transcript sits right
    /// above the keyboard. A ~300 ms delay lets the keyboard's
    /// safe-area insets propagate before we compute the scroll
    /// position; scrolling synchronously with the focus change
    /// would use the pre-keyboard layout and leave the content
    /// clipped under the keyboard.
    func scrollLatestMessageAboveKeyboard(
        focused: Bool,
        session: any BonjourChatSessionProtocol,
        proxy: ScrollViewProxy,
        emptyAnchorID: String,
        reduceMotion: Bool
    ) {
        guard let target = keyboardScrollTarget(
            focused: focused,
            messages: session.messages
        ) else {
            return
        }

        let id: AnyHashable = switch target {
        case .message(let messageID): AnyHashable(messageID)
        case .emptyState:             AnyHashable(emptyAnchorID)
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) {
                proxy.scrollTo(id, anchor: .bottom)
            }
        }
    }

    /// Runs the toolbar's two-step Clear sequence:
    ///
    ///   1. Animate the ScrollView up to the empty-state
    ///      anchor *while messages are still in place*. The
    ///      scroll has actual distance to cover (the bubbles
    ///      are still occupying the layout above the
    ///      viewport's current position), so the user sees
    ///      a continuous, smooth scroll up instead of bubbles
    ///      disappearing in place.
    ///
    ///   2. Once the scroll animation has played out, call
    ///      `session.reset()` to wipe `messages`. The
    ///      bubbles' opacity-removal transitions overlap
    ///      with the tail end of the scroll, so the
    ///      conversation fades away as the suggestions land
    ///      at the top.
    ///
    /// The 450 ms wait matches the scroll animation
    /// duration; tightening it would clip the scroll's tail,
    /// lengthening it would leave a perceptible pause before
    /// the bubbles finally clear.
    func runPendingClearSequence(
        pending: Bool,
        session: any BonjourChatSessionProtocol,
        proxy: ScrollViewProxy,
        anchorID: String,
        reduceMotion: Bool
    ) {
        guard pending else { return }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.45)) {
            proxy.scrollTo(anchorID, anchor: .top)
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
    /// `pendingClear` flow). Resets the first-message flag
    /// and snaps the ScrollView back to the top — at this
    /// point the bubbles are already gone, so this scroll
    /// is effectively a no-op visually but keeps the state
    /// consistent.
    func snapToEmptyStateIfNeeded(
        isEmpty: Bool,
        proxy: ScrollViewProxy,
        anchorID: String
    ) {
        guard isEmpty, !pendingClear else { return }
        hasScrolledFirstUserMessage = false
        proxy.scrollTo(anchorID, anchor: .top)
    }
}
