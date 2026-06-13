//
//  ChatWhatsNewIntentDetectorTests.swift
//  BonjourAICore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourAICore

// MARK: - ChatWhatsNewIntentDetectorTests

/// Pins the contract the prompt builder relies on: the detector
/// flips `true` for "what's new / changelog / recent updates"
/// phrasings (so the release-notes block gets injected) and stays
/// `false` for network-state and concept questions (so it doesn't
/// waste the on-device model's context window).
///
/// The most load-bearing assertion is that every localized
/// "What's new in this version?" suggestion-button value matches —
/// if one didn't, tapping the button in that locale would silently
/// fail to inject release notes and the assistant would answer
/// from nothing.
@Suite("ChatWhatsNewIntentDetector")
struct ChatWhatsNewIntentDetectorTests {

    // MARK: - Positive — English

    @Test("Core English what's-new phrasings trigger")
    func englishPhrasingsTrigger() {
        #expect(ChatWhatsNewIntentDetector.wantsWhatsNew(message: "What's new in this version?"))
        #expect(ChatWhatsNewIntentDetector.wantsWhatsNew(message: "what is new?"))
        #expect(ChatWhatsNewIntentDetector.wantsWhatsNew(message: "Show me the changelog"))
        #expect(ChatWhatsNewIntentDetector.wantsWhatsNew(message: "What changed in the latest update?"))
        #expect(ChatWhatsNewIntentDetector.wantsWhatsNew(message: "Tell me about the release notes"))
        #expect(ChatWhatsNewIntentDetector.wantsWhatsNew(message: "What new features were added recently?"))
    }

    // MARK: - Positive — Suggestion-button values (every locale)

    @Test("Every localized suggestion-button value triggers", arguments: [
        "What's new in this version?",          // en
        "¿Qué hay de nuevo en esta versión?",   // es
        "Quoi de neuf dans cette version ?",    // fr
        "Was ist neu in dieser Version?",       // de
        "このバージョンの新機能は？",                  // ja
        "此版本有哪些新功能？",                       // zh-Hans
        "ما الجديد في هذا الإصدار؟",             // ar
        "מה חדש בגרסה זו?"                       // he
    ])
    func localizedSuggestionButtonValuesTrigger(_ value: String) {
        #expect(
            ChatWhatsNewIntentDetector.wantsWhatsNew(message: value),
            "Suggestion value should inject release notes: \(value)"
        )
    }

    // MARK: - Casing / Whitespace Robustness

    @Test("Matcher is case-insensitive")
    func caseInsensitive() {
        #expect(ChatWhatsNewIntentDetector.wantsWhatsNew(message: "WHAT'S NEW?"))
        #expect(ChatWhatsNewIntentDetector.wantsWhatsNew(message: "Release Notes please"))
    }

    @Test("Phrase embedded in a longer sentence still triggers")
    func embeddedPhraseTriggers() {
        #expect(ChatWhatsNewIntentDetector.wantsWhatsNew(
            message: "Hey, I was wondering what's new in the latest release of the app?"
        ))
    }

    // MARK: - Negative

    @Test("Empty / whitespace input does not trigger")
    func emptyDoesNotTrigger() {
        #expect(!ChatWhatsNewIntentDetector.wantsWhatsNew(message: ""))
        #expect(!ChatWhatsNewIntentDetector.wantsWhatsNew(message: "   "))
    }

    @Test("Network-state questions do not trigger (those route to the scan path)")
    func networkQuestionsDoNotTrigger() {
        #expect(!ChatWhatsNewIntentDetector.wantsWhatsNew(message: "What services are on my network?"))
        #expect(!ChatWhatsNewIntentDetector.wantsWhatsNew(message: "Show me my devices"))
        #expect(!ChatWhatsNewIntentDetector.wantsWhatsNew(message: "What's broadcasting right now?"))
    }

    @Test("Concept questions do not trigger")
    func conceptQuestionsDoNotTrigger() {
        #expect(!ChatWhatsNewIntentDetector.wantsWhatsNew(message: "What is Matter?"))
        #expect(!ChatWhatsNewIntentDetector.wantsWhatsNew(message: "How does AirPlay work?"))
        #expect(!ChatWhatsNewIntentDetector.wantsWhatsNew(message: "Explain mDNS to me"))
    }
}
