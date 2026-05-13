//
//  TopLevelDestination.swift
//  AppCore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourAICloud
import BonjourCore
import BonjourLocalization
import BonjourUI

// MARK: - TopLevelDestination

/// The top-level tab destinations for the app's main TabView.
enum TopLevelDestination: Identifiable {

    case bonjour
    case bonjourServiceTypes
    case chat
    case settings

    /// Stable identifier used by SwiftUI for tab identity.
    var id: String {
        switch self {
        case .bonjour:             "bonjour"
        case .bonjourServiceTypes: "bonjourServiceTypes"
        case .chat:                "chat"
        case .settings:            "settings"
        }
    }

    /// Localized display title. The chat tab reads as "Chat" on
    /// iOS and "Explore" on macOS / visionOS where it feels more
    /// like a discovery surface than a messaging thread.
    var titleString: String {
        switch self {
        case .bonjour:
            String(localized: Strings.Tabs.bonjour)

        case .bonjourServiceTypes:
            String(localized: Strings.Tabs.supportedServices)

        case .chat:
            #if os(macOS) || os(visionOS)
            String(localized: Strings.Tabs.explore)
            #else
            String(localized: Strings.Tabs.chat)
            #endif

        case .settings:
            String(localized: Strings.Tabs.preferences)
        }
    }

    /// Backend-agnostic icon — the chat tab defaults to the
    /// Apple Intelligence glyph. Use ``icon(activeBackend:)`` to
    /// surface the user's currently-selected backend's brand.
    var icon: Image {
        switch self {
        case .bonjour:             Image.bonjour
        case .bonjourServiceTypes: Image.serviceLibrary
        case .chat:                Image.appleIntelligence
        case .settings:            Image.settings
        }
    }

    /// Icon variant where the chat tab's glyph swaps to match
    /// the active AI backend. Non-chat cases ignore the param
    /// and return the default ``icon``.
    func icon(activeBackend: AIBackend) -> Image {
        switch self {
        case .chat:
            return activeBackend.icon
        default:
            return icon
        }
    }
}
