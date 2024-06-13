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
    case bonjourScanForActiveServices
    case bonjourSupportedServices
    case bonjourCreateService

    case bluetooth

    case appInformation

    var id: String {
        switch self {
        case .bonjourScanForActiveServices:
            "bonjour"

        case .bonjourSupportedServices:
            "bonjourSupportedServices"

        case .bonjourCreateService:
            "bonjourCreateService"

        case .bluetooth:
            "bluetooth"

        case .appInformation:
            "appInformation"
        }
    }

    // MARK: - Label

    var titleString: String {
        switch self {
        case .bonjourScanForActiveServices:
            NSLocalizedString(
                "Bonjour",
                comment: "Bonjour tab title"
            )
        case .bonjourSupportedServices:
            ""

        case .bonjourCreateService:
            ""

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
        case .bonjourScanForActiveServices:
            Image.bonjour
        case .bonjourSupportedServices:
            Image.bonjour
        case .bonjourCreateService:
            Image.bonjour
        case .bluetooth:
            Image.bluetoothCapsuleFill
        case .appInformation:
            Image.infoCircleFill
        }
    }
}
