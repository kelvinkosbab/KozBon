//
//  TopLevelDestination.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourCore
import BonjourLocalization

// MARK: - TopLevelDestination

/// The top-level tab destinations for the app's main TabView.
///
/// Each case represents a primary navigation tab with an associated
/// title string (localized) and SF Symbol icon.
enum TopLevelDestination: Identifiable {

    /// The nearby Bonjour services scanner tab.
    case bonjour

    /// The supported service type library and custom service type management tab.
    case bonjourServiceTypes

    /// A stable identifier for each destination, used by SwiftUI for tab identity.
    var id: String {
        switch self {
        case .bonjour:
            "bonjour"

        case .bonjourServiceTypes:
            "bonjourServiceTypes"
        }
    }

    // MARK: - Label

    /// The localized display title for this tab.
    var titleString: String {
        switch self {
        case .bonjour:
            String(localized: Strings.Tabs.bonjour)

        case .bonjourServiceTypes:
            String(localized: Strings.Tabs.supportedServices)
        }
    }

    /// The SF Symbol icon for this tab.
    var icon: Image {
        switch self {
        case .bonjour:
            Iconography.bonjourImage

        case .bonjourServiceTypes:
            Image(systemName: Iconography.serviceLibrary)
        }
    }
}
