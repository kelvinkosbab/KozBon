//
//  BonjourChatSessionFactoryTests.swift
//  BonjourAIApple
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourScanning
@testable import BonjourAIApple
@testable import BonjourAICore

// MARK: - BonjourChatSessionFactoryTests

/// Pins the contract of ``BonjourChatSessionFactory`` — protocol
/// conformance, the prewarm-gating logic, and the build-env
/// branches of ``makeForCurrentEnvironment(publishManager:)``.
///
/// The factory's `makeForCurrentEnvironment` returns a different
/// session type per build env (simulator vs canImport
/// FoundationModels + iOS 26 vs neither). We can only assert
/// "non-nil" on hosts where one of the first two branches is
/// reachable; the host-not-supported case is unreachable under
/// `swift test` on a modern Mac.
@Suite("BonjourChatSessionFactory")
@MainActor
struct BonjourChatSessionFactoryTests {

    // MARK: - Protocol Conformance

    @Test("Concrete factory satisfies `BonjourChatSessionFactoryProtocol`")
    func factoryConformsToProtocol() {
        // Existential assignment is the compile-time conformance
        // check. The runtime assertion just keeps the compiler
        // from optimizing the assignment away.
        let factory: any BonjourChatSessionFactoryProtocol = BonjourChatSessionFactory()
        _ = factory
    }

    // MARK: - prewarmIfEnabled

    @Test("`prewarmIfEnabled` is a no-op when the caller passes nil")
    func prewarmNoOpsOnNilSession() async {
        // Defensive path — the chat factory wires this up before
        // the session env value is fully populated on app launch.
        // Passing nil must not crash and must not blow up the
        // task; we observe success by the call returning at all.
        let factory = BonjourChatSessionFactory()
        await factory.prewarmIfEnabled(session: nil, aiAnalysisEnabled: true)
    }

    @Test("`prewarmIfEnabled` does NOT call `prewarm()` when AI features are disabled in Preferences")
    func prewarmSkippedWhenAIAnalysisDisabled() async {
        // The user's Settings toggle for AI features is the
        // user-respecting gate: if they've turned AI off, the
        // factory must not pre-build any model state on their
        // behalf, even if a session was constructed.
        let factory = BonjourChatSessionFactory()
        let session = MockBonjourChatSession()
        await factory.prewarmIfEnabled(session: session, aiAnalysisEnabled: false)
        #expect(session.prewarmCallCount == 0)
    }

    @Test("`prewarmIfEnabled` honors `AppleIntelligenceSupport.availability` gating")
    func prewarmHonorsAvailabilityGate() async {
        // The factory's contract is: prewarm fires iff all three
        // conditions hold — `aiAnalysisEnabled == true`, the
        // session is non-nil, and `availability == .available`.
        // We can't drive availability from a test, so we read
        // what the host reports and assert the gate matches it.
        // Pins the truth-table against drift without needing
        // injection plumbing.
        let factory = BonjourChatSessionFactory()
        let session = MockBonjourChatSession()
        await factory.prewarmIfEnabled(session: session, aiAnalysisEnabled: true)
        if AppleIntelligenceSupport.availability == .available {
            #expect(session.prewarmCallCount == 1)
        } else {
            #expect(session.prewarmCallCount == 0)
        }
    }

    // MARK: - makeForCurrentEnvironment

    @Test("`makeForCurrentEnvironment` returns a session in environments that have one")
    func makeReturnsSessionOnSupportedEnvironments() {
        let factory = BonjourChatSessionFactory()
        let session = factory.makeForCurrentEnvironment(publishManager: MockBonjourPublishManager())
        #if targetEnvironment(simulator)
        // Simulator branch → SimulatorBonjourChatSession.
        #expect(session != nil)
        #elseif canImport(FoundationModels)
        if #available(iOS 26, macOS 26, visionOS 26, *) {
            // Real BonjourChatSession.
            #expect(session != nil)
        } else {
            // Hosts on canImport-true but pre-26 OS report nil.
            #expect(session == nil)
        }
        #else
        // Hosts that can't import FoundationModels (older SDKs)
        // get nil so the chat tab silently omits itself.
        #expect(session == nil)
        #endif
    }
}
