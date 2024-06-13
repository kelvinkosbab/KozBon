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
    case bluetooth
    case appInformation

    var id: String {
        switch self {
        case .bonjour:
            "bonjour"

        case .bluetooth:
            "bluetooth"

        case .appInformation:
            "appInformation"
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

        case .bluetooth:
            NSLocalizedString(
                "Bluetooth",
                comment: "Bluetooth tab title"
            )

        case .appInformation:
            NSLocalizedString(
                "App information",
                comment: "Information tab title"
            )
        }
    }

    var icon: Image {
        switch self {
        case .bonjour:
            Image.bonjour
        
        case .bluetooth:
            Image.bluetoothCapsuleFill
            
        case .appInformation:
            Image.infoCircleFill
        }
    }
}
