//
//  BonjourServiceSortType.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourLocalization

// MARK: - BonjourServiceSortType

/// A sort option describing how nearby services should be ordered in lists.
///
/// Host name options cluster services from the same device together.
/// Service type options cluster services of the same protocol together.
public enum BonjourServiceSortType: Identifiable, CaseIterable {

    /// Sort by host name in ascending (A → Z) order.
    case hostNameAsc

    /// Sort by host name in descending (Z → A) order.
    case hostNameDesc

    /// Sort by service type name in ascending (A → Z) order.
    case serviceNameAsc

    /// Sort by service type name in descending (Z → A) order.
    case serviceNameDesc

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
        }
    }
}
