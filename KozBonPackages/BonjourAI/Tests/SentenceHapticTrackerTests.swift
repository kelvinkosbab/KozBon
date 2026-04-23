//
//  SentenceHapticTrackerTests.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourAI

// MARK: - SentenceHapticTrackerTests

/// Covers the sentence-boundary haptic state machine that runs alongside
/// the streaming assistant response.
///
/// Two layers are tested:
///
/// 1. **`completedSentenceCount(in:isFinal:)`** — the pure detector, hit
///    with the edge cases that a streaming LLM actually produces:
///    terminator-before-next-token, trailing terminator once generation
///    finishes, false-positive shapes (URLs, decimals, "e.g."), and
///    monotonicity (count never decreases as content grows).
///
/// 2. **State machine** — walks a realistic event sequence (message id
///    changes, content grows, generation finishes) and asserts `tickCount`
///    reflects exactly one increment per completed sentence. This is the
///    invariant the view depends on for one-haptic-per-sentence semantics.
@Suite("SentenceHapticTracker")
struct SentenceHapticTrackerTests {

    // MARK: - Static Detector: Basic Counting

    @Test func emptyStringCountsZero() {
        #expect(SentenceHapticTracker.completedSentenceCount(in: "", isFinal: false) == 0)
        #expect(SentenceHapticTracker.completedSentenceCount(in: "", isFinal: true) == 0)
    }

    @Test func contentWithoutTerminatorCountsZero() {
        #expect(SentenceHapticTracker.completedSentenceCount(in: "Hello world", isFinal: false) == 0)
        #expect(SentenceHapticTracker.completedSentenceCount(in: "Hello world", isFinal: true) == 0)
    }

    @Test func singleSentenceFollowedBySpaceCountsOne() {
        #expect(SentenceHapticTracker.completedSentenceCount(in: "Hello. ", isFinal: false) == 1)
    }

    @Test func multipleSentencesCountCorrectly() {
        let text = "Bonjour is a protocol. It discovers services. AirPlay uses it."
        // Two terminators are followed by spaces; the trailing "." is the
        // in-flight final sentence and shouldn't count while streaming.
        #expect(SentenceHapticTracker.completedSentenceCount(in: text, isFinal: false) == 2)
        // Once generation finishes, the trailing "." counts too.
        #expect(SentenceHapticTracker.completedSentenceCount(in: text, isFinal: true) == 3)
    }

    // MARK: - Static Detector: Streaming-Completion Semantics

    @Test func trailingTerminatorWithoutFollowingSpaceDoesNotCountWhileStreaming() {
        // During streaming we don't know yet whether this `.` ends the
        // response or is a mid-sentence pause like `e.g.`, so hold off.
        #expect(SentenceHapticTracker.completedSentenceCount(in: "Hello.", isFinal: false) == 0)
    }

    @Test func trailingTerminatorCountsOnceGenerationFinishes() {
        // With `isFinal == true` the final terminator lands the last tick
        // for the just-completed response.
        #expect(SentenceHapticTracker.completedSentenceCount(in: "Hello.", isFinal: true) == 1)
        #expect(SentenceHapticTracker.completedSentenceCount(in: "Hello!", isFinal: true) == 1)
        #expect(SentenceHapticTracker.completedSentenceCount(in: "Is it?", isFinal: true) == 1)
    }

    @Test func newlineAfterTerminatorCountsAsSentenceBoundary() {
        // Models often emit `.\n` when starting a new paragraph.
        let text = "First paragraph.\nSecond paragraph."
        #expect(SentenceHapticTracker.completedSentenceCount(in: text, isFinal: false) == 1)
        #expect(SentenceHapticTracker.completedSentenceCount(in: text, isFinal: true) == 2)
    }

    // MARK: - Static Detector: False-Positive Guards

    @Test func decimalNumberDoesNotCount() {
        // "3.14" has a `.` surrounded by digits — the scan requires a
        // whitespace-following terminator, so no tick fires.
        #expect(SentenceHapticTracker.completedSentenceCount(in: "Pi is 3.14", isFinal: false) == 0)
    }

    @Test func urlDotsDoNotCount() {
        // `example.com` and `/foo.html` must not fire because the dot is
        // followed by a letter, not whitespace.
        let text = "Visit example.com/foo.html"
        #expect(SentenceHapticTracker.completedSentenceCount(in: text, isFinal: false) == 0)
    }

    @Test func egAbbreviationDoesNotCount() {
        // "e.g., something" — the dot after `e` is followed by `g`, and
        // the dot after `g` is followed by `,`. Neither triggers.
        let text = "Protocols, e.g., Bonjour"
        #expect(SentenceHapticTracker.completedSentenceCount(in: text, isFinal: false) == 0)
    }

    @Test func ellipsisDoesNotOvercount() {
        // "..." — only the last `.` could fire, and only when `isFinal`.
        #expect(SentenceHapticTracker.completedSentenceCount(in: "Wait...", isFinal: false) == 0)
        #expect(SentenceHapticTracker.completedSentenceCount(in: "Wait...", isFinal: true) == 1)
    }

    // MARK: - Static Detector: Mixed Terminators

