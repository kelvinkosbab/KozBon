//
//  KozBonAppShortcuts.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import AppIntents
import Foundation

// MARK: - KozBonAppShortcuts

/// Registers the suggested phrases for ``AskKozBonIntent`` so users
/// can invoke it via Siri without first creating a Shortcut by hand.
///
/// The phrases are surfaced in:
///
/// - **Siri voice** — "Hey Siri, ask KozBon …"
/// - **Spotlight** — search results for the app
/// - **Shortcuts app** — pre-built actions in the gallery
/// - **Action Button** (iPhone 15 Pro+) — assignable target
/// - **Apple Intelligence** (iOS 26+) — natural-language match
///
/// The `\(.applicationName)` token expands to the localized app
/// display name at runtime, so Spanish users hear "Pregunta a
/// KozBon" rather than the English form. The `\(\.$question)`
/// token interpolates the parameter directly so users can speak
/// the entire question in one breath ("Ask KozBon what is
/// _ipp._tcp") instead of waiting for a follow-up dialog.
@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
struct KozBonAppShortcuts: AppShortcutsProvider {

    /// Tint applied to the Shortcut's icon in the Shortcuts app.
    /// Matches the app's brand blue so the icon reads as a
    /// first-party Shortcut rather than a generic system one.
    static var shortcutTileColor: ShortcutTileColor { .blue }

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AskKozBonIntent(),
            phrases: [
                // Phrase ordering matters: Apple ranks by array
                // position and surfaces the first one most
                // prominently in Spotlight previews. "Talk to" is
                // the canonical assistant-invocation pattern
                // ("Hey Siri, talk to <app>") — leading with it
                // catches the most natural voice usage.
                //
                // After invocation Siri prompts the user for
                // their question via the `requestValueDialog`
                // on `AskKozBonIntent.question`.
                //
                // Inline-question phrases (e.g. "Ask KozBon
                // \(\.$question)") are intentionally NOT shipped
                // here: App Intents requires inline phrase
                // parameters to be `AppEntity` or `AppEnum`, not
                // plain `String`. Wrapping the question in a
                // `QueryAppEntity` for that one feature is
                // disproportionate scope for Phase 1; users get
                // the same outcome via the two-step prompt.
                "Talk to \(.applicationName)",
                "Ask \(.applicationName)",
                "Ask \(.applicationName) a question",
                "Ask \(.applicationName) about my network",
                "Ask \(.applicationName) about Bonjour"
            ],
            shortTitle: "Ask KozBon",
            systemImageName: "bubble.left.and.bubble.right"
        )

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
