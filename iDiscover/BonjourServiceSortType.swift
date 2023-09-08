//
//  BonjourServiceSortType.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 9/8/23.
//  Copyright © 2023 Kozinga. All rights reserved.
//

import Foundation

// MARK: - BonjourServiceSortType

enum BonjourServiceSortType : CaseIterable {
    
    case hostNameAsc
    case hostNameDesc
    case serviceNameAsc
    case serviceNameDesc
    
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
    
    func sorted(services: [BonjourService]) -> [BonjourService] {
        switch self {
        case .hostNameAsc:
            return services.sorted { service1, service2 -> Bool in
                return service1.hostName < service2.hostName
            }
        
        case .hostNameDesc:
        return services.sorted { service1, service2 -> Bool in
            return service1.hostName > service2.hostName
        }
        
        case .serviceNameAsc:
        return services.sorted { service1, service2 -> Bool in
            return service1.serviceType.name < service2.serviceType.name
        }
        
        case .serviceNameDesc:
            return services.sorted { service1, service2 -> Bool in
                return service1.serviceType.name > service2.serviceType.name
            }
        }
    }
}
