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

    var hostOrServiceTitle: String {
        switch self {
        case .hostNameAsc:
            NSLocalizedString("By host name ascending", comment: "By host name ascending section title")
            
        case .hostNameDesc:
            NSLocalizedString("By host name descending", comment: "By host name descending section title")
            
        case .serviceNameAsc:
            NSLocalizedString("By service name ascending", comment: "By service name ascending section title")
            
        case .serviceNameDesc:
            NSLocalizedString("By service name descending", comment: "By service name descending section title")
        }
    }
}
