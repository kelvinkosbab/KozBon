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
        if let category {
            return String(localized: category.title)
        }
        switch self {
        case .hostNameAsc: return String(localized: Strings.SortOptions.hostNameAsc)
        case .hostNameDesc: return String(localized: Strings.SortOptions.hostNameDesc)
        case .serviceNameAsc: return String(localized: Strings.SortOptions.serviceTypeAsc)
        case .serviceNameDesc: return String(localized: Strings.SortOptions.serviceTypeDesc)
        case .smartHome, .appleDevices, .mediaAndStreaming, .printersAndScanners, .remoteAccess:
            // Unreachable — the `category` branch above covers these.
            // The exhaustive switch is here to satisfy the compiler.
            return ""
        }
    }

    /// The SF Symbol name for this sort option's menu icon.
    public var iconName: String {
        if let category {
            return category.iconName
        }
        switch self {
        case .hostNameAsc, .serviceNameAsc: return "arrow.up"
        case .hostNameDesc, .serviceNameDesc: return "arrow.down"
        case .smartHome, .appleDevices, .mediaAndStreaming, .printersAndScanners, .remoteAccess:
            // Unreachable — covered by the `category` branch above.
            return ""
        }
    }

    /// Whether this option filters the list (vs reordering it).
    /// Equivalent to `category != nil`.
    public var isFilter: Bool {
        category != nil
    }

    /// The shared `BonjourServiceCategory` this filter case represents,
    /// or `nil` if the option is a sort (not a filter).
    ///
    /// The filter cases here are a UI-side enum that wraps
    /// `BonjourServiceCategory` so they can sit in the same menu as
    /// the sort cases. The category is the source of truth for
    /// titles, icons, and which service types belong — this property
    /// is the bridge.
    public var category: BonjourServiceCategory? {
        switch self {
        case .hostNameAsc, .hostNameDesc, .serviceNameAsc, .serviceNameDesc: nil
        case .smartHome: .smartHome
        case .appleDevices: .appleDevices
        case .mediaAndStreaming: .mediaAndStreaming
        case .printersAndScanners: .printersAndScanners
        case .remoteAccess: .remoteAccess
        }
    }
}
