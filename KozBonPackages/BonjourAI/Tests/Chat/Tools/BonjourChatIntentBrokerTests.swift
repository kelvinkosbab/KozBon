//
//  BonjourChatIntentBrokerTests.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourAI

// MARK: - BonjourChatIntentBrokerTests

/// Pin the side-channel contract between assistant tool calls and
/// the chat view. The broker's behavior is small but load-bearing
/// — every tool call relies on the publish/consume cycle to
/// surface forms to the user.
@Suite("BonjourChatIntentBroker")
@MainActor
struct BonjourChatIntentBrokerTests {

    @Test("New broker starts with no pending intent")
    func freshBrokerHasNoPendingIntent() {
        let broker = BonjourChatIntentBroker()
        #expect(broker.pendingIntent == nil)
    }

    @Test("`publish` stores the intent on `pendingIntent` for the view to observe")
    func publishStoresIntent() {
        let broker = BonjourChatIntentBroker()
        let intent = BonjourChatIntent.createCustomServiceType(
            name: "Home Media",
            type: "home-media",
            transport: "tcp",
            details: "Personal media server"
        )
        broker.publish(intent)
        #expect(broker.pendingIntent == intent)
    }

    @Test("`consume` clears the pending intent so the same draft can't re-fire on next render")
    func consumeClearsIntent() {
        // Pin the lifecycle: tool publishes, view picks up the intent,
        // view calls `consume`. Without this, the chat view's
        // `.onChange` handler would re-trigger sheet presentation on
        // every subsequent re-render of the body — a sheet would
        // pop back open every time the user typed a character into
        // the chat field.
        let broker = BonjourChatIntentBroker()
        broker.publish(.createCustomServiceType(
            name: "X", type: "x", transport: "tcp", details: "x"
        ))
        broker.consume()
        #expect(broker.pendingIntent == nil)
    }

    @Test("Consuming a broker that has no pending intent is a no-op")
    func consumeWhenEmptyIsNoOp() {
        let broker = BonjourChatIntentBroker()
        broker.consume()
        #expect(broker.pendingIntent == nil)
    }

    @Test("A second `publish` replaces the previous unconsumed intent")
    func publishReplacesPreviousIntent() {
        // Documented contract: the broker holds at most one intent
        // at a time. If the user asks for something new before
        // confirming the previous draft, the old draft is dropped.
        let broker = BonjourChatIntentBroker()
        let first = BonjourChatIntent.createCustomServiceType(
            name: "First", type: "first", transport: "tcp", details: "first"
        )
        let second = BonjourChatIntent.broadcastService(
            serviceTypeFullType: "_http._tcp",
            port: 80,
            domain: "local.",
            txtRecords: []
        )
        broker.publish(first)
        broker.publish(second)
        #expect(broker.pendingIntent == second)
    }

    // MARK: - Cross-Tool Flow

    @Test("Cross-tool flow: publish-create → consume → publish-broadcast lands two distinct intents in order")
    func createThenBroadcastFlow() {
        // Pin the chained-tool lifecycle that the system prompt
        // documents: the model calls `prepareCustomServiceType`,
        // the chat view consumes the intent (after presenting the
        // sheet), the user confirms (form persists), the model
        // then calls `prepareBroadcast` on a follow-up turn. The
        // broker has to handle the two publishes cleanly across
        // a `consume()` in between — no leaked state.
        let broker = BonjourChatIntentBroker()

        let createIntent = BonjourChatIntent.createCustomServiceType(
            name: "Home Media",
            type: "home-media",
            transport: "tcp",
            details: "Personal media server"
        )
        broker.publish(createIntent)
        #expect(broker.pendingIntent == createIntent)

        // View handles the create, consumes the intent — same as
        // what happens when the .sheet(item:) closure runs.
        broker.consume()
        #expect(broker.pendingIntent == nil)

        // Subsequent broadcast intent. Lands cleanly even though
        // the broker just held a different case.
        let broadcastIntent = BonjourChatIntent.broadcastService(
            serviceTypeFullType: "_home-media._tcp",
            port: 8080,
            domain: "local.",
            txtRecords: []
        )
        broker.publish(broadcastIntent)
        #expect(broker.pendingIntent == broadcastIntent)
    }

