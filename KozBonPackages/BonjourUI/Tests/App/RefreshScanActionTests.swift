//
//  RefreshScanActionTests.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Testing
@testable import BonjourUI

// MARK: - RefreshScanActionTests

/// Pins the equality contract the type exists for: a focused value
/// holding a bare closure invalidates every reader on each update,
/// because function types can't be compared. Identity comes from the
/// owner, so the closure a view body rebuilds every pass still
/// compares equal.
@Suite("RefreshScanAction")
@MainActor
struct RefreshScanActionTests {

    // MARK: - Helpers

    /// Stands in for the view model that owns the action.
    private final class Owner {}

    /// Reference box so a `@MainActor` closure can record that it ran.
    private final class CallRecorder {
        var callCount = 0
    }

    // MARK: - Equality

    @Test("Actions over the same owner are equal even with different closures")
    func sameOwnerComparesEqual() {
        let owner = Owner()
        // Two distinct closures — the whole point is that the closure
        // doesn't participate in equality.
        let first = RefreshScanAction(owner: owner) {}
        let second = RefreshScanAction(owner: owner) { _ = 1 + 1 }

        #expect(first == second)
    }

    @Test("Actions over different owners are not equal")
    func differentOwnersCompareUnequal() {
        let firstOwner = Owner()
        let secondOwner = Owner()
        // Interchangeable closures, so only the owner can account for
        // the difference.
        let first = RefreshScanAction(owner: firstOwner) {}
        let second = RefreshScanAction(owner: secondOwner) {}

        #expect(first != second)
    }

    @Test("Owners built as temporaries stay distinct — the action holds them alive")
    func temporaryOwnersDoNotCollide() {
        // Regression guard: fingerprinting the owner with a bare
        // `ObjectIdentifier` compares addresses, and the allocator
        // hands the second `Owner()` the address the first just
        // released, making two unrelated actions compare equal.
        let first = RefreshScanAction(owner: Owner()) {}
        let second = RefreshScanAction(owner: Owner()) {}

        #expect(first != second)
    }

    @Test("A rebuilt action over the same owner compares equal, so readers aren't invalidated")
    func rebuildingOverTheSameOwnerStaysEqual() {
        let owner = Owner()
        let recorder = CallRecorder()

        // Mimics a view body re-evaluating and handing SwiftUI a
        // freshly allocated closure each pass.
        let actions = (0..<3).map { _ in
            RefreshScanAction(owner: owner) { recorder.callCount += 1 }
        }

        #expect(actions.allSatisfy { $0 == actions[0] })
    }

    // MARK: - Invocation

    @Test("Calling the action runs the closure it was built with")
    func callingRunsTheClosure() {
        let recorder = CallRecorder()
        let action = RefreshScanAction(owner: Owner()) { recorder.callCount += 1 }

        #expect(recorder.callCount == 0)
        action()
        #expect(recorder.callCount == 1)
    }

    @Test("Equality does not conflate two actions that run different work")
    func equalActionsStillRunTheirOwnClosure() {
        let owner = Owner()
        let first = CallRecorder()
        let second = CallRecorder()

        let firstAction = RefreshScanAction(owner: owner) { first.callCount += 1 }
        let secondAction = RefreshScanAction(owner: owner) { second.callCount += 1 }

        // Equal by owner, but each still carries its own work — the
        // comparison is a change-detection hint, not an identity of
        // behavior.
        #expect(firstAction == secondAction)
        secondAction()
        #expect(first.callCount == 0)
        #expect(second.callCount == 1)
    }
}
