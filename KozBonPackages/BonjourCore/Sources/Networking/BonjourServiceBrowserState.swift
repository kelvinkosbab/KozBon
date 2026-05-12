//
//  BonjourServiceBrowserState.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - BonjourServiceBrowserState

/// Represents the scanning state of a Bonjour service type scanner.
///
/// Each scanner transitions between ``stopped`` and ``searching`` as it
/// begins or ends browsing for network services.
public enum BonjourServiceBrowserState: Sendable {

    /// The scanner is not actively browsing for services.
    case stopped

    /// The scanner is actively browsing the network for services.
    case searching

    /// Whether the scanner is in the ``stopped`` state.
    public var isStopped: Bool {
        self == .stopped
    }

    /// Whether the scanner is in the ``searching`` state.
    public var isSearching: Bool {
        self == .searching
    }
}
