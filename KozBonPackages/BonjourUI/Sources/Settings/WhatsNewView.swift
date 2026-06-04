//
//  WhatsNewView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourCore
import BonjourLocalization

// MARK: - WhatsNewRelease

/// One release's worth of user-facing highlights for the "What's
/// New" page.
///
/// The `version` string matches what `CFBundleShortVersionString`
/// would carry at the moment of release ("4.4", "4.3", …) so the
/// `Identifiable` id is the release identity itself — no separate
/// uuid plumbing needed.
///
/// `highlights` are intentionally **dev-curated English** rather
/// than going through `BonjourLocalization`. Release notes are
/// developer-authored content that changes per release; routing
/// every bullet through the 8-language string catalog would mean
/// committing translation churn on every version bump and would
/// leave non-English locales blank between releases anyway. The
/// view-level surface labels ("What's New" title, etc.) DO go
/// through the catalog — only the bullets stay raw.
struct WhatsNewRelease: Identifiable, Hashable {

    let version: String
    let highlights: [String]

    var id: String { version }
}

// MARK: - WhatsNewView

/// Read-only page surfacing one section per release since the 3.0
/// baseline. Pushed onto the navigation stack from the
/// `SettingsView` About section.
struct WhatsNewView: View {

    var body: some View {
        List {
            ForEach(Self.releases) { release in
                Section {
                    ForEach(release.highlights, id: \.self) { highlight in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(verbatim: "•")
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)
                            Text(verbatim: highlight)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        // Combine the bullet and text into one
                        // VoiceOver element, then pin the label
                        // to the highlight content. `.combine`
                        // alone would still leave the rotor with
                        // a row, but the bullet `Text` could leak
                        // a "bullet" pronunciation on some
                        // VoiceOver versions despite
                        // `.accessibilityHidden(true)` — the
                        // explicit label forecloses that.
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(Text(verbatim: highlight))
                    }
                } header: {
                    // Visual: bare version string ("4.4" / "3.7")
                    // — pure digits and a dot, no localization
                    // needed and the page title already gives it
                    // context. VoiceOver: explicit "Version 4.4"
                    // phrasing so heading-rotor navigation reads
                    // unambiguously.
                    Text(verbatim: release.version)
                        .font(.headline)
                        .accessibilityLabel(
                            Strings.Accessibility.whatsNewVersionHeader(release.version)
                        )
                        .accessibilityAddTraits(.isHeader)
                }
            }
        }
        .navigationTitle(String(localized: Strings.Settings.whatsNew))
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .accessibilityIdentifier("whats_new_list")
    }

    // MARK: - Release Notes

    /// Newest-first list of releases since major version 3.0.
    /// Curated from the actual git commit history between each
    /// `Bump version to …` commit; bullets focus on user-visible
    /// changes (new tabs, new features, fixes the user would
    /// notice) and skip refactors / tooling / CI.
    ///
    /// Update by prepending a new entry on each release. Older
    /// entries are immutable historical record.
    static let releases: [WhatsNewRelease] = [
        WhatsNewRelease(version: "4.4", highlights: [
            "Chat tab now shows a red badge when an assistant reply lands while you're scrolled away from the bottom. The badge clears the moment you scroll back to the latest message.",
            "Wider Discover and Library sidebars on macOS so hostnames and service-type identifiers fit on one line.",
            "Tighter wide-window tab bar and detail layouts on iPad and macOS.",
            "About section trimmed to just the marketing version — the redundant build-number row is gone."
        ]),
        WhatsNewRelease(version: "4.3", highlights: [
            "New GitHub Models cloud backend (OpenAI GPT-4o via GitHub) joins Anthropic Claude as an opt-in cloud assistant.",
            "Claude model picker in Preferences — choose which Claude variant to use.",
            "Brand-tinted in-app sign-in pages for each cloud provider with native link rows to your API key console."
        ]),
        WhatsNewRelease(version: "4.1", highlights: [
            "Chat automatically runs a fresh Bonjour scan when you ask about live network state.",
            "Chat session pre-warmed at launch so the first prompt streams without a cold-start lag.",
            "Hover effects, Dynamic Type cap, and busy-state hints across the chat tab for accessibility polish.",
            "BonjourChatView split into focused files for faster compile and easier review."
        ]),
        WhatsNewRelease(version: "4.0", highlights: [
            "Brand-new AI Chat tab — ask the on-device Apple Intelligence assistant about Bonjour services and the app.",
            "Response-length preference (brief / standard / detailed) carries through every AI surface.",
            "Chat remembers the conversation while the app is running.",
            "New service filters, animated list transitions when sorting, and context-aware AI prompts.",
            "Settings deep-link surfaces when Apple Intelligence is disabled or unavailable so you can flip it on without leaving KozBon."
        ]),
        WhatsNewRelease(version: "3.9", highlights: [
            "Accessibility updates across the app — VoiceOver labels, hints, and traits tightened on every screen."
        ]),
        WhatsNewRelease(version: "3.8", highlights: [
            "New Smart Home filter, plus Thread and Matter service types in the library.",
            "Comprehensive accessibility audit — VoiceOver, Dynamic Type, Reduce Motion across every surface.",
            "Markdown rendering rewrite for richer AI explanations."
        ]),
        WhatsNewRelease(version: "3.7", highlights: [
            "Brand-new Preferences tab pulling display, AI, and reset options into one place.",
            "Sort order menu and IP-address context menus on service detail rows.",
            "Service-type expertise level setting for adjusting AI explanations.",
            "Haptic feedback when selecting a service type to broadcast.",
            "Loading spinner during initial scan; macOS sheet sizing fixed."
        ]),
        WhatsNewRelease(version: "3.6", highlights: [
            "On-device AI explanations for any service in the library and on Discover via long-press.",
            "macOS-native app icon for the menu bar and Dock.",
            "Long-press context menus throughout for copying service details."
        ]),
        WhatsNewRelease(version: "3.5", highlights: [
            "visionOS and macOS toolbar styling fixes.",
            "Detail view navigation polish across platforms."
        ]),
        WhatsNewRelease(version: "3.4", highlights: [
            "Done button on forms now stays disabled until inputs validate.",
            "Toolbar icons simplified to plain SF Symbols without circle fills.",
            "Removed singletons from the scanner and publish manager for cleaner internals.",
            "Trimmed unused assets from the catalog."
        ]),
        WhatsNewRelease(version: "3.3", highlights: [
            "Centralized iconography across the app using SF Symbols.",
            "Improved sorting on the nearby services list.",
            "macOS top tab bar fixes and tab icon polish.",
            "Removed legacy Bluetooth references."
        ]),
        WhatsNewRelease(version: "3.2", highlights: [
            "Six-language localization — English, Spanish, French, German, Japanese, Simplified Chinese.",
            "Right-to-left support for Arabic and Hebrew added in a follow-up."
        ]),
        WhatsNewRelease(version: "3.1", highlights: [
            "TXT record editing on published services.",
            "Project polish for App Store Connect submission."
        ]),
        WhatsNewRelease(version: "3.0", highlights: [
            "Bonjour service discovery across iPhone, iPad, macOS, and visionOS.",
            "Custom service type library with editable TXT records.",
            "Service publishing — broadcast your own services from this device.",
            "Background continuous scan with live service refresh."
        ])
    ]
}
