//
//  ChatSentenceHapticTracker.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - ChatSentenceHapticTracker

/// Value-type state machine that drives sentence-boundary haptic feedback
/// for the streaming assistant response in `BonjourChatView`.
///
/// Held as a single `@State` on the view. The view calls
/// `onMessageIdChanged` whenever the last message identity changes (so the
/// counter resets at the start of each new assistant response), and
/// `onStreamingStateChanged` every time content grows or generation
/// transitions between in-flight and finished. Each time a newly-completed
/// sentence is detected, `tickCount` is incremented — the view binds
/// `.sensoryFeedback(_:trigger:)` to that counter, so every tick produces
/// a tactile tap.
///
/// Keeping this outside the view keeps `BonjourChatView` slim and makes
/// the detection logic independently testable.
struct ChatSentenceHapticTracker: Equatable {

    // MARK: - State

    /// The id of the assistant message whose sentences are being counted.
    /// When the id changes (new response starts), `sentencesAlreadyTicked`
    /// resets to zero so the next response's first sentence still ticks.
    private var trackedMessageId: UUID?

    /// Number of completed sentences already acknowledged with a haptic
    /// tick in the currently-tracked message.
    private var sentencesAlreadyTicked: Int = 0

    /// Monotonically-increasing counter the view binds to
    /// `.sensoryFeedback(_:trigger:)`. Each increment produces one haptic.
    private(set) var tickCount: Int = 0

    // MARK: - State Transitions

    /// Call whenever the observed last-message id changes. If the id is
    /// different from the one we're tracking, reset the per-message
    /// sentence counter so the next sentence in the new message fires.
    mutating func onMessageIdChanged(_ newId: UUID?) {
        guard trackedMessageId != newId else { return }
        trackedMessageId = newId
        sentencesAlreadyTicked = 0
    }

    /// Call when the streaming content grows or the `isGenerating` flag
    /// flips. Recomputes completed-sentence count and bumps `tickCount`
    /// once for each newly-completed sentence.
    ///
    /// - Parameters:
    ///   - content: Current text of the assistant message. Safe to pass
    ///     the partial, in-flight content — the detector holds off on the
    ///     trailing unterminated sentence until more content arrives.
    ///   - isFinal: `true` once the session's `isGenerating` flag flips
    ///     to `false`. Tells the detector it's OK to count a trailing
    ///     terminator without a following space as a completed sentence
    ///     (the "final sentence" case).
    mutating func onStreamingStateChanged(content: String, isFinal: Bool) {
        let completed = Self.completedSentenceCount(in: content, isFinal: isFinal)
        guard completed > sentencesAlreadyTicked else { return }
        // Advance by the full delta, not just 1 — if two sentences land
        // in the same streamed chunk (rare but possible, especially on
        // simulator/mock fixtures) `tickCount` should reflect the true
        // number of completed sentences. Real device streaming tends to
        // deliver one token at a time, so in practice the delta is 1
        // and each increment maps to its own SwiftUI render cycle and
        // haptic tap.
        tickCount &+= (completed - sentencesAlreadyTicked)
        sentencesAlreadyTicked = completed
    }

    // MARK: - Sentence Detection

    /// Counts sentences in `text` that are fully complete.
    ///
    /// A sentence is "complete" when it ends with `.`, `!`, or `?` followed
    /// by whitespace — the whitespace is the signal that the model has
    /// moved on to the next sentence. When `isFinal` is `true` (generation
    /// has stopped), a trailing terminator without following whitespace is
    /// also counted, so the very last sentence of a response ticks once.
    ///
    /// This deliberately uses a simple character scan rather than
    /// `enumerateSubstrings(options: .bySentences)`:
    ///
    /// - The scan correctly distinguishes "in-flight last sentence"
    ///   from "completed final sentence" via the `isFinal` flag.
    ///   Foundation's sentence enumerator counts partial trailing
    ///   content as a sentence, which would cause the haptic to fire
    ///   too eagerly during streaming.
    /// - A whitespace-gated check naturally skips false positives on
    ///   decimals (`3.14`), URLs (`example.com`), and most uses of
    ///   `e.g.` — the terminator is never followed by whitespace inside
    ///   those forms.
    ///
    /// Known false positives (accepted as rare enough not to matter in
    /// the networking/Bonjour chat context): abbreviations like "Mr. " or
    /// "Dr. " will tick mid-sentence.
    static func completedSentenceCount(in text: String, isFinal: Bool) -> Int {
        let terminators: Set<Character> = [".", "!", "?"]
        var count = 0
        let characters = Array(text)
        for index in characters.indices {
            guard terminators.contains(characters[index]) else { continue }
            let next = characters.indices.contains(index + 1) ? characters[index + 1] : nil
            if let next, next.isWhitespace {
                count += 1
            } else if next == nil, isFinal {
                count += 1
            }
        }
        return count
    }
}
