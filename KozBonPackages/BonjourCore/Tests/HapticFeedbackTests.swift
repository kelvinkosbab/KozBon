//
//  HapticFeedbackTests.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Testing
@testable import BonjourCore

// MARK: - HapticFeedbackTests

/// Covers the ``HapticFeedbackProviding`` abstraction and its mock
/// implementation. The production ``SystemHapticFeedback`` delegates
/// directly to UIKit generators on iOS and is a no-op elsewhere, so the
/// tests here focus on the mock's recording semantics — that's the part
/// the rest of the codebase depends on for dependency-injected
/// verification of haptic behavior in view models.
@Suite("HapticFeedback")
@MainActor
struct HapticFeedbackTests {

    // MARK: - Mock: Initial State

    @Test func freshMockHasNoRecordedStyles() {
        let mock = MockHapticFeedback()
        #expect(mock.playedStyles.isEmpty)
    }

    // MARK: - Mock: Recording

    @Test func playAppendsStyleToHistory() {
        let mock = MockHapticFeedback()
        mock.play(.light)
        #expect(mock.playedStyles == [.light])
    }

    @Test func multiplePlaysPreserveOrder() {
        let mock = MockHapticFeedback()
        mock.play(.medium)
        mock.play(.success)
        mock.play(.light)
        #expect(mock.playedStyles == [.medium, .success, .light])
    }

    @Test func repeatedSameStyleAppendsEachTime() {
        // Consecutive identical requests must all record — the mock is a
        // log, not a `Set`, because view models may legitimately fire
        // the same haptic several times in a row (e.g. per-sentence tick).
        let mock = MockHapticFeedback()
        mock.play(.light)
        mock.play(.light)
        mock.play(.light)
        #expect(mock.playedStyles.count == 3)
        #expect(mock.playedStyles.allSatisfy { $0 == .light })
    }

    // MARK: - Mock: Reset

    @Test func resetClearsRecordedHistory() {
        let mock = MockHapticFeedback()
        mock.play(.medium)
        mock.play(.error)
        mock.reset()
        #expect(mock.playedStyles.isEmpty)
    }

    @Test func playAfterResetStartsFreshHistory() {
        let mock = MockHapticFeedback()
        mock.play(.light)
        mock.reset()
        mock.play(.success)
        #expect(mock.playedStyles == [.success])
    }

    // MARK: - Style Coverage

    /// Every published style must be round-trippable through the mock.
    /// This fails loudly if someone adds a new `HapticFeedbackStyle` case
    /// and forgets to update ``SystemHapticFeedback/play(_:)`` — the
    /// switch there is exhaustive, so an unhandled case becomes a build
    /// error; this test covers the mirror axis (mock must also handle
    /// it).
    @Test func mockAcceptsEveryStyle() {
        let mock = MockHapticFeedback()
        let styles: [HapticFeedbackStyle] = [
            .light, .medium, .heavy, .soft, .rigid,
            .selection,
            .success, .warning, .error
        ]
        for style in styles {
            mock.play(style)
        }
        #expect(mock.playedStyles == styles)
    }

    // MARK: - System: Smoke Test

    /// The system implementation must not throw or crash for any style
    /// on any platform. On iOS it fires UIKit generators; everywhere
    /// else it's a no-op. Either way, `play` should return cleanly.
    @Test func systemImplementationNeverThrows() {
        let system = SystemHapticFeedback()
        let styles: [HapticFeedbackStyle] = [
            .light, .medium, .heavy, .soft, .rigid,
            .selection,
            .success, .warning, .error
        ]
        for style in styles {
            // No return value, no `throws` — the assertion is simply
            // "we got here". A platform-specific crash would fail the
            // test suite.
            system.play(style)
        }
    }
}
