//
//  IconographyTests.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Testing
@testable import BonjourCore

// MARK: - IconographyTests

/// Pins the SF Symbol names behind the `Iconography` catalog so they can't
/// drift silently.
///
/// We don't pin every one of the ~60 constants — picking a different SF
/// Symbol for an existing semantic role is a legitimate, intentional design
/// change and a test sweeping through every name would just add friction.
/// Instead we:
///
/// 1. Pin the names that have load-bearing call-site semantics baked into
///    the name itself (e.g. `arrowUp`, which the chat compose bar relies
///    on to point *up*).
/// 2. Enforce a catalog-wide invariant — no constant may be empty — so that
///    a typo-deleted value surfaces here before it ships as a missing icon.
@Suite("Iconography")
struct IconographyTests {

    // MARK: - Arrow constants
    //
    // These back the chat compose bar's send button (`arrowUp`) and the
    // suggestion-chip affordance (`arrowUpRight`). The direction is implied
    // by the constant name, so a swap would be a semantic regression the
    // compiler can't catch.

    @Test("`arrowUp` resolves to the upward `arrow.up` symbol the chat send button relies on")
    func arrowUpIsUpwardArrow() {
        #expect(Iconography.arrowUp == "arrow.up")
    }

    @Test("`arrowUpRight` resolves to the diagonal `arrow.up.right` symbol used on suggestion chips")
    func arrowUpRightIsDiagonalArrow() {
        #expect(Iconography.arrowUpRight == "arrow.up.right")
    }

    // MARK: - Catalog invariant

    /// Every published constant must be a non-empty SF Symbol name. An
    /// empty string would render as a blank image at the call site, which
    /// typically goes unnoticed in QA until it ships.
    @Test("Every catalog constant is non-empty so no call site renders a blank icon")
    func everyConstantIsNonEmpty() {
        for constant in Self.allConstants {
            #expect(!constant.isEmpty)
        }
    }

    // MARK: - Catalog

    /// Every string constant exposed on `Iconography`.
    ///
    /// Kept as a static rather than inlined in the test so the function
    /// body stays compact enough for the `function_body_length` lint limit,
    /// and so future icon additions have a single, obvious place to update.
    private static let allConstants: [String] = [
        // App Branding
        Iconography.bonjour,
        Iconography.appleIntelligence,
        Iconography.airportExtreme,
        // Navigation & Tabs
        Iconography.serviceLibrary,
        Iconography.antenna,
        Iconography.createServiceType,
        // Actions
        Iconography.add,
        Iconography.remove,
        Iconography.cancel,
        Iconography.confirm,
        Iconography.sort,
        Iconography.refresh,
        // Arrows
        Iconography.arrowUp,
        Iconography.arrowUpRight,
        // Clipboard & Copy
        Iconography.copy,
        Iconography.copyAlternate,
        // Network
        Iconography.network,
        Iconography.globe,
        Iconography.phone,
        Iconography.radioWaves,
        // Information
        Iconography.info,
        Iconography.list,
        // Selection
        Iconography.selected,
        Iconography.unselected,
        // macOS
        Iconography.openInNewWindow,
        // Devices
        Iconography.desktop,
        Iconography.mobileDevice,
        Iconography.macAndIphone,
        Iconography.car,
        Iconography.tv,
        Iconography.appleTV,
        Iconography.appleTVRemote,
        Iconography.avRemote,
        Iconography.xserve,
        // Smart Home
        Iconography.homeKit,
        Iconography.house,
        // Media & Audio
        Iconography.airplayVideo,
        Iconography.speaker,
        Iconography.multiSpeaker,
        Iconography.musicNote,
        Iconography.musicNoteList,
        Iconography.playTV,
        Iconography.playRectangle,
        Iconography.pianoKeys,
        // Files & Storage
        Iconography.folder,
        Iconography.fileTransfer,
        Iconography.externalDrive,
        // Printing & Scanning
        Iconography.printer,
        Iconography.scanner,
        // Development
        Iconography.terminal,
        Iconography.build,
        Iconography.settings,
        Iconography.gears,
        Iconography.sourceControl,
        Iconography.debug,
        // Data
        Iconography.database,
        Iconography.chart,
        // Communication
        Iconography.chat,
        Iconography.link,
        Iconography.people,
        // Security
        Iconography.lock,
        // Camera & Photo
        Iconography.camera,
        // Gaming
        Iconography.gameController,
        // Design
        Iconography.paintbrush,
        Iconography.paintbrushPointed,
        // Administration
        Iconography.adminPanels,
        // Default
        Iconography.wifi
    ]
}
