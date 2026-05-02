//
//  ChatScanIntentDetector.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - ChatScanIntentDetector

/// Heuristic detector that decides whether a chat message should
/// trigger a fresh Bonjour scan before the assistant answers.
///
/// The chat surface defaults to passing the live-but-cached
/// `BonjourServicesViewModel.flatActiveServices` snapshot into the
/// model's context block. That snapshot is fine for questions
/// about *concepts* — "what is Matter?", "explain HomeKit" — but
/// can be stale for questions about *current state* — "what's on
/// my network?", "list my discovered devices." For the latter,
/// we want the model to see fresh data.
///
/// The matcher is deliberately lenient: false positives (running
/// a fresh scan when the user just wanted a concept explanation)
/// cost ~3 seconds of extra latency before the first token arrives.
/// False negatives (skipping the fresh scan when the user wanted
/// live state) cost the user *wrong answers*. Wrong answers are
/// the worse failure mode, so the phrase list bias toward over-
/// matching.
///
/// English-only by design today. The 6 languages we ship would
/// each need their own phrase list to match comparably; a future
/// iteration can layer those in. Until then, non-English
/// questions fall back to the cached-snapshot path, which is no
/// worse than the pre-detector behavior.
public enum ChatScanIntentDetector {

    // MARK: - Public API

    /// Returns `true` when the user's message looks like a question
    /// about live network state — services, devices, broadcasts —
    /// where stale cached data would mislead the assistant.
    ///
    /// - Parameter message: The user's trimmed input text. The
    ///   matcher lowercases internally; callers don't need to.
    /// - Returns: Whether the chat surface should run a fresh
    ///   `BonjourOneShotScanner` pass before constructing the
    ///   assistant's context.
    public static func wantsFreshScan(message: String) -> Bool {
        let lowered = message.lowercased()
        guard !lowered.isEmpty else { return false }
        for phrase in matchPhrases where lowered.contains(phrase) {
            return true
        }
        return false
    }

    // MARK: - Phrase List

    /// Phrases that strongly indicate the user wants live network
    /// state. Stored already lowercased since ``wantsFreshScan(message:)``
    /// lowercases its input.
    ///
    /// Grouped by signal type for readability — possessive +
    /// state-noun phrasings, "what's around" question stems,
    /// action verbs implying "look right now," and listing/showing
    /// requests. The lookup is a linear contains-scan; with ~60
    /// phrases and chat messages that are usually under 200
    /// characters, the cost is negligible per send.
    static let matchPhrases: [String] = [
        // Possessive + state nouns: the strongest signal that the
        // user is asking about THEIR network, not the concept of
        // networks in general.
        "my network",
        "my services",
        "my devices",
        "my broadcasts",
        "my broadcast",
        "your network",

        // "What's out there right now" question stems.
        "what's on",
        "what is on",
        "what's connected",
        "what is connected",
        "anything on my",
        "anything connected",
        "what services",
        "which services",
        "how many services",
        "what devices",
        "which devices",
        "how many devices",
        "what's broadcasting",
        "what is broadcasting",
        "currently advertising",
        "currently broadcasting",
        "on my network",
        "on the network",
        "on this network",
        "on the local network",

        // Action verbs that imply "go look now."
        "scan",
        "rescan",
        "refresh",
        "discover services",
        "discover devices",

        // Listing / showing — asks for an enumeration of current state.
        "list services",
        "list devices",
        "list discovered",
        "list active",
        "list all services",
        "list all devices",
        "show services",
        "show devices",
        "show discovered",
        "show active",
        "show me services",
        "show me devices",
        "show me what",

        // Discovery vocabulary the assistant itself uses, which
        // users tend to mirror back in follow-up questions.
        "discovered services",
        "discovered devices",
        "available services",
        "available devices",
        "active services",
        "active devices",

        // Find-by-category — the user is asking whether a specific
        // class of thing is on the network right now.
        "find services",
        "find devices",
        "find printers",
        "find airplay",
        "find chromecast",
        "find homekit",
        "find matter",
        "find thread",
        "find sonos",
        "find spotify"
    ]
}
