//
//  AppCoreViewModelChatBadgeTests.swift
//  AppCore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourAICore
import BonjourAIApple
import BonjourScanning
@testable import AppCore

// MARK: - AppCoreViewModelChatBadgeTests

/// Pins the chat-tab unread-badge state machine on
/// ``AppCoreViewModel``: when ``hasUnreadAssistantChatMessage``
/// returns true, when ``markChatMessagesSeen`` snaps the seen-id
/// forward, and what happens at the edge cases (no session,
/// generating session, no assistant messages yet).
///
/// The view-side scroll observer that fires
/// ``markChatMessagesSeen`` lives in
/// `BonjourChatView+MessageList` and is intentionally uncovered
/// here — `.onScrollGeometryChange` requires a SwiftUI host. We
/// instead pin the pure VM-level contract the observer
/// ultimately drives.
@Suite("AppCoreViewModel · Chat badge state")
@MainActor
struct AppCoreViewModelChatBadgeTests {

    // MARK: - Helpers

    /// Builds an `AppCoreViewModel` whose `chatSession` is the
    /// supplied controllable test session. Pass `nil` to model
    /// the "no session" / chat-unavailable case.
    private func makeViewModel(
        session: TestChatSession?
    ) -> AppCoreViewModel {
        AppCoreViewModel(
            dependencies: .mock(),
            explainerFactory: TestExplainerFactory(),
            chatSessionFactory: TestChatSessionFactory(session: session),
            credentialsStore: nil,
            preferencesStore: nil
        )
    }

    private func makeAssistantMessage(content: String = "hi") -> BonjourChatMessage {
        BonjourChatMessage(role: .assistant, content: content)
    }

    private func makeUserMessage(content: String = "hi") -> BonjourChatMessage {
        BonjourChatMessage(role: .user, content: content)
    }

    // MARK: - selectedTab

    @Test("`selectedTab` defaults to `.bonjour`")
    func selectedTabDefaultsToBonjour() {
        let vm = makeViewModel(session: TestChatSession())
        #expect(vm.selectedTab == .bonjour)
    }

    @Test("`selectedTab` is mutable for TabView binding")
    func selectedTabIsMutable() {
        let vm = makeViewModel(session: TestChatSession())
        vm.selectedTab = .chat
        #expect(vm.selectedTab == .chat)
    }

    // MARK: - hasUnreadAssistantChatMessage — false cases

    @Test("Returns false when `chatSession` is nil")
    func unreadIsFalseWhenSessionIsNil() {
        let vm = makeViewModel(session: nil)
        #expect(vm.hasUnreadAssistantChatMessage == false)
    }

    @Test("Returns false when the session has no messages")
    func unreadIsFalseWhenNoMessages() {
        let session = TestChatSession()
        let vm = makeViewModel(session: session)
        #expect(vm.hasUnreadAssistantChatMessage == false)
    }

    @Test("Returns false when the session has only user messages")
    func unreadIsFalseWhenOnlyUserMessages() {
        let session = TestChatSession()
        session.messages = [makeUserMessage()]
        let vm = makeViewModel(session: session)
        #expect(vm.hasUnreadAssistantChatMessage == false)
    }

    @Test("Returns false while the session is mid-stream (`isGenerating == true`)")
    func unreadIsFalseWhileGenerating() {
        let session = TestChatSession()
        session.messages = [makeUserMessage(), makeAssistantMessage()]
        session.isGenerating = true
        let vm = makeViewModel(session: session)
        // Even though the assistant id ≠ the (nil) seen id, the
        // badge stays suppressed while a turn is streaming —
        // prevents the empty placeholder from flashing as
        // "unread" before content arrives.
        #expect(vm.hasUnreadAssistantChatMessage == false)
    }

    @Test("Returns false after the user has been marked as seeing the latest message")
    func unreadIsFalseAfterMarkSeen() {
        let session = TestChatSession()
        session.messages = [makeUserMessage(), makeAssistantMessage()]
        session.isGenerating = false
        let vm = makeViewModel(session: session)
        vm.markChatMessagesSeen()
        #expect(vm.hasUnreadAssistantChatMessage == false)
    }

    // MARK: - hasUnreadAssistantChatMessage — true cases

    @Test("Returns true when a completed assistant message exists and nothing has been seen yet")
    func unreadIsTrueForUnseenCompletedMessage() {
        let session = TestChatSession()
        session.messages = [makeUserMessage(), makeAssistantMessage()]
        session.isGenerating = false
        let vm = makeViewModel(session: session)
        // `lastSeenAssistantMessageID` starts nil → latest id
        // differs → badge.
        #expect(vm.hasUnreadAssistantChatMessage == true)
    }