    @Test("Cross-tool flow: stop → consume → delete chain works without state leakage")
    func stopThenDeleteFlow() {
        // Mirror of the create→broadcast chain for the destructive
        // pair. The system prompt documents this as the recommended
        // way to remove a custom type that's currently broadcasting:
        // stop the broadcast first, then delete the type. Both
        // steps go through the broker.
        let broker = BonjourChatIntentBroker()

        let stopIntent = BonjourChatIntent.stopBroadcast(serviceTypeFullType: "_homemedia._tcp")
        broker.publish(stopIntent)
        #expect(broker.pendingIntent == stopIntent)

        broker.consume()
        #expect(broker.pendingIntent == nil)

        let deleteIntent = BonjourChatIntent.deleteCustomServiceType(serviceTypeFullType: "_homemedia._tcp")
        broker.publish(deleteIntent)
        #expect(broker.pendingIntent == deleteIntent)
    }

    // MARK: - Per-Turn Tool-Call Rate Limit

    @Test("New broker starts with zero tool calls counted")
    func freshBrokerHasZeroToolCallCount() {
        let broker = BonjourChatIntentBroker()
        #expect(broker.toolCallsThisTurn == 0)
    }

    @Test("`reserveToolSlot` increments the counter and returns true while under cap")
    func reserveToolSlotIncrementsAndGrants() {
        let broker = BonjourChatIntentBroker()
        for index in 1...BonjourChatIntentBroker.maxToolCallsPerTurn {
            #expect(broker.reserveToolSlot())
            #expect(broker.toolCallsThisTurn == index)
        }
    }

    @Test("`reserveToolSlot` returns false once the cap is hit so the offending tool can return an error")
    func reserveToolSlotRefusesPastCap() {
        let broker = BonjourChatIntentBroker()
        // Burn through the quota.
        for _ in 0..<BonjourChatIntentBroker.maxToolCallsPerTurn {
            _ = broker.reserveToolSlot()
        }
        // Next reservation must refuse — and must NOT keep
        // incrementing past the cap, otherwise a long-stuck loop
        // would push the counter to absurd numbers.
        #expect(!broker.reserveToolSlot())
        #expect(broker.toolCallsThisTurn == BonjourChatIntentBroker.maxToolCallsPerTurn)
        // Subsequent attempts also refuse.
        #expect(!broker.reserveToolSlot())
        #expect(broker.toolCallsThisTurn == BonjourChatIntentBroker.maxToolCallsPerTurn)
    }

    @Test("`resetToolCallCount` zeroes the counter so each user turn starts with a fresh quota")
    func resetToolCallCountZeroesCounter() {
        let broker = BonjourChatIntentBroker()
        for _ in 0..<BonjourChatIntentBroker.maxToolCallsPerTurn {
            _ = broker.reserveToolSlot()
        }
        broker.resetToolCallCount()
        #expect(broker.toolCallsThisTurn == 0)
        // Quota fully restored — model gets a fresh allotment on
        // the next user turn.
        #expect(broker.reserveToolSlot())
    }

    @Test("Cap is at least 2 so the documented chains can fire within a single turn if needed")
    func capAllowsAtLeastTwoChainedCalls() {
        // The "create then broadcast" and "stop then delete" chains
        // are documented as two-turn flows but the model can chain
        // them in a single turn when the user's request unambiguously
        // describes both actions. Pin a floor so a future cap
        // tightening doesn't break that flow without an explicit
        // intentional change.
        #expect(BonjourChatIntentBroker.maxToolCallsPerTurn >= 2)
    }
}
