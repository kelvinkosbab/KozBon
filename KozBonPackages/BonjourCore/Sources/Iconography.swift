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

    /// AirPort Extreme base station icon.
    public static let airportExtreme = "airport.extreme"

    // MARK: - Navigation & Tabs

    /// Supported services tab icon (library).
    public static let serviceLibrary = "books.vertical"

    /// Antenna icon for broadcasting and wireless services.
    public static let antenna = "antenna.radiowaves.left.and.right"

    /// Create/add service type icon.
    public static let createServiceType = "badge.plus.radiowaves.forward"

    // MARK: - Actions

    /// Add/create item icon (filled circle with plus).
    public static let add = "plus.circle.fill"

    /// Remove/delete item icon (filled circle with minus).
    public static let remove = "minus.circle.fill"

    /// Cancel/close icon (filled circle with X).
    public static let cancel = "x.circle.fill"

    /// Confirm/done icon (filled circle with checkmark).
    public static let confirm = "checkmark.circle.fill"

    /// Sort icon (arrows in circle).
    public static let sort = "arrow.up.arrow.down.circle.fill"

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

    // MARK: - Default

    /// Wi-Fi icon (default fallback for unknown service types).
    public static let wifi = "wifi"
}
