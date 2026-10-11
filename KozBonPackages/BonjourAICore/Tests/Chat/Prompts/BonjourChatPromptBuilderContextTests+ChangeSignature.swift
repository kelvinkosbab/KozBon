//
//  BonjourChatPromptBuilderContextTests+ChangeSignature.swift
//  BonjourAICore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourAICore
import BonjourCore
import BonjourModels

// MARK: - BonjourChatPromptBuilderContextTests · Change Signature

/// The key sessions use to decide whether the context block has
/// to be re-sent.
///
/// An extension on the parent suite so these share its fixtures.
///
/// The bug this exists for: the rendered block stamps a live
/// "Ns ago" scan counter, so comparing rendered text reported a
/// change once per wall-clock second. Every turn more than a
/// second after the previous one re-sent the whole context —
/// wasted tokens, and a broken prompt-cache prefix on the
/// Anthropic path. It also made
/// `subsequentTurnsSkipUnchangedContextBlock` fail on CI
/// whenever the runner was slow enough for two sends to straddle
/// a second boundary.
extension BonjourChatPromptBuilderContextTests {

    @Test("Elapsed scan time doesn't change the signature, though it does change the block")
    func signatureIgnoresElapsedScanTime() {
        let service = makeService(name: "AirPort", type: "http")
        let justNow = BonjourChatPromptBuilder.ChatContext(
            discoveredServices: [service],
            publishedServices: [],
            serviceTypeLibrary: [],
            lastScanTime: Date(),
            isScanning: false
        )
        let awhileAgo = BonjourChatPromptBuilder.ChatContext(
            discoveredServices: [service],
            publishedServices: [],
            serviceTypeLibrary: [],
            lastScanTime: Date().addingTimeInterval(-42),
            isScanning: false
        )

        // The rendered blocks differ — that's the live counter,
        // and it's correct for the model to see it.
        #expect(
            BonjourChatPromptBuilder.contextBlock(context: justNow)
                != BonjourChatPromptBuilder.contextBlock(context: awhileAgo)
        )
        // ...but nothing the model needs re-told has changed.
        #expect(
            BonjourChatPromptBuilder.contextSignature(context: justNow)
                == BonjourChatPromptBuilder.contextSignature(context: awhileAgo)
        )
    }

    @Test("A scan starting or finishing does change the signature")
    func signatureTracksScanState() {
        let service = makeService(name: "AirPort", type: "http")
        func context(scanning: Bool, scanned: Bool) -> BonjourChatPromptBuilder.ChatContext {
            BonjourChatPromptBuilder.ChatContext(
                discoveredServices: [service],
                publishedServices: [],
                serviceTypeLibrary: [],
                lastScanTime: scanned ? Date() : nil,
                isScanning: scanning
            )
        }

        let idle = BonjourChatPromptBuilder.contextSignature(context: context(scanning: false, scanned: true))
        let scanning = BonjourChatPromptBuilder.contextSignature(context: context(scanning: true, scanned: true))
        let never = BonjourChatPromptBuilder.contextSignature(context: context(scanning: false, scanned: false))

        #expect(idle != scanning)
        #expect(idle != never)
        #expect(scanning != never)
    }

    @Test("A newly discovered service changes the signature")
    func signatureTracksDiscoveredServices() {
        let one = BonjourChatPromptBuilder.ChatContext(
            discoveredServices: [makeService(name: "AirPort", type: "http")],
            publishedServices: [],
            serviceTypeLibrary: [],
            lastScanTime: Date(),
            isScanning: false
        )
        let two = BonjourChatPromptBuilder.ChatContext(
            discoveredServices: [
                makeService(name: "AirPort", type: "http"),
                makeService(name: "Printer", type: "ipp")
            ],
            publishedServices: [],
            serviceTypeLibrary: [],
            lastScanTime: Date(),
            isScanning: false
        )

        #expect(
            BonjourChatPromptBuilder.contextSignature(context: one)
                != BonjourChatPromptBuilder.contextSignature(context: two)
        )
    }

    @Test("Publishing a service changes the signature")
    func signatureTracksPublishedServices() {
        let base = BonjourChatPromptBuilder.ChatContext(
            discoveredServices: [],
            publishedServices: [],
            serviceTypeLibrary: [],
            lastScanTime: Date(),
            isScanning: false
        )
        let published = BonjourChatPromptBuilder.ChatContext(
            discoveredServices: [],
            publishedServices: [makeService(name: "Mine", type: "http")],
            serviceTypeLibrary: [],
            lastScanTime: Date(),
            isScanning: false
        )

        #expect(
            BonjourChatPromptBuilder.contextSignature(context: base)
                != BonjourChatPromptBuilder.contextSignature(context: published)
        )
    }
}
