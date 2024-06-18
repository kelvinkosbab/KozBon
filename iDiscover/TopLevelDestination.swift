//
//  TopLevelDestination.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 6/12/24.
//  Copyright © 2024 Kozinga. All rights reserved.
//

import SwiftUI

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
            NSLocalizedString(
                "Bonjour",
                comment: "Bonjour tab title"
            )
            
        case .bonjourServiceTypes:
            NSLocalizedString(
                "Supported services",
                comment: "Bonjour service types tab title"
            )

        case .bluetooth:
            NSLocalizedString(
                "Bluetooth",
                comment: "Bluetooth tab title"
            )
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
