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

    /// Active category filter (Smart Home, Apple Devices, etc.). When
    /// non-nil, the visible list is narrowed to types belonging to
    /// the chosen category. The search filter still applies on top.
    /// `nil` means "show everything", matching the Discover tab's
    /// "no filter" baseline.
    var filterCategory: BonjourServiceCategory?

    var isCreateCustomServiceTypePresented = false {
        didSet {
            if !isCreateCustomServiceTypePresented {
                self.load()
            }
        }
    }

    var filteredBuiltInServiceTypes: [BonjourServiceType] {
        applyCategoryFilter(filterServiceTypes(builtInServiceTypes))
    }

    var filteredCustomServiceTypes: [BonjourServiceType] {
        applyCategoryFilter(filterServiceTypes(customServiceTypes))
    }

    /// Whether *both* visible lists are empty after applying both the
    /// search filter and the category filter. The view uses this to
    /// distinguish "no results for this filter" (show a hint) from
    /// "no results because the user typed a typo" — the empty-state
    /// message differs in each case.
    var isFilteredResultEmpty: Bool {
        filteredBuiltInServiceTypes.isEmpty && filteredCustomServiceTypes.isEmpty
    }

    private func filterServiceTypes(_ types: [BonjourServiceType]) -> [BonjourServiceType] {
        guard !searchText.isEmpty else { return types }
        return types.filter { serviceType in
            serviceType.name.containsIgnoreCase(searchText) ||
            serviceType.fullType.containsIgnoreCase(searchText) ||
            (serviceType.localizedDetail?.containsIgnoreCase(searchText) ?? false)
        }
    }

    private func applyCategoryFilter(_ types: [BonjourServiceType]) -> [BonjourServiceType] {
        guard let category = filterCategory else { return types }
        return types.filter(category.matches)
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