    @Test("Returns true again after a new assistant message arrives post-mark-seen")
    func unreadFlipsBackTrueOnNewMessage() {
        let session = TestChatSession()
        session.messages = [makeUserMessage(), makeAssistantMessage(content: "first")]
        session.isGenerating = false
        let vm = makeViewModel(session: session)
        vm.markChatMessagesSeen()
        #expect(vm.hasUnreadAssistantChatMessage == false)

        // New assistant turn lands.
        session.messages.append(makeUserMessage(content: "follow up"))
        session.messages.append(makeAssistantMessage(content: "second"))

        #expect(vm.hasUnreadAssistantChatMessage == true)
    }

    // MARK: - markChatMessagesSeen

    @Test("`markChatMessagesSeen` with no messages is a no-op (no crash)")
    func markSeenWithNoMessagesIsSafe() {
        let session = TestChatSession()
        let vm = makeViewModel(session: session)
        vm.markChatMessagesSeen()
        #expect(vm.hasUnreadAssistantChatMessage == false)
    }

    @Test("`markChatMessagesSeen` is a no-op when the session is nil")
    func markSeenWithNilSessionIsSafe() {
        let vm = makeViewModel(session: nil)
        vm.markChatMessagesSeen()
        #expect(vm.hasUnreadAssistantChatMessage == false)
    }

    @Test("`markChatMessagesSeen` ignores trailing user messages — picks the last *assistant* message")
    func markSeenTracksLastAssistantNotLastMessage() {
        let session = TestChatSession()
        // The conversation ends on a user message — the assistant
        // hasn't replied yet. The seen-id should still snap to the
        // last *assistant* message, not the user one.
        let firstAssistant = makeAssistantMessage(content: "first")
        session.messages = [
            makeUserMessage(content: "u1"),
            firstAssistant,
            makeUserMessage(content: "u2")
        ]
        session.isGenerating = false
        let vm = makeViewModel(session: session)
        vm.markChatMessagesSeen()
        // No new assistant messages → no badge.
        #expect(vm.hasUnreadAssistantChatMessage == false)

        // An assistant message landing now should be unread
        // because the seen-id is pinned to `firstAssistant`, not
        // the user message that came after.
        let secondAssistant = makeAssistantMessage(content: "second")
        session.messages.append(secondAssistant)
        #expect(vm.hasUnreadAssistantChatMessage == true)
    }

    @Test("`markChatMessagesSeen` is idempotent")
    func markSeenIsIdempotent() {
        let session = TestChatSession()
        session.messages = [makeUserMessage(), makeAssistantMessage()]
        session.isGenerating = false
        let vm = makeViewModel(session: session)

        vm.markChatMessagesSeen()
        vm.markChatMessagesSeen()
        vm.markChatMessagesSeen()

        #expect(vm.hasUnreadAssistantChatMessage == false)
    }
}

// MARK: - Test Doubles

/// Minimal stub conforming to ``BonjourChatSessionProtocol`` with
/// every field writable, so badge-state tests can drive the
/// session through arbitrary `(messages, isGenerating)` pairs
/// without going through `send(_:context:)`. The protocol's
/// default implementations cover `prewarm`, `errorAction`, and
/// `clearError` — we only re-implement the methods badge tests
/// actually exercise.
@MainActor
final class TestChatSession: BonjourChatSessionProtocol {

    var messages: [BonjourChatMessage] = []
    var isGenerating: Bool = false
    var error: String?
    var responseLength: BonjourServicePromptBuilder.ResponseLength = .standard
    let intentBroker = BonjourChatIntentBroker()

    func appendUserMessage(_ text: String) {
        messages.append(BonjourChatMessage(role: .user, content: text))
    }

    func send(_ text: String, context: BonjourChatPromptBuilder.ChatContext) async {
        // Badge tests don't drive the streaming path.
    }

    func appendLocalRejection(userMessage: String, refusalText: String) {
        messages.append(BonjourChatMessage(role: .user, content: userMessage))
        messages.append(BonjourChatMessage(role: .assistant, content: refusalText))
    }

    func reset() {
        messages = []
        error = nil
    }

    func restore(messages: [BonjourChatMessage]) {
        self.messages = messages
    }
}

/// Factory that hands the supplied ``TestChatSession`` back from
/// `makeForCurrentEnvironment(...)`. `nil` covers the
/// chat-unavailable branch the production cloud-aware factory can
/// produce on devices that have no AI configured.
struct TestChatSessionFactory: BonjourChatSessionFactoryProtocol {

    let session: TestChatSession?

    func makeForCurrentEnvironment(
        publishManager: any BonjourPublishManagerProtocol
    ) -> (any BonjourChatSessionProtocol)? {
        session
    }

    func prewarmIfEnabled(
        session: (any BonjourChatSessionProtocol)?,
        aiAnalysisEnabled: Bool
    ) async {
        // No-op — badge tests don't care about prewarm cost.
    }
}

/// Stub explainer factory used only because
/// `AppCoreViewModel.init` requires one. Returns `nil` because
/// badge tests don't reach the explainer code path.
struct TestExplainerFactory: BonjourServiceExplainerFactoryProtocol {

    func makeForCurrentEnvironment() -> (any BonjourServiceExplainerProtocol)? {
        nil
    }
}
