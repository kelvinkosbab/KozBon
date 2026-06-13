//
//  ReleaseNote.swift
//  BonjourCore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - ReleaseNote

/// One release's worth of user-facing highlights for KozBon's
/// "What's New" surfaces.
///
/// The `version` string matches what `CFBundleShortVersionString`
/// carries at the moment of release ("4.6", "4.5", …) so the
/// `Identifiable` id is the release identity itself — no separate
/// uuid plumbing needed.
///
/// `highlights` are intentionally **dev-curated English** rather
/// than going through `BonjourLocalization`. Release notes are
/// developer-authored content that changes per release; routing
/// every bullet through the 8-language string catalog would mean
/// committing translation churn on every version bump and would
/// leave non-English locales blank between releases anyway. The
/// `WhatsNewView` surface labels ("What's New" title, version-
/// header accessibility) DO go through the catalog — only the
/// bullets stay raw. The AI chat assistant reads these English
/// bullets and translates the gist into the user's language at
/// response time (it's already locale-pinned by the system prompt).
///
/// Lives in `BonjourCore` — the base module — so both the
/// `WhatsNewView` (in `BonjourUI`) and the chat prompt builder
/// (in `BonjourAICore`) can read the same source of truth. The
/// two modules don't depend on each other, so a shared ancestor
/// is the only place the data can be reached from both.
public struct ReleaseNote: Identifiable, Hashable, Sendable {

    /// User-visible marketing version this entry describes (e.g.
    /// "4.6"). Matches `CFBundleShortVersionString` at release.
    public let version: String

    /// User-facing highlight bullets, newest-first within the
    /// release. Dev-curated English (see type doc).
    public let highlights: [String]

    public var id: String { version }

    public init(version: String, highlights: [String]) {
        self.version = version
        self.highlights = highlights
    }
}

// MARK: - ReleaseNotes

/// The canonical, newest-first list of KozBon releases since major
/// version 3.0.
///
/// Curated from the actual git commit history between each
/// "Bump version to …" commit; bullets focus on user-visible
/// changes (new tabs, new features, fixes the user would notice)
/// and skip refactors / tooling / CI.
///
/// Update by prepending a new entry on each release. Older entries
/// are immutable historical record. Consumed by ``WhatsNewView``
/// (the Preferences → About page) and by the chat assistant's
/// prompt builder (so "what's new?" questions answer from real
/// data instead of hallucinated version history).
public enum ReleaseNotes {

    /// Newest-first releases since 3.0.
    public static let all: [ReleaseNote] = [
        ReleaseNote(version: "4.6", highlights: [
            "Internal polish and Xcode 27 / iOS 26 compatibility — the assistant tab badge and brand icons render correctly on the new SDK.",
            "Reliability improvements across the chat surface, including a swipe-delete animation fix in the broadcast TXT-record list.",
            "Brand names (Apple Intelligence, Claude, GitHub) now reliably stay in English across every locale."
        ]),
        ReleaseNote(version: "4.5", highlights: [
            "Chat tab now shows a red badge in compact / portrait windows when an assistant reply lands while you're scrolled away from the bottom. The badge clears the moment you scroll back to the latest message.",
            "Wider Discover and Library sidebars on macOS so hostnames and service-type identifiers fit on one line.",
            "Tighter wide-window tab bar and detail layouts on iPad and macOS.",
            "New What's New page in Preferences → About lists every release since 3.0.",
            "About section trimmed to just the marketing version — the redundant build-number row is gone."
        ]),
        ReleaseNote(version: "4.3", highlights: [
            "New GitHub Models cloud backend (OpenAI GPT-4o via GitHub) joins Anthropic Claude as an opt-in cloud assistant.",
            "Claude model picker in Preferences — choose which Claude variant to use.",
            "Brand-tinted in-app sign-in pages for each cloud provider with native link rows to your API key console."
        ]),
        ReleaseNote(version: "4.1", highlights: [
            "Chat automatically runs a fresh Bonjour scan when you ask about live network state.",
            "Chat session pre-warmed at launch so the first prompt streams without a cold-start lag.",
            "Hover effects, Dynamic Type cap, and busy-state hints across the chat tab for accessibility polish.",
            "BonjourChatView split into focused files for faster compile and easier review."
        ]),
        ReleaseNote(version: "4.0", highlights: [
            "Brand-new AI Chat tab — ask the on-device Apple Intelligence assistant about Bonjour services and the app.",
            "Response-length preference (brief / standard / detailed) carries through every AI surface.",
            "Chat remembers the conversation while the app is running.",
            "New service filters, animated list transitions when sorting, and context-aware AI prompts.",
            "Settings deep-link surfaces when Apple Intelligence is disabled or unavailable so you can flip it on without leaving KozBon."
        ]),
        ReleaseNote(version: "3.9", highlights: [
            "Accessibility updates across the app — VoiceOver labels, hints, and traits tightened on every screen."
        ]),
        ReleaseNote(version: "3.8", highlights: [
            "New Smart Home filter, plus Thread and Matter service types in the library.",
            "Comprehensive accessibility audit — VoiceOver, Dynamic Type, Reduce Motion across every surface.",
            "Markdown rendering rewrite for richer AI explanations."
        ]),
        ReleaseNote(version: "3.7", highlights: [
            "Brand-new Preferences tab pulling display, AI, and reset options into one place.",
            "Sort order menu and IP-address context menus on service detail rows.",
            "Service-type expertise level setting for adjusting AI explanations.",
            "Haptic feedback when selecting a service type to broadcast.",
            "Loading spinner during initial scan; macOS sheet sizing fixed."
        ]),
        ReleaseNote(version: "3.6", highlights: [
            "On-device AI explanations for any service in the library and on Discover via long-press.",
            "macOS-native app icon for the menu bar and Dock.",
            "Long-press context menus throughout for copying service details."
        ]),
        ReleaseNote(version: "3.5", highlights: [
            "visionOS and macOS toolbar styling fixes.",
            "Detail view navigation polish across platforms."
        ]),
        ReleaseNote(version: "3.4", highlights: [
            "Done button on forms now stays disabled until inputs validate.",
            "Toolbar icons simplified to plain SF Symbols without circle fills.",
            "Removed singletons from the scanner and publish manager for cleaner internals.",
            "Trimmed unused assets from the catalog."
        ]),
        ReleaseNote(version: "3.3", highlights: [
            "Centralized iconography across the app using SF Symbols.",
            "Improved sorting on the nearby services list.",
            "macOS top tab bar fixes and tab icon polish.",
            "Removed legacy Bluetooth references."
        ]),
        ReleaseNote(version: "3.2", highlights: [
            "Six-language localization — English, Spanish, French, German, Japanese, Simplified Chinese.",
            "Right-to-left support for Arabic and Hebrew added in a follow-up."
        ]),
        ReleaseNote(version: "3.1", highlights: [
            "TXT record editing on published services.",
            "Project polish for App Store Connect submission."
        ]),
        ReleaseNote(version: "3.0", highlights: [
            "Bonjour service discovery across iPhone, iPad, macOS, and visionOS.",
            "Custom service type library with editable TXT records.",
            "Service publishing — broadcast your own services from this device.",
            "Background continuous scan with live service refresh."
        ])
    ]
}
