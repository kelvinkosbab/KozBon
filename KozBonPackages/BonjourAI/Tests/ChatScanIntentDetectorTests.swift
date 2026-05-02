//
//  ChatScanIntentDetectorTests.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourAI

// MARK: - ChatScanIntentDetectorTests

/// Pin the contract `BonjourChatView.buildChatContext` relies on:
/// the detector flips to `true` for every "what's on my network"
/// phrasing we expect, stays `false` for concept questions, and
/// is robust to casing / whitespace.
///
/// The tests bias toward concrete examples copied from the
/// suggestion buttons and from the kinds of follow-up questions
/// the assistant's prompt invites — those are the phrasings that
/// matter most in practice.
@Suite("ChatScanIntentDetector")
struct ChatScanIntentDetectorTests {

    // MARK: - Network-State Questions

    @Test("Possessive + state nouns trigger a fresh scan")
    func possessiveStateNounsTrigger() {
        // The strongest signal — "MY network" / "my services" /
        // "my devices" — should always flip to true.
        #expect(ChatScanIntentDetector.wantsFreshScan(message: "What services are on my network?"))
        #expect(ChatScanIntentDetector.wantsFreshScan(message: "Show me my devices"))
        #expect(ChatScanIntentDetector.wantsFreshScan(message: "Tell me about my broadcasts"))
    }

    @Test("'What's on…' question stems trigger a fresh scan")
    func whatsOnQuestionsTrigger() {
        #expect(ChatScanIntentDetector.wantsFreshScan(message: "What's on the network?"))
        #expect(ChatScanIntentDetector.wantsFreshScan(message: "What is on my network right now?"))
        #expect(ChatScanIntentDetector.wantsFreshScan(message: "What's connected to the local network?"))
    }

    @Test("Counting questions about services and devices trigger a fresh scan")
    func countingQuestionsTrigger() {
        // The assistant's answer to "how many?" is unambiguously
        // wrong if the cached snapshot is stale — the count
        // question is the highest-signal trigger for fresh data.
        #expect(ChatScanIntentDetector.wantsFreshScan(message: "How many services are there?"))
        #expect(ChatScanIntentDetector.wantsFreshScan(message: "How many devices do I have?"))
    }

    @Test("Action verbs like 'scan' / 'rescan' / 'refresh' trigger a fresh scan")
    func actionVerbsTrigger() {
        // Direct imperatives — the user is explicitly asking for
        // a scan to happen.
        #expect(ChatScanIntentDetector.wantsFreshScan(message: "Scan now"))
        #expect(ChatScanIntentDetector.wantsFreshScan(message: "Rescan please"))
        #expect(ChatScanIntentDetector.wantsFreshScan(message: "Refresh the list"))
    }

    @Test("Listing requests trigger a fresh scan")
    func listingRequestsTrigger() {
        #expect(ChatScanIntentDetector.wantsFreshScan(message: "List services"))
        #expect(ChatScanIntentDetector.wantsFreshScan(message: "Show me services"))
        #expect(ChatScanIntentDetector.wantsFreshScan(message: "Show discovered devices"))
    }

    @Test("Find-by-category questions trigger a fresh scan")
    func findByCategoryTriggers() {
        // The user wants to know if a specific service type is
        // currently advertising — stale data could miss a printer
        // that just came online.
        #expect(ChatScanIntentDetector.wantsFreshScan(message: "Find printers"))
        #expect(ChatScanIntentDetector.wantsFreshScan(message: "Find AirPlay devices"))
        #expect(ChatScanIntentDetector.wantsFreshScan(message: "Find HomeKit accessories"))
    }

    // MARK: - Concept Questions (Should Not Trigger)

    @Test("Concept questions about protocols don't trigger a fresh scan")
    func conceptQuestionsDontTrigger() {
        // "What is X?" pattern questions ask about the protocol
        // itself, not the user's network — the cached snapshot
        // is sufficient and a fresh scan is wasted latency.
        #expect(!ChatScanIntentDetector.wantsFreshScan(message: "What is Matter?"))
        #expect(!ChatScanIntentDetector.wantsFreshScan(message: "How does HomeKit work?"))
        #expect(!ChatScanIntentDetector.wantsFreshScan(message: "Explain mDNS"))
        #expect(!ChatScanIntentDetector.wantsFreshScan(message: "What's the difference between TCP and UDP?"))
    }

    @Test("Greetings and small talk don't trigger a fresh scan")
    func smallTalkDoesntTrigger() {
        #expect(!ChatScanIntentDetector.wantsFreshScan(message: "Hello"))
        #expect(!ChatScanIntentDetector.wantsFreshScan(message: "Thanks"))
        #expect(!ChatScanIntentDetector.wantsFreshScan(message: "OK"))
    }

    @Test("How-to questions about app features don't trigger a fresh scan")
    func howToQuestionsDontTrigger() {
        #expect(!ChatScanIntentDetector.wantsFreshScan(message: "How do I broadcast a service?"))
        #expect(!ChatScanIntentDetector.wantsFreshScan(message: "How do I create a custom service type?"))
    }

    // MARK: - Robustness

    @Test("Empty and whitespace input do not trigger a fresh scan")
    func emptyInputDoesntTrigger() {
        // Defensive check — `BonjourChatView.sendMessage`
        // already guards against empty trimmed input, but the
        // detector should be safe regardless.
        #expect(!ChatScanIntentDetector.wantsFreshScan(message: ""))
        #expect(!ChatScanIntentDetector.wantsFreshScan(message: "   "))
    }

    @Test("Detection is case-insensitive")
    func detectionIsCaseInsensitive() {
        // Users type "scan" in lowercase, "Scan" capitalized at
        // the start of a sentence, or "SCAN" if they're shouting.
        // All three should match.
        #expect(ChatScanIntentDetector.wantsFreshScan(message: "scan"))
        #expect(ChatScanIntentDetector.wantsFreshScan(message: "Scan"))
        #expect(ChatScanIntentDetector.wantsFreshScan(message: "SCAN"))
        #expect(ChatScanIntentDetector.wantsFreshScan(message: "WHAT'S ON MY NETWORK"))
    }

    @Test("Detection works when the trigger phrase sits inside a longer sentence")
    func phraseInLongerSentenceMatches() {
        // The scan triggers as long as the phrase appears
        // anywhere in the message — users pad their questions
        // with politeness ("Hey, could you tell me what's on my
        // network please?") and we need to catch the live-state
        // intent regardless.
        let message = "Hey, could you please tell me what services are on my network right now? Thanks!"
        #expect(ChatScanIntentDetector.wantsFreshScan(message: message))
    }
}
