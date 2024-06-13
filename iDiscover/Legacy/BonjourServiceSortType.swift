//
//  BonjourServiceSortType.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 9/8/23.
//  Copyright © 2023 Kozinga. All rights reserved.
//

import Foundation

// MARK: - BonjourServiceSortType

enum BonjourServiceSortType: Identifiable, CaseIterable {

    case hostNameAsc
    case hostNameDesc
    case serviceNameAsc
    case serviceNameDesc

    var id: String {
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

    var string: String {
        switch self {
        case .hostNameAsc:
            NSLocalizedString("Host Name ASC", comment: "Host Name ASC sort title")
        case .hostNameDesc:
            NSLocalizedString("Host Name DESC", comment: "Host Name DESC sort title")
        case .serviceNameAsc:
            NSLocalizedString("Service Name ASC", comment: "Service Name ASC sort title")
        case .serviceNameDesc:
            NSLocalizedString("Service Name DESC", comment: "Service Name DESC sort title")
        }
    }
}
