//
//  BonjourServiceCategory.swift
//  BonjourModels
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourCore
import BonjourLocalization

// MARK: - BonjourServiceCategory

/// Coarse-grained groupings of Bonjour service types used as filter
/// buckets in the Discover and Library tabs and as taxonomy hints in
/// the AI assistant's context block.
///
/// Categories are deliberately not a strict partition: a few service
/// types belong to more than one category (e.g. `airplay` is both
/// `appleDevices` and `mediaAndStreaming`). When that happens both
/// matching categories surface the type. This is the desired
/// behavior — users picking the "Apple" lens still see AirPlay, and
/// users picking "Media & Streaming" still see AirPlay, even though
/// it's strictly speaking the same service.
///
/// Adding a new service type requires checking whether it should
/// appear in any category here. The default (no edit) is "Other" —
/// it shows in unfiltered views but never in a filtered one.
public enum BonjourServiceCategory: String, CaseIterable, Sendable, Identifiable {

    /// HomeKit, Matter, Thread, and other smart-home / IoT protocols.
    case smartHome

    /// Services Apple devices advertise (AirPlay, AirDrop, Apple TV
    /// pairing, Continuity, etc.).
    case appleDevices

    /// Services that stream audio or video to or from a device.
    case mediaAndStreaming

    /// Network printers and scanners (IPP, AirScan, LPD, etc.).
    case printersAndScanners

    /// Shell, screen-sharing, and remote-management protocols.
    case remoteAccess

    public var id: String { rawValue }

    // MARK: - Display

    /// A localized, user-facing title.
    public var title: LocalizedStringResource {
        switch self {
        case .smartHome: Strings.SortOptions.smartHome
        case .appleDevices: Strings.SortOptions.appleDevices
        case .mediaAndStreaming: Strings.SortOptions.mediaAndStreaming
        case .printersAndScanners: Strings.SortOptions.printersAndScanners
        case .remoteAccess: Strings.SortOptions.remoteAccess
        }
    }

    /// The SF Symbol icon associated with this category (used in
    /// menus, empty-state placeholders, and category badges).
    public var iconName: String {
        switch self {
        case .smartHome: Iconography.homeKit
        case .appleDevices: Iconography.macAndIphone
        case .mediaAndStreaming: Iconography.airplayVideo
        case .printersAndScanners: Iconography.printer
        case .remoteAccess: Iconography.terminal
        }
    }

    /// Stable English label used by the AI prompt builder so the
    /// model sees consistent category names regardless of the user's
    /// UI locale. Not localized on purpose — the model reasons in
    /// English and then renders its answer in the user's preferred
    /// language at the end.
    public var promptLabel: String {
        switch self {
        case .smartHome: "Smart Home"
        case .appleDevices: "Apple Devices"
        case .mediaAndStreaming: "Media & Streaming"
        case .printersAndScanners: "Printers & Scanners"
        case .remoteAccess: "Remote Access"
        }
    }

    // MARK: - Type Membership

    /// The set of `BonjourServiceType.type` strings that belong to
    /// this category. Used as the filter predicate in
    /// `BonjourServicesViewModel.flatActiveServices`,
    /// `SupportedServicesViewModel.filteredBuiltInServiceTypes`, and
    /// the AI prompt's library section.
    ///
    /// Categories may intentionally overlap (see the type-level
    /// comment) — e.g. `airplay` is in both `appleDevices` and
    /// `mediaAndStreaming`.
    public var typeStrings: Set<String> {
        switch self {
        case .smartHome:
            [
                "matter", "meshcop", "matterc", "matterd",
                "hap", "homekit", "home-assistant",
                "powerview", "sonos", "spotify-connect",
                "hue", "lifx", "ecobee", "tasmota",
                "octoprint", "klipper",
                "mqtt", "coap"
            ]
        case .appleDevices:
            [
                "airplay", "airdrop", "appletv", "appletv-v2", "appletv-v3", "appletv-v4",
                "appletv-itunes", "appletv-pair",
                "apple-mobdev", "apple-mobdev2", "apple-mobdev3",
                "apple-midi", "applerdbg", "apple-sasl",
                "hap", "homekit", "companion-link", "continuity",
                "keynoteaccess", "keynotepair", "keynotepairing",
                "KeynoteControl", "mediaremotetv", "raop",
                "device-info", "airport", "eppc", "workstation",
                "carplay_ctrl", "sleep-proxy"
            ]
        case .mediaAndStreaming:
            [
                "airplay", "raop", "spotify-connect", "sonos",
                "googlecast", "daap", "dpap", "home-sharing",
                "rtsp", "roku-rcp", "amzn-wplay", "nvstream",
                "touch-able", "ptp",
                "plex", "jellyfin", "emby", "xbmc",
                "btp", "steam"
            ]
        case .printersAndScanners:
            [
                "printer", "ipp", "ipps", "pdl-datastream",
                "riousbprint", "scanner", "uscan", "uscans"
            ]
        case .remoteAccess:
            [
                "ssh", "sftp-ssh", "udisks-ssh", "vnc", "rfb",
                "rdp", "telnet", "eppc", "servermgr",
                "net-assistant"
            ]
        }
    }

    /// Returns `true` if the given service type belongs to this
    /// category.
    public func matches(_ serviceType: BonjourServiceType) -> Bool {
        typeStrings.contains(serviceType.type)
    }

    /// Returns `true` if the given service's type belongs to this
    /// category.
    public func matches(_ service: BonjourService) -> Bool {
        typeStrings.contains(service.serviceType.type)
    }
}
