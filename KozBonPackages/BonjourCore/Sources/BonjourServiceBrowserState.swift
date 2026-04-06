//
//  BonjourServiceBrowserState.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - BonjourServiceBrowserState

public enum BonjourServiceBrowserState: Sendable {

    case stopped
    case searching

    public var string: String {
        switch self {
        case .stopped:
            NSLocalizedString("Stopped", comment: "Stopped browser state string")
        case .searching:
            NSLocalizedString("Searching", comment: "Searching browser state string")
        }
    }

    public var isStopped: Bool {
        self == .stopped
    }

    public var isSearching: Bool {
        self == .searching
    }
}
