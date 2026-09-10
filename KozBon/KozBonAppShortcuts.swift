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
/// The `\(.applicationName)` token expands to the app's display
/// name — which is "KozBon" in every locale. It does not localize
/// the phrase: the surrounding text below is an untranslated
/// literal, so a Spanish user still has to say "Scan my network
/// with KozBon". Localizing these (and `shortTitle`) requires an
/// `AppShortcuts.xcstrings` catalog in this module; none exists
/// yet, so the whole Siri surface ships English-only.
///
/// The conversational `AskKozBonIntent` (and its supporting
/// `BonjourSiriPromptBuilder` / `SiriResponsePostProcessor`) was
/// removed: routing voice questions through the on-device model
/// for free-form Q&A produced inconsistent answers and made the
/// Siri experience feel less polished than the in-app chat. Users
/// who want chat should open the Chat tab; Siri is reserved for
/// concrete actions (scan, list).
public struct KozBonAppShortcuts: AppShortcutsProvider {

    /// Tint applied to the Shortcut's icon in the Shortcuts app.
    /// Matches the app's brand blue so the icon reads as a
    /// first-party Shortcut rather than a generic system one.
    public static var shortcutTileColor: ShortcutTileColor { .blue }

    public static var appShortcuts: [AppShortcut] {
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
