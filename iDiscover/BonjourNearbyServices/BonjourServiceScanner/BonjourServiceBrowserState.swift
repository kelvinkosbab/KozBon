//
//  BonjourServiceBrowserState.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 9/8/23.
//  Copyright © 2023 Kozinga. All rights reserved.
//

import Foundation

// MARK: - BonjourServiceBrowserState

enum BonjourServiceBrowserState {

    case stopped
    case searching

    var string: String {
        switch self {
        case .stopped:
            NSLocalizedString("Stopped", comment: "Stopped browser state string")
        case .searching:
            NSLocalizedString("Searching", comment: "Searching browser state string")
        }
    }

    var isStopped: Bool {
        self == .stopped
    }

    var isSearching: Bool {
        self == .searching
    }
}
