//
//  RefreshScanAction.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - RefreshScanAction

/// The "rescan for nearby services" command, published by the
/// Discover screen and invoked from the app's menu bar.
///
/// Exists so the focused value can be compared. A bare
/// `(() -> Void)?` in `FocusedValues` invalidates every reader on
/// each update, because function types aren't `Equatable` and
/// SwiftUI can't tell a re-created closure from a changed one.
/// Identity here is the object that owns the action, so the closure
/// the view body rebuilds every pass still compares equal.
public struct RefreshScanAction: Equatable {

    // MARK: - Properties

    /// Held, not just fingerprinted: `ObjectIdentifier` is an address,
    /// and the allocator reuses the address of a deallocated object.
    /// Keeping the owner alive is what makes the identity stable for
    /// as long as any action derived from it exists.
    private let owner: AnyObject
    private let perform: @MainActor () -> Void

    // MARK: - Init

    /// - Parameters:
    ///   - owner: The object whose identity stands in for the
    ///     action's — typically the view model the work runs
    ///     against. Two actions owned by the same object are equal.
    ///     Retained for the action's lifetime; in practice `perform`
    ///     already captures it.
    ///   - perform: The work to run when the command fires.
    public init(
        owner: AnyObject,
        perform: @escaping @MainActor () -> Void
    ) {
        self.owner = owner
        self.perform = perform
    }

    // MARK: - Invocation

    /// Runs the action, so the call site reads `refreshScan?()`.
    @MainActor
    public func callAsFunction() {
        perform()
    }

    // MARK: - Equatable

    public static func == (lhs: RefreshScanAction, rhs: RefreshScanAction) -> Bool {
        lhs.owner === rhs.owner
    }
}
