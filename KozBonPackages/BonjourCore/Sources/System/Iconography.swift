//
//  Iconography.swift
//  BonjourCore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - Iconography

/// Centralized catalog of all SF Symbol icons used throughout the app.
///
/// Use these constants instead of hardcoding SF Symbol strings in views.
/// This ensures consistency, catches typos at compile time, and makes it
/// easy to update icons across the entire app from one place.
///
/// ```swift
/// // Instead of:
/// Label("Copy", systemImage: "doc.on.doc")
///
/// // Use:
/// Label("Copy", image: Iconography.copy)
/// ```
public enum Iconography {

    // MARK: - App Branding

    /// Bonjour protocol icon.
    public static let bonjour = "bonjour"

    /// Apple Intelligence icon. Used as the Chat tab and Insights
    /// glyph when the user has the on-device backend selected
    /// (ADR 0005).
    public static let appleIntelligence = "apple.intelligence"

    /// Anthropic Claude glyph. Used as the Chat tab and Insights
    /// glyph when the user has the Anthropic backend selected so
    /// the active provider is visible at a glance — the same
    /// purpose `appleIntelligence` serves for the on-device path.
    ///
    /// `sparkle` (single-pointed star) is the closest SF Symbol
    /// to Anthropic's published Cara/Sun brand mark without
    /// shipping a custom asset that would carry trademark
    /// constraints. The accent color (`Color.kozBonAnthropic`)
    /// carries the rest of the brand cue.
    public static let anthropicClaude = "sparkle"

    /// GitHub Models SF Symbol fallback. `Image.github` now
    /// resolves to the bundled Octocat asset
    /// (`Media.xcassets/GitHub.imageset`); this constant exists
    /// only for call sites that need a `systemImage:`-compatible
    /// name — e.g., `Label(_:systemImage:)`, which doesn't
    /// accept asset-catalog names. The "code" symbol is the
    /// closest semantic stand-in when an asset isn't reachable.
    public static let github = "chevron.left.forwardslash.chevron.right"

    /// AirPort Extreme base station icon.
    public static let airportExtreme = "airport.extreme"

    // MARK: - Navigation & Tabs

    /// Supported services tab icon (library).
    public static let serviceLibrary = "list.bullet"

    /// Antenna icon for broadcasting and wireless services.
    public static let antenna = "antenna.radiowaves.left.and.right"

    /// Create/add service type icon.
    public static let createServiceType = "badge.plus.radiowaves.forward"

    // MARK: - Actions

    /// Add/create item icon.
    public static let add = "plus"

    /// Remove/delete item icon (filled circle with minus).
    public static let remove = "minus.circle.fill"

    /// Cancel/close icon.
    public static let cancel = "xmark"

    /// Confirm/done icon.
    public static let confirm = "checkmark"

    /// Sort or filter icon — used by both the Discover tab's combined
    /// sort/filter menu and the Library tab's category filter menu.
    public static let sort = "line.3.horizontal.decrease"

    /// Refresh icon.
    public static let refresh = "arrow.clockwise"

    /// Clear / delete-all icon used by the Chat tab's "Clear chat"
    /// toolbar button. `trash` reads as "discard everything here"
    /// — the same metaphor Mail and Notes use when the action
    /// removes content the user can't recover.
    public static let clearChat = "trash"

    // MARK: - Arrows

    /// Upward arrow — used as the Send glyph in the chat compose bar.
    public static let arrowUp = "arrow.up"

    /// Upward-and-trailing arrow — used as the affordance on suggestion chips.
    public static let arrowUpRight = "arrow.up.right"

    // MARK: - Clipboard & Copy

    /// Copy to clipboard icon.
    public static let copy = "doc.on.doc"

    /// Copy to clipboard alternate icon.
    public static let copyAlternate = "doc.on.clipboard"

    // MARK: - Network

    /// Network/connectivity icon.
    public static let network = "network"

    /// Globe/web icon.
    public static let globe = "globe"

    /// Phone icon.
    public static let phone = "phone.fill"

    /// Wireless radio waves icon.
    public static let radioWaves = "dot.radiowaves.right"

    // MARK: - Information

    /// Info circle icon.
    public static let info = "info.circle"

    /// List icon.
    public static let list = "list.dash"

    // MARK: - Selection

    /// Selected/checked circle icon.
    public static let selected = "checkmark.circle.fill"

    /// Unselected/empty circle icon.
    public static let unselected = "circle"

    // MARK: - macOS

    /// Open in new window icon (macOS).
    public static let openInNewWindow = "macwindow.badge.plus"

    // MARK: - Devices

    /// Desktop computer icon.
    public static let desktop = "desktopcomputer"

    /// iPhone/mobile device icon.
    public static let mobileDevice = "platter.2.filled.iphone"

    /// Mac and iPhone together icon.
    public static let macAndIphone = "macbook.and.iphone"

    /// Car icon.
    public static let car = "car.fill"

    /// TV icon.
    public static let tv = "tv"

    /// Apple TV icon.
    public static let appleTV = "appletv"

