//
//  TopLevelDestination.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourCore
import BonjourLocalization
import BonjourUI

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

    /// The AI chat assistant tab (only shown on Apple Intelligence-capable devices).
    case chat

    /// The user preferences tab.
    case settings

    /// A stable identifier for each destination, used by SwiftUI for tab identity.
    var id: String {
        switch self {
        case .bonjour:
            "bonjour"

        case .bonjourServiceTypes:
            "bonjourServiceTypes"

        case .chat:
            "chat"

        case .settings:
            "settings"
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

        case .chat:
            // "Chat" on iOS, "Explore" on macOS/visionOS where the tab feels
            // more like a discovery surface than a messaging thread.
            #if os(macOS) || os(visionOS)
            String(localized: Strings.Tabs.explore)
            #else
            String(localized: Strings.Tabs.chat)
            #endif

        case .settings:
            String(localized: Strings.Tabs.preferences)
        }
    }

    /// The SF Symbol icon for this tab.
    var icon: Image {
        switch self {
        case .bonjour:
            Image.bonjour

        case .bonjourServiceTypes:
            Image.serviceLibrary

        case .chat:
            Image.appleIntelligence

        case .settings:
            Image.settings
        }
    }
}
