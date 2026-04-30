//
//  BonjourChatLongConversationDetectorTests.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourAI

// MARK: - BonjourChatLongConversationDetectorTests

/// Pin the heuristic that drives the chat view's "long
/// conversation" indicator. Each test names the scenario it
/// guards against — failures point at a specific UX regression
/// rather than just "the threshold changed".
@Suite("Array<BonjourChatMessage> · isLongConversation")
struct BonjourChatLongConversationDetectorTests {

    // MARK: - Helpers

    private func makeMessages(count: Int, contentLength: Int = 10) -> [BonjourChatMessage] {
        let body = String(repeating: "x", count: contentLength)
        return (0..<count).map { index in
            BonjourChatMessage(
                role: index.isMultiple(of: 2) ? .user : .assistant,
                content: body
            )
        }
    }

    // MARK: - Empty / Trivial

    @Test("Empty conversation is NOT long")
    func emptyConversationIsNotLong() {
        let messages: [BonjourChatMessage] = []
        #expect(!messages.isLongConversation)
    }

    @Test("Single short message is NOT long")
    func singleMessageIsNotLong() {
        let messages = [BonjourChatMessage(role: .user, content: "Hi")]
        #expect(!messages.isLongConversation)
    }

    // MARK: - Message-Count Threshold

    @Test("Just below the count threshold is NOT long — boundary is inclusive at the threshold")
    func belowCountThresholdIsNotLong() {
        let messages = makeMessages(
            count: [BonjourChatMessage].longConversationMessageThreshold - 1,
            contentLength: 10
        )
        #expect(!messages.isLongConversation)
    }

    @Test("At the count threshold IS long — short messages alone can trigger the indicator")
    func atCountThresholdIsLong() {
        let messages = makeMessages(
            count: [BonjourChatMessage].longConversationMessageThreshold,
            contentLength: 10
        )
        #expect(messages.isLongConversation)
    }

    @Test("Well past the count threshold remains long")
    func wellPastCountThresholdIsLong() {
        let messages = makeMessages(count: 100, contentLength: 10)
        #expect(messages.isLongConversation)
    }

    // MARK: - Character Threshold

    @Test("Few messages with combined content below the character threshold are NOT long")
    func belowCharacterThresholdIsNotLong() {
        // 5 messages × 100 chars = 500 chars total — well under
        // the 8000-char threshold, well under the 30-message
        // threshold. Catches neither — should not flag.
        let messages = makeMessages(count: 5, contentLength: 100)
        #expect(!messages.isLongConversation)
    }

    @Test("Few messages with combined content at the character threshold IS long")
    func atCharacterThresholdIsLong() {
        // 5 messages × 1600 chars = 8000 chars. Inclusive
        // boundary — the threshold marks the start of "long",
        // not just past it.
        let messages = makeMessages(count: 5, contentLength: 1_600)
        #expect(messages.isLongConversation)
    }

    @Test("Single very-long message can trip the character threshold by itself")
    func singleLongMessageTripsCharacterThreshold() {
        // The pathological case the character threshold guards
        // against: one massive model reply (technical
        // explanation, debug dump) eats the context window
        // even with a low message count. The count-only
        // threshold would miss this — the character threshold
        // catches it.
        let big = BonjourChatMessage(
            role: .assistant,
            content: String(repeating: "y", count: 9_000)
        )
        let messages = [big]
        #expect(messages.isLongConversation)
    }

    // MARK: - Either-Threshold Trip Semantics

    @Test("Either threshold tripping is sufficient — count or characters, OR semantics")
    func eitherThresholdTrips() {
        // Count met, characters small: long.
        let manyShort = makeMessages(count: 30, contentLength: 5)
        #expect(manyShort.isLongConversation)

        // Characters met, count small: long.
        let fewLong = makeMessages(count: 3, contentLength: 3_000)
        #expect(fewLong.isLongConversation)
    }

    // MARK: - Threshold Constants

    @Test("Message-count threshold is 30 — pinned so a future tightening doesn't quietly hide the chip")
    func messageCountThresholdIs30() {
        #expect([BonjourChatMessage].longConversationMessageThreshold == 30)
    }

    @Test("Character threshold is 8,000 — pinned so a future tightening doesn't quietly hide the chip")
    func characterThresholdIs8000() {
        #expect([BonjourChatMessage].longConversationCharacterThreshold == 8_000)
    }
}
