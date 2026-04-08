//
//  SupportedServicesViewModel.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourModels
import BonjourLocalization

// MARK: - SupportedServicesViewModel

/// View model for ``SupportedServicesView``, managing the list of built-in and custom
/// Bonjour service types with search filtering.
@MainActor
@Observable
final class SupportedServicesViewModel {

    private var builtInServiceTypes: [BonjourServiceType] = []
    private var customServiceTypes: [BonjourServiceType] = []

    var selectedServiceType: BonjourServiceType?
    var searchText: String = ""
    var isCreateCustomServiceTypePresented = false {
        didSet {
            if !isCreateCustomServiceTypePresented {
                self.load()
            }
        }
    }

    var filteredBuiltInServiceTypes: [BonjourServiceType] {
        filterServiceTypes(builtInServiceTypes)
    }

    var filteredCustomServiceTypes: [BonjourServiceType] {
        filterServiceTypes(customServiceTypes)
    }

    private func filterServiceTypes(_ types: [BonjourServiceType]) -> [BonjourServiceType] {
        guard !searchText.isEmpty else { return types }
        return types.filter { serviceType in
            serviceType.name.containsIgnoreCase(searchText) ||
            serviceType.fullType.containsIgnoreCase(searchText) ||
            (serviceType.localizedDetail?.containsIgnoreCase(searchText) ?? false)
        }
    }

    let createButtonString = String(localized: Strings.Buttons.create)

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