    @Test func mixOfExclamationQuestionAndPeriodCountsAll() {
        let text = "Hello! How are you? I'm fine."
        #expect(SentenceHapticTracker.completedSentenceCount(in: text, isFinal: false) == 2)
        #expect(SentenceHapticTracker.completedSentenceCount(in: text, isFinal: true) == 3)
    }

    // MARK: - Static Detector: Monotonicity
    //
    // The streaming flow depends on the count being monotonically
    // non-decreasing as content grows — otherwise `sentencesAlreadyTicked`
    // could get "ahead" of the current count and the haptic would stop
    // firing for the rest of the response.

    @Test func countIsMonotonicAsContentGrows() {
        let stream = [
            "",
            "Hello",
            "Hello.",
            "Hello. ",
            "Hello. World",
            "Hello. World.",
            "Hello. World. Done",
            "Hello. World. Done."
        ]
        var previous = 0
        for chunk in stream {
            let current = SentenceHapticTracker.completedSentenceCount(in: chunk, isFinal: false)
            #expect(current >= previous, "count decreased from \(previous) to \(current) at '\(chunk)'")
            previous = current
        }
    }

    // MARK: - State Machine: Initial State

    @Test func freshTrackerStartsAtTickZero() {
        let tracker = SentenceHapticTracker()
        #expect(tracker.tickCount == 0)
    }

    // MARK: - State Machine: Single-Response Streaming

    @Test func tickCountIncrementsOncePerCompletedSentenceWhileStreaming() {
        let messageId = UUID()
        var tracker = SentenceHapticTracker()
        tracker.onMessageIdChanged(messageId)
        #expect(tracker.tickCount == 0)

        // Partial first sentence — no tick yet.
        tracker.onStreamingStateChanged(content: "Hello", isFinal: false)
        #expect(tracker.tickCount == 0)

        // Terminator arrives but no trailing space — still no tick.
        tracker.onStreamingStateChanged(content: "Hello.", isFinal: false)
        #expect(tracker.tickCount == 0)

        // Next token includes the space — first tick fires.
        tracker.onStreamingStateChanged(content: "Hello. ", isFinal: false)
        #expect(tracker.tickCount == 1)

        // Mid second sentence — no change.
        tracker.onStreamingStateChanged(content: "Hello. World", isFinal: false)
        #expect(tracker.tickCount == 1)

        // Second sentence terminator with trailing space — second tick.
        tracker.onStreamingStateChanged(content: "Hello. World. ", isFinal: false)
        #expect(tracker.tickCount == 2)
    }

    @Test func finalSentenceTicksWhenGenerationFinishes() {
        let messageId = UUID()
        var tracker = SentenceHapticTracker()
        tracker.onMessageIdChanged(messageId)

        // Build up to "Hello. World." while still streaming — one tick.
        tracker.onStreamingStateChanged(content: "Hello. World.", isFinal: false)
        #expect(tracker.tickCount == 1)

        // Generation finishes — the trailing "." now counts.
        tracker.onStreamingStateChanged(content: "Hello. World.", isFinal: true)
        #expect(tracker.tickCount == 2)
    }

    @Test func repeatedCallsWithSameContentDoNotDoubleTick() {
        let messageId = UUID()
        var tracker = SentenceHapticTracker()
        tracker.onMessageIdChanged(messageId)

        tracker.onStreamingStateChanged(content: "Hello. ", isFinal: false)
        let afterFirstTick = tracker.tickCount

        tracker.onStreamingStateChanged(content: "Hello. ", isFinal: false)
        tracker.onStreamingStateChanged(content: "Hello. ", isFinal: false)
        #expect(tracker.tickCount == afterFirstTick, "idempotent-call shouldn't retick")
    }

    // MARK: - State Machine: Multiple Responses

    @Test func newMessageIdResetsPerMessageCounterSoFirstSentenceTicks() {
        var tracker = SentenceHapticTracker()

        // First assistant response — reaches tickCount 2.
        let firstId = UUID()
        tracker.onMessageIdChanged(firstId)
        tracker.onStreamingStateChanged(content: "Hello. World. ", isFinal: false)
        #expect(tracker.tickCount == 2)

        // Second response starts. Without the id-change reset, the first
        // sentence of the new message would be ignored because the
        // tracker's internal counter still reads 2.
        let secondId = UUID()
        tracker.onMessageIdChanged(secondId)
        tracker.onStreamingStateChanged(content: "Another. ", isFinal: false)
        #expect(tracker.tickCount == 3, "first sentence of new message must tick")
    }

    @Test func unchangedMessageIdDoesNotResetCounter() {
        let messageId = UUID()
        var tracker = SentenceHapticTracker()
        tracker.onMessageIdChanged(messageId)
        tracker.onStreamingStateChanged(content: "One. Two. ", isFinal: false)
        let afterTwoSentences = tracker.tickCount
        #expect(afterTwoSentences == 2)

        // Same id again — no reset, no extra ticks from recounting.
        tracker.onMessageIdChanged(messageId)
        tracker.onStreamingStateChanged(content: "One. Two. ", isFinal: false)
        #expect(tracker.tickCount == afterTwoSentences)
    }
}
