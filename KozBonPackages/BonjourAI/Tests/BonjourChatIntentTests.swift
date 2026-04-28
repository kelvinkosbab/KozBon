//
//  BonjourChatIntentTests.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourAI

// MARK: - BonjourChatIntentTests

/// Pin the value-type semantics of the chat-tool intent enum and the
/// TXT-record draft type. Both are passed across an actor boundary
/// (tools run on the model's pipeline, broker is `@MainActor`), so
/// they MUST stay `Sendable` and `Equatable` for the broker's
/// `pendingIntent == newIntent` change-detection to work correctly.
@Suite("BonjourChatIntent")
struct BonjourChatIntentTests {

    @Test("Identical `createCustomServiceType` intents compare equal so re-publication doesn't bounce")
    func createCustomServiceTypeEquality() {
        let lhs = BonjourChatIntent.createCustomServiceType(
            name: "Home Media",
            type: "home-media",
            transport: "tcp",
            details: "Personal media server"
        )
        let rhs = BonjourChatIntent.createCustomServiceType(
            name: "Home Media",
            type: "home-media",
            transport: "tcp",
            details: "Personal media server"
        )
        #expect(lhs == rhs)
    }

    @Test("`createCustomServiceType` intents differing on any field are not equal")
    func createCustomServiceTypeFieldSensitivity() {
        let base = BonjourChatIntent.createCustomServiceType(
            name: "A", type: "a", transport: "tcp", details: "d"
        )
        let differentName = BonjourChatIntent.createCustomServiceType(
            name: "B", type: "a", transport: "tcp", details: "d"
        )
        let differentType = BonjourChatIntent.createCustomServiceType(
            name: "A", type: "b", transport: "tcp", details: "d"
        )
        let differentTransport = BonjourChatIntent.createCustomServiceType(
            name: "A", type: "a", transport: "udp", details: "d"
        )
        let differentDetails = BonjourChatIntent.createCustomServiceType(
            name: "A", type: "a", transport: "tcp", details: "e"
        )
        #expect(base != differentName)
        #expect(base != differentType)
        #expect(base != differentTransport)
        #expect(base != differentDetails)
    }

    @Test("Identical `broadcastService` intents compare equal even with empty TXT lists")
    func broadcastServiceEquality() {
        let lhs = BonjourChatIntent.broadcastService(
            serviceTypeFullType: "_http._tcp",
            port: 80,
            domain: "local.",
            txtRecords: []
        )
        let rhs = BonjourChatIntent.broadcastService(
            serviceTypeFullType: "_http._tcp",
            port: 80,
            domain: "local.",
            txtRecords: []
        )
        #expect(lhs == rhs)
    }

    @Test("`broadcastService` intents with the same fields but different TXT records are not equal")
    func broadcastServiceTxtSensitivity() {
        let withRecords = BonjourChatIntent.broadcastService(
            serviceTypeFullType: "_http._tcp",
            port: 80,
            domain: "local.",
            txtRecords: [TxtRecordDraft(key: "version", value: "1.0")]
        )
        let withoutRecords = BonjourChatIntent.broadcastService(
            serviceTypeFullType: "_http._tcp",
            port: 80,
            domain: "local.",
            txtRecords: []
        )
        #expect(withRecords != withoutRecords)
    }

    @Test("`createCustomServiceType` is not equal to `broadcastService` even with overlapping field values")
    func intentCasesDoNotCollide() {
        // Defense against accidental case-pattern overlap in a future
        // refactor (e.g. extracting common fields into associated
        // values that get compared by position rather than by case).
        let create = BonjourChatIntent.createCustomServiceType(
            name: "x", type: "x", transport: "tcp", details: "x"
        )
        let broadcast = BonjourChatIntent.broadcastService(
            serviceTypeFullType: "_x._tcp",
            port: 1,
            domain: "local.",
            txtRecords: []
        )
        #expect(create != broadcast)
    }

    @Test("`TxtRecordDraft` is encodable so chat intents could be persisted in a future iteration")
    func txtRecordDraftIsCodable() throws {
        let original = TxtRecordDraft(key: "color", value: "blue")
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(TxtRecordDraft.self, from: encoded)
        #expect(decoded == original)
    }

    // MARK: - Edit / Delete / Stop Cases

    @Test("Identical `editCustomServiceType` intents compare equal even when suggestions are nil")
    func editCustomServiceTypeEquality() {
        let lhs = BonjourChatIntent.editCustomServiceType(
            currentFullType: "_homemedia._tcp",
            suggestedName: nil,
            suggestedDetails: nil
        )
        let rhs = BonjourChatIntent.editCustomServiceType(
            currentFullType: "_homemedia._tcp",
            suggestedName: nil,
            suggestedDetails: nil
        )
        #expect(lhs == rhs)
    }

    @Test("`editCustomServiceType` differing on suggested values is not equal — re-suggesting must re-fire")
    func editCustomServiceTypeSuggestionSensitivity() {
        // The view's `.sheet(item:)` keys off the intent's identity;
        // identical re-suggestion shouldn't pop the sheet again, but
        // a NEW suggestion should. Pin the equality contract so the
        // identity check at the view layer behaves correctly.
        let withName = BonjourChatIntent.editCustomServiceType(
            currentFullType: "_x._tcp",
            suggestedName: "New Name",
            suggestedDetails: nil
        )
        let withoutName = BonjourChatIntent.editCustomServiceType(
            currentFullType: "_x._tcp",
            suggestedName: nil,
            suggestedDetails: nil
        )
        #expect(withName != withoutName)
    }

    @Test("Identical `deleteCustomServiceType` intents compare equal — re-publication is a no-op")
    func deleteCustomServiceTypeEquality() {
        let lhs = BonjourChatIntent.deleteCustomServiceType(serviceTypeFullType: "_homemedia._tcp")
        let rhs = BonjourChatIntent.deleteCustomServiceType(serviceTypeFullType: "_homemedia._tcp")
        #expect(lhs == rhs)
    }

    @Test("Identical `stopBroadcast` intents compare equal so the dialog isn't re-shown")
    func stopBroadcastEquality() {
        let lhs = BonjourChatIntent.stopBroadcast(serviceTypeFullType: "_http._tcp")
        let rhs = BonjourChatIntent.stopBroadcast(serviceTypeFullType: "_http._tcp")
        #expect(lhs == rhs)
    }

    @Test("`deleteCustomServiceType` and `stopBroadcast` for the same type are not equal — different actions")
    func deleteAndStopAreDistinct() {
        // The two destructive intents target the same fullType in
        // certain user flows ("delete the type I just stopped") but
        // they trigger different dialogs. Equality must reflect the
        // case, not just the associated value.
        let delete = BonjourChatIntent.deleteCustomServiceType(serviceTypeFullType: "_x._tcp")
        let stop = BonjourChatIntent.stopBroadcast(serviceTypeFullType: "_x._tcp")
        #expect(delete != stop)
    }
}
