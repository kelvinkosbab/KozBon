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
/// `summary` is what `WhatsNewView` displays: a short one- or
/// two-paragraph overview of the release, authored in **English**
/// and also its own key in the `BonjourLocalization` catalog,
/// resolved through `Strings.Settings.releaseSummary(_:)` with an
/// English fallback. `BonjourCore` can't see the catalog, which is
/// why the lookup happens in the view rather than here.
///
/// `highlights` are English-only, finer-grained facts for the chat
/// assistant's "what's new?" answers. They aren't displayed or
/// translated — the assistant answers in the user's language itself.
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

    /// One- or two-paragraph overview shown on the What's New page.
    /// English source text and catalog key (see type doc); paragraphs
    /// are separated by a blank line.
    public let summary: String

    /// Individual changes, most notable first within the release.
    /// English-only context for the chat assistant (see type doc).
    public let highlights: [String]

    public var id: String { version }

    public init(version: String, summary: String, highlights: [String]) {
        self.version = version
        self.summary = summary
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
/// Update by prepending a new entry on each release, and add its
/// `summary` to `Localizable.xcstrings` in all eight locales —
/// `scripts/validate-localizations.py` fails CI on any summary
/// missing from the catalog. Older entries are immutable historical
/// record; rewording a summary means re-keying its translations too. Consumed by ``WhatsNewView``
/// (the Settings → About page) and by the chat assistant's
/// prompt builder (so "what's new?" questions answer from real
/// data instead of hallucinated version history).
public enum ReleaseNotes {

    /// Newest-first releases since 3.0.
    public static let all: [ReleaseNote] = [
        ReleaseNote(
            version: "4.8",
            // swiftlint:disable:next line_length
            summary: "OpenAI GPT joins Apple Intelligence, Anthropic Claude, and Google Gemini as an AI option. Add your own OpenAI API key in Settings, and the GPT model picker loads the models your key can use. OpenAI bills API usage separately from a ChatGPT subscription.\n\nThe Chat tab now takes on the colours of the AI you've selected. On devices without Apple Intelligence, it also appears whenever any cloud provider has a key, not just Claude.",
            highlights: [
                // swiftlint:disable:next line_length
                "OpenAI GPT joins Apple Intelligence, Anthropic Claude, and Google Gemini as an AI backend — add your own OpenAI API key in Settings → Assistant. OpenAI bills API usage separately from any ChatGPT subscription.",
                // swiftlint:disable:next line_length
                "The GPT model picker loads the models your OpenAI key can use, so new models show up without an app update. Offline, it falls back to a built-in list.",
                // swiftlint:disable:next line_length
                "Requests to OpenAI are sent with storage turned off, so OpenAI doesn't keep a copy of your conversation — KozBon replays the conversation itself on each turn.",
                // swiftlint:disable:next line_length
                "The Chat tab's ambient background now takes on the colours of the selected AI — Apple Intelligence's glow, Claude's warm orange, Gemini's blue and violet, or OpenAI's greens — matching the send button and message bubbles.",
                // swiftlint:disable:next line_length
                "On devices without Apple Intelligence, the Chat tab now appears whenever any cloud provider has a key. Previously only a Claude key counted, which hid the tab from Gemini users."
            ]
        ),
        ReleaseNote(
            version: "4.7",
            // swiftlint:disable:next line_length
            summary: "Google Gemini joins Apple Intelligence and Anthropic Claude as an AI option, and the Claude and Gemini model pickers now load each provider's latest models. GitHub Models is gone now that GitHub has retired the service — if you used it, KozBon switches you back to Apple Intelligence.\n\nKozBon also gets a fresh look: an ambient background on every tab (with a switch to turn it off), landscape and wide layouts on iPhone, and a Nearby list organized into sections by device or service type. Siri and Shortcuts can now scan and list services, and KozBon now requires iOS, iPadOS, macOS, or visionOS 26.",
            highlights: [
                // swiftlint:disable:next line_length
                "Google Gemini joins Apple Intelligence and Anthropic Claude as an AI backend — add your own Google AI Studio key in Settings → Assistant. Each cloud provider remembers its own model choice, so switching back and forth keeps both.",
                // swiftlint:disable:next line_length
                "The Claude and Gemini model pickers now load each provider's current model list with your key, so new models show up without an app update. Offline, they fall back to a built-in list.",
                // swiftlint:disable:next line_length
                "GitHub Models is gone — GitHub retired the service on July 30. If you were using it, KozBon switches you back to Apple Intelligence, and Settings offers to delete the saved GitHub token.",
                // swiftlint:disable:next line_length
                "The Nearby list is now organized into sections — one per device by default, or one per service type with a short description of the type when you sort by service name.",
                // swiftlint:disable:next line_length
                "Every tab now sits on an ambient background — a slow colour wash that drifts like water, tinted differently per tab, and carried through to the detail pages you open from each one.",
                // swiftlint:disable:next line_length
                "New Ambient Background switch in Settings → Display turns the wash off and restores the plain system styling. It also steps aside automatically for Increase Contrast, Reduce Transparency, and Smart Invert, and holds still under Reduce Motion or Low Power Mode.",
                // swiftlint:disable:next line_length
                "iPhone now supports landscape and wide layouts, including the iPhone Duo's inner display, where the sidebar and detail pane open side by side. Settings, Chat, and detail pages keep a readable width, and the service badge names the host too — \"AirPlay – Living Room\".",
                // swiftlint:disable:next line_length
                "Siri and the Shortcuts app now offer KozBon's scan and list-services shortcuts, localized in all eight languages. Permission prompts are now translated into Arabic and Hebrew as well.",
                // swiftlint:disable:next line_length
                "Long-press any highlight on this page for an AI explanation of what it means for you, or ask the chat assistant \"what's new?\" to get answers drawn from these notes.",
                // swiftlint:disable:next line_length
                "Every AI Insights long-press now has a matching VoiceOver action, and the Broadcast forms move VoiceOver focus to the first error when a submit fails.",
                // swiftlint:disable:next line_length
                "Chat suggestions are now iMessage-style blue capsules with a send arrow, so they read as prompts you can send rather than links. On iOS 27 the Chat tab keeps its own spot at the end of the tab bar.",
                "The Preferences tab is now called Settings.",
                "KozBon now requires iOS 26, iPadOS 26, macOS 26, or visionOS 26."
            ]
        ),
        ReleaseNote(
            version: "4.6",
            // swiftlint:disable:next line_length
            summary: "A maintenance release for Xcode 27 and iOS 26. The chat tab badge and brand icons render correctly again, a broadcast list animation glitch is fixed, and brand names stay in English in every language.",
            highlights: [
                // Release-note prose is data, not code — breaking a
                // sentence across a `+` to satisfy the column limit
                // hurts the thing being read here.
                // swiftlint:disable:next line_length
                "Internal polish and Xcode 27 / iOS 26 compatibility — the assistant tab badge and brand icons render correctly on the new SDK.",
                "Reliability improvements across the chat surface, including a swipe-delete animation fix in the broadcast TXT-record list.",
                "Brand names (Apple Intelligence, Claude, GitHub) now reliably stay in English across every locale."
            ]
        ),
        ReleaseNote(
            version: "4.5",
            // swiftlint:disable:next line_length
            summary: "Better layouts on larger screens, with wider sidebars on Mac and tighter layouts on iPad and Mac. The Chat tab now shows a badge when a reply arrives while you're scrolled away, and this What's New page arrives in Preferences → About.",
            highlights: [
                // swiftlint:disable:next line_length
                "Chat tab now shows a red badge in compact / portrait windows when an assistant reply lands while you're scrolled away from the bottom. The badge clears the moment you scroll back to the latest message.",
                "Wider Discover and Library sidebars on macOS so hostnames and service-type identifiers fit on one line.",
                "Tighter wide-window tab bar and detail layouts on iPad and macOS.",
                "New What's New page in Preferences → About lists every release since 3.0.",
                "About section trimmed to just the marketing version — the redundant build-number row is gone."
            ]
        ),
        ReleaseNote(
            version: "4.3",
            // swiftlint:disable:next line_length
            summary: "GitHub Models joins Anthropic Claude as a second opt-in cloud assistant. You can also choose which Claude model to use, and each cloud provider gets its own sign-in page with a link to your API key console.",
            highlights: [
                "New GitHub Models cloud backend (OpenAI GPT-4o via GitHub) joins Anthropic Claude as an opt-in cloud assistant.",
                "Claude model picker in Preferences — choose which Claude variant to use.",
                "Brand-tinted in-app sign-in pages for each cloud provider with native link rows to your API key console."
            ]
        ),
        ReleaseNote(
            version: "4.1",
            // swiftlint:disable:next line_length
            summary: "Chat now runs a fresh network scan when you ask what's on your network, and the first answer streams faster thanks to a warmed-up session. The chat tab also gets accessibility polish.",
            highlights: [
                "Chat automatically runs a fresh Bonjour scan when you ask about live network state.",
                "Chat session pre-warmed at launch so the first prompt streams without a cold-start lag.",
                "Hover effects, Dynamic Type cap, and busy-state hints across the chat tab for accessibility polish.",
                "BonjourChatView split into focused files for faster compile and easier review."
            ]
        ),
        ReleaseNote(
            version: "4.0",
            // swiftlint:disable:next line_length
            summary: "Introducing the AI Chat tab: ask the on-device Apple Intelligence assistant about Bonjour services and the app, with a response-length setting that applies to every AI feature. Also new: service filters, animated sorting, and a shortcut to Settings when Apple Intelligence is turned off.",
            highlights: [
                "Brand-new AI Chat tab — ask the on-device Apple Intelligence assistant about Bonjour services and the app.",
                "Response-length preference (brief / standard / detailed) carries through every AI surface.",
                "Chat remembers the conversation while the app is running.",
                "New service filters, animated list transitions when sorting, and context-aware AI prompts.",
                "Settings deep-link surfaces when Apple Intelligence is disabled or unavailable so you can flip it on without leaving KozBon."
            ]
        ),
        ReleaseNote(
            version: "3.9",
            summary: "Accessibility improvements across the app, with clearer VoiceOver labels, hints, and traits on every screen.",
            highlights: [
                "Accessibility updates across the app — VoiceOver labels, hints, and traits tightened on every screen."
            ]
        ),
        ReleaseNote(
            version: "3.8",
            // swiftlint:disable:next line_length
            summary: "Adds a Smart Home filter and the Thread and Matter service types, along with a full accessibility pass covering VoiceOver, Dynamic Type, and Reduce Motion. AI explanations also get richer formatting.",
            highlights: [
                "New Smart Home filter, plus Thread and Matter service types in the library.",
                "Comprehensive accessibility audit — VoiceOver, Dynamic Type, Reduce Motion across every surface.",
                "Markdown rendering rewrite for richer AI explanations."
            ]
        ),
        ReleaseNote(
            version: "3.7",
            // swiftlint:disable:next line_length
            summary: "Introducing the Preferences tab, which gathers display, AI, and reset options in one place. Also new: a sort menu, menus for copying IP addresses, an AI detail level setting, haptics when you choose a service type to broadcast, and a loading spinner during the first scan.",
            highlights: [
                "Brand-new Preferences tab pulling display, AI, and reset options into one place.",
                "Sort order menu and IP-address context menus on service detail rows.",
                "Service-type expertise level setting for adjusting AI explanations.",
                "Haptic feedback when selecting a service type to broadcast.",
                "Loading spinner during initial scan; macOS sheet sizing fixed."
            ]
        ),
        ReleaseNote(
            version: "3.6",
            // swiftlint:disable:next line_length
            summary: "Long-press any service on Discover or in the library for an on-device AI explanation, or to copy its details. The Mac app also gets its own native icon.",
            highlights: [
                "On-device AI explanations for any service in the library and on Discover via long-press.",
                "macOS-native app icon for the menu bar and Dock.",
                "Long-press context menus throughout for copying service details."
            ]
        ),
        ReleaseNote(
            version: "3.5",
            summary: "Toolbar fixes for visionOS and macOS, plus smoother navigation in detail views on every platform.",
            highlights: [
                "visionOS and macOS toolbar styling fixes.",
                "Detail view navigation polish across platforms."
            ]
        ),
        ReleaseNote(
            version: "3.4",
            // swiftlint:disable:next line_length
            summary: "The Done button on forms now stays disabled until your input is valid, toolbar icons are simpler, and the app gets a round of under-the-hood cleanup.",
            highlights: [
                "Done button on forms now stays disabled until inputs validate.",
                "Toolbar icons simplified to plain SF Symbols without circle fills.",
                "Removed singletons from the scanner and publish manager for cleaner internals.",
                "Trimmed unused assets from the catalog."
            ]
        ),
        ReleaseNote(
            version: "3.3",
            // swiftlint:disable:next line_length
            summary: "Consistent SF Symbols icons throughout the app, better sorting in the nearby services list, and tab bar fixes on macOS.",
            highlights: [
                "Centralized iconography across the app using SF Symbols.",
                "Improved sorting on the nearby services list.",
                "macOS top tab bar fixes and tab icon polish.",
                "Removed legacy Bluetooth references."
            ]
        ),
        ReleaseNote(
            version: "3.2",
            // swiftlint:disable:next line_length
            summary: "KozBon now speaks English, Spanish, French, German, Japanese, and Simplified Chinese, with right-to-left support for Arabic and Hebrew following soon after.",
            highlights: [
                "Six-language localization — English, Spanish, French, German, Japanese, Simplified Chinese.",
                "Right-to-left support for Arabic and Hebrew added in a follow-up."
            ]
        ),
        ReleaseNote(
            version: "3.1",
            summary: "You can now edit the TXT records of services you publish, plus polish ahead of the App Store release.",
            highlights: [
                "TXT record editing on published services.",
                "Project polish for App Store Connect submission."
            ]
        ),
        ReleaseNote(
            version: "3.0",
            // swiftlint:disable:next line_length
            summary: "The foundation of KozBon: discover Bonjour services on iPhone, iPad, Mac, and Apple Vision Pro, broadcast your own services, and build a custom service type library with editable TXT records. Scanning runs continuously in the background, so the list stays live.",
            highlights: [
                "Bonjour service discovery across iPhone, iPad, macOS, and visionOS.",
                "Custom service type library with editable TXT records.",
                "Service publishing — broadcast your own services from this device.",
                "Background continuous scan with live service refresh."
            ]
        )
    ]
}
