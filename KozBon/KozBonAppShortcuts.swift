//
//  KozBonAppShortcuts.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import AppIntents
import BonjourAppIntents
import Foundation

// MARK: - KozBonAppShortcuts

/// Registers the suggested phrases for KozBon's App Intents so
/// users can invoke them via Siri without first creating a
/// Shortcut by hand.
///
/// Lives in the **app target**, not `BonjourAppIntents`, because
/// Xcode runs the App Intents extractor with
/// `--no-app-shortcuts-localization` for every SPM target and
/// without it only for the app target. Declared in the package,
/// these phrases cannot be localized at all — and did not reach
/// the shipped `Metadata.appintents` (`autoShortcuts` was empty).
///
/// The phrases are surfaced in:
///
/// - **Siri voice** — "Hey Siri, scan my network with KozBon"
/// - **Spotlight** — search results for the app
/// - **Shortcuts app** — pre-built actions in the gallery
/// - **Action Button** (iPhone 15 Pro+) — assignable target
/// - **Apple Intelligence** (iOS 26+) — natural-language match
///
/// The `\(.applicationName)` token expands to "KozBon" in every
/// locale. The phrases themselves are translated in
/// `AppShortcuts.xcstrings`, and the `shortTitle`s in
/// `Localizable.xcstrings`, both in this target.
///
/// The conversational `AskKozBonIntent` (and its supporting
/// `BonjourSiriPromptBuilder` / `SiriResponsePostProcessor`) was
/// removed: routing voice questions through the on-device model
/// for free-form Q&A produced inconsistent answers and made the
/// Siri experience feel less polished than the in-app chat. Users
/// who want chat should open the Chat tab; Siri is reserved for
/// concrete actions.
///
/// Open in KozBon has no phrase: it takes a service from an earlier
/// List or Find step, so it only makes sense inside a Shortcut.
public struct KozBonAppShortcuts: AppShortcutsProvider {

    /// Tint applied to the Shortcut's icon in the Shortcuts app.
    /// Matches the app's brand blue so the icon reads as a
    /// first-party Shortcut rather than a generic system one.
    public static var shortcutTileColor: ShortcutTileColor { .blue }

    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ScanForServicesIntent(),
            phrases: [
                // Voice-first: Siri scans and reads back counts.
                // Scan owns "scan", "count", and "how many"; List
                // owns "list", "show", and "what's on". No verb
                // belongs to both, so Siri can't pick the wrong one.
                "Scan my network with \(.applicationName)",
                "Scan for Bonjour services with \(.applicationName)",
                "Run a Bonjour scan with \(.applicationName)",
                "Count devices on my network with \(.applicationName)",
                "How many devices are on my network with \(.applicationName)"
            ],
            shortTitle: "Scan for Services",
            systemImageName: "wifi"
        )

        AppShortcut(
            intent: ListDiscoveredServicesIntent(),
            phrases: [
                // Data-first: "list" suits the Shortcuts editor,
                // "show" and "what's on" suit casual speech.
                "List Bonjour services with \(.applicationName)",
                "Show Bonjour services with \(.applicationName)",
                "What's on my network with \(.applicationName)",
                "List services on my network with \(.applicationName)",
                "Show devices on my network with \(.applicationName)"
            ],
            shortTitle: "List Discovered Services",
            systemImageName: "list.bullet"
        )

        AppShortcut(
            intent: FindServicesIntent(),
            phrases: [
                // "Find" belongs to no other action. The category
                // token takes a case name or synonym ("printers").
                "Find \(\.$category) with \(.applicationName)",
                "Find \(\.$category) on my network with \(.applicationName)",
                "Find services by category with \(.applicationName)"
            ],
            shortTitle: "Find Services",
            systemImageName: "magnifyingglass"
        )

        AppShortcut(
            intent: IsDeviceOnlineIntent(),
            phrases: [
                // A device name is free text, which a phrase can't
                // carry, so Siri asks for it.
                "Check if a device is online with \(.applicationName)",
                "Check if a device is on my network with \(.applicationName)"
            ],
            shortTitle: "Check If Device Is Online",
            systemImageName: "checkmark.circle"
        )

        AppShortcut(
            intent: ExplainServiceTypeIntent(),
            phrases: [
                "Explain a service type with \(.applicationName)",
                "Explain a Bonjour service with \(.applicationName)"
            ],
            shortTitle: "Explain a Service Type",
            systemImageName: "sparkles"
        )

        AppShortcut(
            intent: BroadcastServiceIntent(),
            phrases: [
                "Broadcast a service with \(.applicationName)",
                "Start a Bonjour broadcast with \(.applicationName)"
            ],
            shortTitle: "Broadcast a Service",
            systemImageName: "antenna.radiowaves.left.and.right"
        )

        AppShortcut(
            intent: StopBroadcastingIntent(),
            phrases: [
                "Stop broadcasting with \(.applicationName)",
                "Stop all broadcasts with \(.applicationName)"
            ],
            shortTitle: "Stop Broadcasting",
            systemImageName: "stop.circle"
        )
    }
}
