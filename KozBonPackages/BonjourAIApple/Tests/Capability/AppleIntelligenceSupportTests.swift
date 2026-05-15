//
//  AppleIntelligenceSupportTests.swift
//  BonjourAIApple
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourAIApple

// MARK: - AppleIntelligenceSupportTests

/// Pins the public surface of ``AppleIntelligenceSupport`` — the
/// `AvailabilityState` enum and the derived static properties the
/// rest of the app reads to decide whether to surface AI UI.
///
/// We can't drive the underlying `SystemLanguageModel.default.availability`
/// from a test, so coverage here focuses on invariants that hold
/// regardless of what the host reports: enum-case distinctness,
/// the `availability` → `isDeviceSupported` derivation, the
/// `unavailabilityReason` contract, and the simulator gate.
@Suite("AppleIntelligenceSupport")
struct AppleIntelligenceSupportTests {

    // MARK: - AvailabilityState

    @Test("Every AvailabilityState case is distinct from every other case")
    func availabilityStateCasesMutuallyDistinct() {
        let available: AppleIntelligenceSupport.AvailabilityState = .available
        let ineligible: AppleIntelligenceSupport.AvailabilityState = .deviceNotEligible
        let disabled: AppleIntelligenceSupport.AvailabilityState = .appleIntelligenceDisabled
        let notReady: AppleIntelligenceSupport.AvailabilityState = .modelNotReady
        let other: AppleIntelligenceSupport.AvailabilityState = .otherUnavailable

        #expect(available != ineligible)
        #expect(available != disabled)
        #expect(available != notReady)
        #expect(available != other)
        #expect(ineligible != disabled)
        #expect(ineligible != notReady)
        #expect(ineligible != other)
        #expect(disabled != notReady)
        #expect(disabled != other)
        #expect(notReady != other)
    }

    @Test("AvailabilityState equality matches identical cases")
    func availabilityStateEqualityReflexive() {
        #expect(AppleIntelligenceSupport.AvailabilityState.available == .available)
        #expect(AppleIntelligenceSupport.AvailabilityState.deviceNotEligible == .deviceNotEligible)
        #expect(AppleIntelligenceSupport.AvailabilityState.appleIntelligenceDisabled == .appleIntelligenceDisabled)
        #expect(AppleIntelligenceSupport.AvailabilityState.modelNotReady == .modelNotReady)
        #expect(AppleIntelligenceSupport.AvailabilityState.otherUnavailable == .otherUnavailable)
    }

    // MARK: - Derived Properties

    @Test("`isDeviceSupported` is the inverse of `.deviceNotEligible`")
    func isDeviceSupportedTracksAvailability() {
        // Whatever state the host reports, the supported flag must
        // be exactly `false` for `.deviceNotEligible` and `true`
        // for everything else. The Settings AI Insights section
        // hangs off this invariant — flipping it the wrong way
        // would hide AI UI from users who could enable it, or
        // surface it for users with no path forward.
        let availability = AppleIntelligenceSupport.availability
        let supported = AppleIntelligenceSupport.isDeviceSupported
        if availability == .deviceNotEligible {
            #expect(supported == false)
        } else {
            #expect(supported == true)
        }
    }

    @Test("`unavailabilityReason` is nil exactly when there's nothing for the user to act on")
    func unavailabilityReasonContract() {
        // `.available` → AI is working, no message to show.
        // `.deviceNotEligible` → no recovery path, the AI UI is
        // hidden entirely so a message would have nowhere to land.
        // Other unavailable states have user-actionable
        // remediations and need a non-empty localized string so
        // the Settings AI Insights banner can render.
        let availability = AppleIntelligenceSupport.availability
        let reason = AppleIntelligenceSupport.unavailabilityReason
        switch availability {
        case .available, .deviceNotEligible:
            #expect(reason == nil)
        case .appleIntelligenceDisabled, .modelNotReady, .otherUnavailable:
            #expect(reason != nil)
            #expect(reason?.isEmpty == false)
        }
    }

    @Test("`isRunningInSimulator` matches the `targetEnvironment(simulator)` compile-time predicate")
    func isRunningInSimulatorMatchesBuildEnvironment() {
        // The static value is a thin wrapper over the compile-time
        // macro; pinning the relationship guards against a typo
        // that would invert the flag and silently route real
        // FoundationModels traffic through the lorem-ipsum
        // simulator path (or vice versa).
        #if targetEnvironment(simulator)
        #expect(AppleIntelligenceSupport.isRunningInSimulator == true)
        #else
        #expect(AppleIntelligenceSupport.isRunningInSimulator == false)
        #endif
    }

    @Test("In the iOS Simulator, `availability` is forced to `.available` so devs can exercise the AI UI")
    func availabilityAlwaysAvailableInSimulator() {
        // The simulator branch in `AppleIntelligenceSupport`
        // short-circuits the FoundationModels availability query
        // to `.available`. Without this, the chat / Insights UI
        // would be unreachable in the simulator — the on-device
        // model simply isn't there. The lorem-ipsum simulator
        // sessions then stand in for the real model.
        //
        // Only assert this from a simulator-hosted test run. The
        // SPM `swift test` host (macOS) skips this; the test is
        // exercised by `xcodebuild test` on the iPhone 17 Pro
        // simulator runs in CI.
        #if targetEnvironment(simulator)
        #expect(AppleIntelligenceSupport.availability == .available)
        #endif
    }
}
