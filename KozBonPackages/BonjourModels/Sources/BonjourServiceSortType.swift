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
/// Host name options cluster services from the same device together.
/// Service type options cluster services of the same protocol together.
/// The Thread & Matter option filters to show only Thread and Matter services.
public enum BonjourServiceSortType: Identifiable, CaseIterable {

    /// Sort by host name in ascending (A → Z) order.
    case hostNameAsc

    /// Sort by host name in descending (Z → A) order.
    case hostNameDesc

    /// Sort by service type name in ascending (A → Z) order.
    case serviceNameAsc

    /// Sort by service type name in descending (Z → A) order.
    case serviceNameDesc

    /// Filter to show only smart home services (Thread, Matter, HomeKit, etc.).
    case smartHome

    /// A stable identifier for the sort option.
    public var id: String {
        switch self {
        case .hostNameAsc:
            "hostNameAsc"
        case .hostNameDesc:
            "hostNameDesc"
        case .serviceNameAsc:
            "serviceNameAsc"
        case .serviceNameDesc:
            "serviceNameDesc"
        case .smartHome:
            "smartHome"
        }
    }

    /// A localized, user-facing title describing the sort option.
    public var title: String {
        switch self {
        case .hostNameAsc:
            String(localized: Strings.SortOptions.hostNameAsc)
        case .hostNameDesc:
            String(localized: Strings.SortOptions.hostNameDesc)
        case .serviceNameAsc:
            String(localized: Strings.SortOptions.serviceTypeAsc)
        case .serviceNameDesc:
            String(localized: Strings.SortOptions.serviceTypeDesc)
        case .smartHome:
            String(localized: Strings.SortOptions.smartHome)
        }
    }

    /// The SF Symbol name for this sort option's menu icon.
    public var iconName: String {
        switch self {
        case .hostNameAsc, .serviceNameAsc:
            "arrow.up"
        case .hostNameDesc, .serviceNameDesc:
            "arrow.down"
        case .smartHome:
            Iconography.homeKit
        }
    }
}
