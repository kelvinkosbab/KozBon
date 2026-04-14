//
//  BonjourServiceSortType.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourCore
import BonjourLocalization

// MARK: - BonjourServiceSortType

/// A sort or filter option describing how nearby services should be ordered or filtered in lists.
///
/// Sort options reorder all services. Filter options show only matching services.
public enum BonjourServiceSortType: Identifiable, CaseIterable {

    // MARK: - Sort Options

    /// Sort by host name in ascending (A → Z) order.
    case hostNameAsc

    /// Sort by host name in descending (Z → A) order.
    case hostNameDesc

    /// Sort by service type name in ascending (A → Z) order.
    case serviceNameAsc

    /// Sort by service type name in descending (Z → A) order.
    case serviceNameDesc

    // MARK: - Filters

    /// Filter to show only smart home services (Thread, Matter, HomeKit, etc.).
    case smartHome

    /// Filter to show only Apple device services (AirPlay, AirDrop, Apple TV, etc.).
    case appleDevices

    /// Filter to show only media and streaming services (AirPlay, Spotify, Sonos, etc.).
    case mediaAndStreaming

    /// Filter to show only printer and scanner services.
    case printersAndScanners

    /// Filter to show only remote access services (SSH, VNC, RDP, etc.).
    case remoteAccess

    /// A stable identifier for the sort option.
    public var id: String {
        switch self {
        case .hostNameAsc: "hostNameAsc"
        case .hostNameDesc: "hostNameDesc"
        case .serviceNameAsc: "serviceNameAsc"
        case .serviceNameDesc: "serviceNameDesc"
        case .smartHome: "smartHome"
        case .appleDevices: "appleDevices"
        case .mediaAndStreaming: "mediaAndStreaming"
        case .printersAndScanners: "printersAndScanners"
        case .remoteAccess: "remoteAccess"
        }
    }

    /// A localized, user-facing title describing the sort option.
    public var title: String {
        switch self {
        case .hostNameAsc: String(localized: Strings.SortOptions.hostNameAsc)
        case .hostNameDesc: String(localized: Strings.SortOptions.hostNameDesc)
        case .serviceNameAsc: String(localized: Strings.SortOptions.serviceTypeAsc)
        case .serviceNameDesc: String(localized: Strings.SortOptions.serviceTypeDesc)
        case .smartHome: String(localized: Strings.SortOptions.smartHome)
        case .appleDevices: String(localized: Strings.SortOptions.appleDevices)
        case .mediaAndStreaming: String(localized: Strings.SortOptions.mediaAndStreaming)
        case .printersAndScanners: String(localized: Strings.SortOptions.printersAndScanners)
        case .remoteAccess: String(localized: Strings.SortOptions.remoteAccess)
        }
    }

    /// The SF Symbol name for this sort option's menu icon.
    public var iconName: String {
        switch self {
        case .hostNameAsc, .serviceNameAsc: "arrow.up"
        case .hostNameDesc, .serviceNameDesc: "arrow.down"
        case .smartHome: Iconography.homeKit
        case .appleDevices: Iconography.macAndIphone
        case .mediaAndStreaming: Iconography.airplayVideo
        case .printersAndScanners: Iconography.printer
        case .remoteAccess: Iconography.terminal
        }
    }

    /// Whether this option filters the list (vs reordering it).
    public var isFilter: Bool {
        switch self {
        case .hostNameAsc, .hostNameDesc, .serviceNameAsc, .serviceNameDesc:
            false
        case .smartHome, .appleDevices, .mediaAndStreaming, .printersAndScanners, .remoteAccess:
            true
        }
    }
}
