//
//  Image+Icons.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourCore

// MARK: - Image + App Iconography
//
// Named `Image` constants for every SF Symbol the app renders. Use these in
// view code instead of `Image(systemName: "…")`:
//
// - **Compile-time safety** — typos surface as build errors, not missing
//   icons at runtime.
// - **Global swap** — changing an icon across the whole app is a one-line
//   edit to the underlying `Iconography` constant.
// - **Discoverable** — autocomplete on `Image.` surfaces the full catalog.
// - **Consistent ergonomics** — matches SwiftUI's own `Color.blue` /
//   `Color.accentColor` static-accessor style.
//
// Every property defers to the string constants in `Iconography` (BonjourCore),
// which remain the single source of truth for SF Symbol names. This extension
// is the SwiftUI-facing façade so that views never touch the raw symbol string.
//
// ```swift
// // Instead of:
// Image(systemName: "bubble.left.fill")
// Image(systemName: Iconography.chat)
//
// // Write:
// Image.chat
// ```
//
// **When NOT to use this:** If the SF Symbol name is coming from the data
// layer at runtime (e.g. `serviceType.imageSystemName` on a model object),
// continue to use `Image(systemName: someString)` — that's a legitimate
// bridge from dynamic model data to a view. This façade is for *static*
// references that the app itself owns.
public extension Image {

    // MARK: - App Branding

    static var bonjour: Image { Image(systemName: Iconography.bonjour) }
    static var appleIntelligence: Image { Image(systemName: Iconography.appleIntelligence) }
    static var airportExtreme: Image { Image(systemName: Iconography.airportExtreme) }

    // MARK: - Navigation & Tabs

    static var serviceLibrary: Image { Image(systemName: Iconography.serviceLibrary) }
    static var antenna: Image { Image(systemName: Iconography.antenna) }
    static var createServiceType: Image { Image(systemName: Iconography.createServiceType) }

    // MARK: - Actions

    static var add: Image { Image(systemName: Iconography.add) }
    static var remove: Image { Image(systemName: Iconography.remove) }
    static var cancel: Image { Image(systemName: Iconography.cancel) }
    static var confirm: Image { Image(systemName: Iconography.confirm) }
    static var sort: Image { Image(systemName: Iconography.sort) }
    static var refresh: Image { Image(systemName: Iconography.refresh) }

    // MARK: - Arrows

    static var arrowUp: Image { Image(systemName: Iconography.arrowUp) }
    static var arrowUpRight: Image { Image(systemName: Iconography.arrowUpRight) }

    // MARK: - Clipboard & Copy

    static var copy: Image { Image(systemName: Iconography.copy) }
    static var copyAlternate: Image { Image(systemName: Iconography.copyAlternate) }

    // MARK: - Network

    static var network: Image { Image(systemName: Iconography.network) }
    static var globe: Image { Image(systemName: Iconography.globe) }
    static var phone: Image { Image(systemName: Iconography.phone) }
    static var radioWaves: Image { Image(systemName: Iconography.radioWaves) }

    // MARK: - Information

    static var info: Image { Image(systemName: Iconography.info) }
    static var list: Image { Image(systemName: Iconography.list) }

    // MARK: - Selection

    static var selected: Image { Image(systemName: Iconography.selected) }
    static var unselected: Image { Image(systemName: Iconography.unselected) }

    // MARK: - macOS

    static var openInNewWindow: Image { Image(systemName: Iconography.openInNewWindow) }

    // MARK: - Devices

    static var desktop: Image { Image(systemName: Iconography.desktop) }
    static var mobileDevice: Image { Image(systemName: Iconography.mobileDevice) }
    static var macAndIphone: Image { Image(systemName: Iconography.macAndIphone) }
    static var car: Image { Image(systemName: Iconography.car) }
    static var tv: Image { Image(systemName: Iconography.tv) }
    static var appleTV: Image { Image(systemName: Iconography.appleTV) }
    static var appleTVRemote: Image { Image(systemName: Iconography.appleTVRemote) }
    static var avRemote: Image { Image(systemName: Iconography.avRemote) }
    static var xserve: Image { Image(systemName: Iconography.xserve) }

    // MARK: - Smart Home

    static var homeKit: Image { Image(systemName: Iconography.homeKit) }
    static var house: Image { Image(systemName: Iconography.house) }

    // MARK: - Media & Audio

    static var airplayVideo: Image { Image(systemName: Iconography.airplayVideo) }
    static var speaker: Image { Image(systemName: Iconography.speaker) }
    static var multiSpeaker: Image { Image(systemName: Iconography.multiSpeaker) }
    static var musicNote: Image { Image(systemName: Iconography.musicNote) }
    static var musicNoteList: Image { Image(systemName: Iconography.musicNoteList) }
    static var playTV: Image { Image(systemName: Iconography.playTV) }
    static var playRectangle: Image { Image(systemName: Iconography.playRectangle) }
    static var pianoKeys: Image { Image(systemName: Iconography.pianoKeys) }

    // MARK: - Files & Storage

    static var folder: Image { Image(systemName: Iconography.folder) }
    static var fileTransfer: Image { Image(systemName: Iconography.fileTransfer) }
    static var externalDrive: Image { Image(systemName: Iconography.externalDrive) }

    // MARK: - Printing & Scanning

    static var printer: Image { Image(systemName: Iconography.printer) }
    static var scanner: Image { Image(systemName: Iconography.scanner) }

    // MARK: - Development

    static var terminal: Image { Image(systemName: Iconography.terminal) }
    static var build: Image { Image(systemName: Iconography.build) }
    static var settings: Image { Image(systemName: Iconography.settings) }
    static var gears: Image { Image(systemName: Iconography.gears) }
    static var sourceControl: Image { Image(systemName: Iconography.sourceControl) }
    static var debug: Image { Image(systemName: Iconography.debug) }

    // MARK: - Data

    static var database: Image { Image(systemName: Iconography.database) }
    static var chart: Image { Image(systemName: Iconography.chart) }

    // MARK: - Communication

    static var chat: Image { Image(systemName: Iconography.chat) }
    static var link: Image { Image(systemName: Iconography.link) }
    static var people: Image { Image(systemName: Iconography.people) }

    // MARK: - Security

    static var lock: Image { Image(systemName: Iconography.lock) }

    // MARK: - Camera & Photo

    static var camera: Image { Image(systemName: Iconography.camera) }

    // MARK: - Gaming

    static var gameController: Image { Image(systemName: Iconography.gameController) }

    // MARK: - Design

    static var paintbrush: Image { Image(systemName: Iconography.paintbrush) }
    static var paintbrushPointed: Image { Image(systemName: Iconography.paintbrushPointed) }

    // MARK: - Administration

    static var adminPanels: Image { Image(systemName: Iconography.adminPanels) }

    // MARK: - Default

    static var wifi: Image { Image(systemName: Iconography.wifi) }
}
