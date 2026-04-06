//
//  TopLevelDestination.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourLocalization

// MARK: - TopLevelDestination

enum TopLevelDestination: Identifiable {
    case bonjour
    case bonjourServiceTypes
    case bluetooth

    var id: String {
        switch self {
        case .bonjour:
            "bonjour"

        case .bonjourServiceTypes:
            "bonjourServiceTypes"

        case .bluetooth:
            "bluetooth"
        }
    }

    // MARK: - Label

    var titleString: String {
        switch self {
        case .bonjour:
            String(localized: Strings.Tabs.bonjour)

        case .bonjourServiceTypes:
            String(localized: Strings.Tabs.supportedServices)

        case .bluetooth:
            String(localized: Strings.Tabs.bluetooth)
        }
    }

    var icon: Image {
        switch self {
        case .bonjour:
            Image.bonjour

        case .bonjourServiceTypes:
            Image(systemName: "list.dash")

        case .bluetooth:
            Image.bluetoothCapsuleFill
        }
    }
}