    /// Apple TV remote icon.
    public static let appleTVRemote = "appletvremote.gen4.fill"

    /// AV remote icon.
    public static let avRemote = "av.remote"

    /// Xserve icon.
    public static let xserve = "xserve"

    // MARK: - Smart Home

    /// HomeKit icon.
    public static let homeKit = "homekit"

    /// House icon.
    public static let house = "house.fill"

    // MARK: - Media & Audio

    /// AirPlay video icon.
    public static let airplayVideo = "airplayvideo"

    /// Speaker icon.
    public static let speaker = "hifispeaker.fill"

    /// Multi-speaker icon.
    public static let multiSpeaker = "hifispeaker.2.fill"

    /// Music note icon.
    public static let musicNote = "music.note"

    /// Music note list icon.
    public static let musicNoteList = "music.note.list"

    /// Play on TV icon.
    public static let playTV = "play.tv"

    /// Play rectangle icon.
    public static let playRectangle = "play.rectangle.fill"

    /// Piano keys icon.
    public static let pianoKeys = "pianokeys"

    // MARK: - Files & Storage

    /// Folder icon.
    public static let folder = "folder.fill"

    /// File transfer (up/down arrows) icon.
    public static let fileTransfer = "arrow.up.arrow.down.square"

    /// External drive icon.
    public static let externalDrive = "externaldrive.fill"

    // MARK: - Printing & Scanning

    /// Printer icon.
    public static let printer = "printer.fill"

    /// Scanner icon.
    public static let scanner = "scanner.fill"

    // MARK: - Development

    /// Terminal/SSH icon.
    public static let terminal = "greaterthan.square"

    /// Build/hammer icon.
    public static let build = "hammer.fill"

    /// Settings/preferences icon.
    public static let settings = "gear"

    /// Gears icon.
    public static let gears = "gearshape.2.fill"

    /// Code/source control icon.
    public static let sourceControl = "chevron.left.forwardslash.chevron.right"

    /// Bug/debug icon.
    public static let debug = "ant.fill"

    // MARK: - Data

    /// Database/cylinder icon.
    public static let database = "cylinder.split.1x2.fill"

    /// Chart/monitoring icon.
    public static let chart = "chart.line.uptrend.xyaxis"

    // MARK: - Communication

    /// Chat bubble icon.
    public static let chat = "bubble.left.fill"

    /// Speech bubble with ellipsis — used for the "long
    /// conversation" advisory banner in the chat view, where it
    /// signals "lots of back-and-forth has happened" at a
    /// glance.
    public static let chatEllipsis = "ellipsis.bubble"

    /// Link icon.
    public static let link = "link"

    /// People/directory icon.
    public static let people = "person.2.fill"

    // MARK: - Security

    /// Lock/password icon.
    public static let lock = "lock.fill"

    // MARK: - Camera & Photo

    /// Camera icon.
    public static let camera = "camera.fill"

    // MARK: - Gaming

    /// Game controller icon.
    public static let gameController = "gamecontroller.fill"

    // MARK: - Design

    /// Paintbrush icon.
    public static let paintbrush = "paintbrush.fill"

    /// Paintbrush pointed icon.
    public static let paintbrushPointed = "paintbrush.pointed.fill"

    // MARK: - Administration

    /// Admin/management panels icon.
    public static let adminPanels = "squares.leading.rectangle"

    // MARK: - Accounts & Sign-In

    /// "Add account" icon. Used by the Settings → AI Backend
    /// section's "Sign in to Claude" CTA and any future
    /// add-account affordance.
    public static let signIn = "person.crop.circle.badge.plus"

    /// Trailing disclosure chevron — used by row-style buttons
    /// to signal "tapping here presents another surface."
    public static let disclosure = "chevron.right"

    /// Outward-pointing arrow in a square — signals that
    /// tapping leaves the app and opens an external surface
    /// (typically a web page in the user's default browser).
    /// Used by "Get an API key" in the Claude sign-in sheet.
    public static let externalLink = "arrow.up.right.square"

    /// Filled checkmark inside a circle. Used by the Settings
    /// AI Backend "Signed in" status row. Distinct from
    /// ``selected`` (same SF Symbol name) so future divergence
    /// can be applied without disturbing every selected-state
    /// usage in pickers.
    public static let signedIn = "checkmark.circle.fill"

    // MARK: - Status

    /// Filled triangle with an exclamation mark — used as the
    /// leading glyph on the chat error banner. Communicates
    /// "something went wrong" at a glance; the colored fill (red)
    /// is applied at the view layer so the symbol stays neutral
    /// here.
    public static let errorBanner = "exclamationmark.triangle.fill"

    // MARK: - Default

    /// Wi-Fi icon (default fallback for unknown service types).
    public static let wifi = "wifi"

    /// Wi-Fi-off icon. Used by the Discover tab's empty state when the
    /// device isn't on a local network — Bonjour discovery can't reach
    /// anything from cellular-only or offline paths.
    public static let wifiSlash = "wifi.slash"
}
