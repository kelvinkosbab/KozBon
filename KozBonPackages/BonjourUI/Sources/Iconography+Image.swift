//
//  Iconography+Image.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourCore

// MARK: - Iconography + SwiftUI Image

/// Extends `Iconography` with SwiftUI `Image` properties for direct use in views.
///
/// ```swift
/// // Instead of:
/// Image(systemName: Iconography.copy)
///
/// // Use:
/// Iconography.copyImage
/// ```
public extension Iconography {

    // MARK: - App Branding

    /// Bonjour protocol icon image.
    static var bonjourImage: Image { Image(systemName: bonjour) }

    /// AirPort Extreme base station icon image.
    static var airportExtremeImage: Image { Image(systemName: airportExtreme) }

    // MARK: - Navigation & Tabs

    /// Supported services tab icon image.
    static var serviceLibraryImage: Image { Image(systemName: serviceLibrary) }

    /// Antenna icon image.
    static var antennaImage: Image { Image(systemName: antenna) }

    /// Create service type icon image.
    static var createServiceTypeImage: Image { Image(systemName: createServiceType) }

    // MARK: - Actions

    /// Add/create item icon image.
    static var addImage: Image { Image(systemName: add) }

    /// Remove/delete item icon image.
    static var removeImage: Image { Image(systemName: remove) }

    /// Cancel/close icon image.
    static var cancelImage: Image { Image(systemName: cancel) }

    /// Confirm/done icon image.
    static var confirmImage: Image { Image(systemName: confirm) }

    /// Sort icon image.
    static var sortImage: Image { Image(systemName: sort) }

    /// Refresh icon image.
    static var refreshImage: Image { Image(systemName: refresh) }

    // MARK: - Clipboard & Copy

    /// Copy to clipboard icon image.
    static var copyImage: Image { Image(systemName: copy) }

    /// Copy to clipboard alternate icon image.
    static var copyAlternateImage: Image { Image(systemName: copyAlternate) }

    // MARK: - Network

    /// Network/connectivity icon image.
    static var networkImage: Image { Image(systemName: network) }

    /// Globe/web icon image.
    static var globeImage: Image { Image(systemName: globe) }

    /// Phone icon image.
    static var phoneImage: Image { Image(systemName: phone) }

    /// Wireless radio waves icon image.
    static var radioWavesImage: Image { Image(systemName: radioWaves) }

    // MARK: - Information

    /// Info circle icon image.
    static var infoImage: Image { Image(systemName: info) }

    /// List icon image.
    static var listImage: Image { Image(systemName: list) }

    // MARK: - Selection

    /// Selected/checked circle icon image.
    static var selectedImage: Image { Image(systemName: selected) }

    /// Unselected/empty circle icon image.
    static var unselectedImage: Image { Image(systemName: unselected) }

    // MARK: - macOS

    /// Open in new window icon image.
    static var openInNewWindowImage: Image { Image(systemName: openInNewWindow) }

    // MARK: - Devices

    /// Desktop computer icon image.
    static var desktopImage: Image { Image(systemName: desktop) }

    /// Mobile device icon image.
    static var mobileDeviceImage: Image { Image(systemName: mobileDevice) }

    /// Mac and iPhone together icon image.
    static var macAndIphoneImage: Image { Image(systemName: macAndIphone) }

    /// Car icon image.
    static var carImage: Image { Image(systemName: car) }

    /// TV icon image.
    static var tvImage: Image { Image(systemName: tv) }

    /// Apple TV icon image.
    static var appleTVImage: Image { Image(systemName: appleTV) }

    /// Apple TV remote icon image.
    static var appleTVRemoteImage: Image { Image(systemName: appleTVRemote) }

    /// AV remote icon image.
    static var avRemoteImage: Image { Image(systemName: avRemote) }

    /// Xserve icon image.
    static var xserveImage: Image { Image(systemName: xserve) }

    // MARK: - Smart Home

    /// HomeKit icon image.
    static var homeKitImage: Image { Image(systemName: homeKit) }

    /// House icon image.
    static var houseImage: Image { Image(systemName: house) }

    // MARK: - Media & Audio

    /// AirPlay video icon image.
    static var airplayVideoImage: Image { Image(systemName: airplayVideo) }

    /// Speaker icon image.
    static var speakerImage: Image { Image(systemName: speaker) }

    /// Multi-speaker icon image.
    static var multiSpeakerImage: Image { Image(systemName: multiSpeaker) }

    /// Music note icon image.
    static var musicNoteImage: Image { Image(systemName: musicNote) }

    /// Music note list icon image.
    static var musicNoteListImage: Image { Image(systemName: musicNoteList) }

    /// Play on TV icon image.
    static var playTVImage: Image { Image(systemName: playTV) }

    /// Play rectangle icon image.
    static var playRectangleImage: Image { Image(systemName: playRectangle) }

    /// Piano keys icon image.
    static var pianoKeysImage: Image { Image(systemName: pianoKeys) }

    // MARK: - Files & Storage

    /// Folder icon image.
    static var folderImage: Image { Image(systemName: folder) }

    /// File transfer icon image.
    static var fileTransferImage: Image { Image(systemName: fileTransfer) }

    /// External drive icon image.
    static var externalDriveImage: Image { Image(systemName: externalDrive) }

    // MARK: - Printing & Scanning

    /// Printer icon image.
    static var printerImage: Image { Image(systemName: printer) }

    /// Scanner icon image.
    static var scannerImage: Image { Image(systemName: scanner) }

    // MARK: - Development

    /// Terminal/SSH icon image.
    static var terminalImage: Image { Image(systemName: terminal) }

    /// Build/hammer icon image.
    static var buildImage: Image { Image(systemName: build) }

    /// Settings icon image (single gear).
    static var settingsImage: Image { Image(systemName: settings) }

    /// Gears icon image.
    static var gearsImage: Image { Image(systemName: gears) }

    /// Code/source control icon image.
    static var sourceControlImage: Image { Image(systemName: sourceControl) }

    /// Bug/debug icon image.
    static var debugImage: Image { Image(systemName: debug) }

    // MARK: - Data

    /// Database/cylinder icon image.
    static var databaseImage: Image { Image(systemName: database) }

    /// Chart/monitoring icon image.
    static var chartImage: Image { Image(systemName: chart) }

    // MARK: - Communication

    /// Chat bubble icon image.
    static var chatImage: Image { Image(systemName: chat) }

    /// Link icon image.
    static var linkImage: Image { Image(systemName: link) }

    /// People/directory icon image.
    static var peopleImage: Image { Image(systemName: people) }

    // MARK: - Security

    /// Lock/password icon image.
    static var lockImage: Image { Image(systemName: lock) }

    // MARK: - Camera & Photo

    /// Camera icon image.
    static var cameraImage: Image { Image(systemName: camera) }

    // MARK: - Gaming

    /// Game controller icon image.
    static var gameControllerImage: Image { Image(systemName: gameController) }

    // MARK: - Design

    /// Paintbrush icon image.
    static var paintbrushImage: Image { Image(systemName: paintbrush) }

    /// Paintbrush pointed icon image.
    static var paintbrushPointedImage: Image { Image(systemName: paintbrushPointed) }

    // MARK: - Administration

    /// Admin/management panels icon image.
    static var adminPanelsImage: Image { Image(systemName: adminPanels) }

    // MARK: - Default

    /// Wi-Fi icon image.
    static var wifiImage: Image { Image(systemName: wifi) }
}
