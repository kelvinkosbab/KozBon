//
//  KozBonAppShortcuts.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import AppIntents
import Foundation

// MARK: - KozBonAppShortcuts

/// Registers the suggested phrases for KozBon's App Intents so
/// users can invoke them via Siri without first creating a
/// Shortcut by hand.
///
/// The phrases are surfaced in:
///
/// - **Siri voice** — "Hey Siri, scan my network with KozBon"
/// - **Spotlight** — search results for the app
/// - **Shortcuts app** — pre-built actions in the gallery
/// - **Action Button** (iPhone 15 Pro+) — assignable target
/// - **Apple Intelligence** (iOS 26+) — natural-language match
///
/// The `\(.applicationName)` token expands to the localized app
/// display name at runtime, so Spanish users hear "Buscar
/// servicios Bonjour con KozBon" rather than the English form.
///
/// The conversational `AskKozBonIntent` (and its supporting
/// `BonjourSiriPromptBuilder` / `SiriResponsePostProcessor`) was
/// removed: routing voice questions through the on-device model
/// for free-form Q&A produced inconsistent answers and made the
/// Siri experience feel less polished than the in-app chat. Users
/// who want chat should open the Chat tab; Siri is reserved for
/// concrete actions (scan, list).
@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
struct KozBonAppShortcuts: AppShortcutsProvider {

    /// Tint applied to the Shortcut's icon in the Shortcuts app.
    /// Matches the app's brand blue so the icon reads as a
    /// first-party Shortcut rather than a generic system one.
    static var shortcutTileColor: ShortcutTileColor { .blue }

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ScanForServicesIntent(),
            phrases: [
                // Voice-first phrasing: the user wants Siri to
                // run the scan and read back a count. Five
                // phrases cover the major verb variations a
                // user might reach for ("scan", "discover",
                // "look for", "run a scan") without diluting
                // disambiguation against `ListDiscovered…`,
                // which uses different verbs ("list", "show",
                // "find", "what's on").
                "Scan my network with \(.applicationName)",
                "Scan for Bonjour services with \(.applicationName)",
                "Discover services with \(.applicationName)",
                "Look for Bonjour services with \(.applicationName)",
                "Run a Bonjour scan with \(.applicationName)"
            ],
            shortTitle: "Scan for Services",
            systemImageName: "wifi"
        )

        AppShortcut(
            intent: ListDiscoveredServicesIntent(),
            phrases: [
                // Data-first phrasing. "Show" is more natural
                // than "list" in casual voice but "list" is
                // more natural in Shortcuts-builder context;
                // both forms ship so the same intent surfaces
                // for either user mental model. The
                // question-form phrase ("What's on my
                // network…") catches users who think in
                // questions rather than commands.
                "List Bonjour services with \(.applicationName)",
                "Show Bonjour services with \(.applicationName)",
                "What's on my network with \(.applicationName)",
                "List services on my network with \(.applicationName)",
                "Find Bonjour services with \(.applicationName)"
            ],
            shortTitle: "List Discovered Services",
            systemImageName: "list.bullet"
        )
    }
}
