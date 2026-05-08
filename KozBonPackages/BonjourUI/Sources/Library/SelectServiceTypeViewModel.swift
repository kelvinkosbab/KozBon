//
//  SelectServiceTypeViewModel.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourModels

// MARK: - SelectServiceTypeViewModel

/// View model for the service type selection screen, providing searchable lists of
/// built-in and custom Bonjour service types.
@MainActor
@Observable
final class SelectServiceTypeViewModel {

    private var builtInServiceTypes: [BonjourServiceType] = []
    private var customServiceTypes: [BonjourServiceType] = []

    var searchText: String = ""

    var filteredBuiltInServiceTypes: [BonjourServiceType] {
        if searchText.isEmpty {
            builtInServiceTypes
        } else {
            builtInServiceTypes.filter { serviceType in
                let isInName = serviceType.name.containsIgnoreCase(searchText)
                let isInType = serviceType.fullType.containsIgnoreCase(searchText)
                var isInDetail = false
                if let detail = serviceType.localizedDetail {
                    isInDetail = detail.containsIgnoreCase(searchText)
                }
                return isInName || isInType || isInDetail
            }
        }
    }

    var filteredCustomServiceTypes: [BonjourServiceType] {
        if searchText.isEmpty {
            customServiceTypes
        } else {
            customServiceTypes.filter { serviceType in
                let isInName = serviceType.name.containsIgnoreCase(searchText)
                let isInType = serviceType.fullType.containsIgnoreCase(searchText)
                var isInDetail = false
                if let detail = serviceType.localizedDetail {
                    isInDetail = detail.containsIgnoreCase(searchText)
                }
                return isInName || isInType || isInDetail
            }
        }
    }

    func load() {
        let sortedServiceTypes = BonjourServiceType.fetchAll().sorted { lhs, rhs -> Bool in
            lhs.name < rhs.name
        }
        let builtInServiceTypes = sortedServiceTypes.filter { $0.isBuiltIn }
        let customServiceTypes = sortedServiceTypes.filter { !$0.isBuiltIn }

        if self.builtInServiceTypes != builtInServiceTypes {
            withAnimation {
                self.builtInServiceTypes = builtInServiceTypes
            }
        }

        if self.customServiceTypes != customServiceTypes {
            withAnimation {
                self.customServiceTypes = customServiceTypes
            }
        }
    }
}
