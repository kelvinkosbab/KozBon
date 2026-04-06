//
//  SelectServiceTypeView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourModels

// MARK: - SelectServiceTypeView

struct SelectServiceTypeView: View {

    @Binding var selectedServiceType: BonjourServiceType?
    @State private var viewModel = ViewModel()

    init(selectedServiceType: Binding<BonjourServiceType?>) {
        self._selectedServiceType = selectedServiceType
    }

    var body: some View {
        List {
            if let selectedServiceType {
                Section {
                    BlueSectionItemIconTitleDetailView(
                        imageSystemName: selectedServiceType.imageSystemName,
                        title: selectedServiceType.name,
                        detail: selectedServiceType.fullType
                    )
                }
            }

            if !viewModel.filteredCustomServiceTypes.isEmpty {
                Section("Custom Service Types") {
                    ForEach(viewModel.filteredCustomServiceTypes, id: \.fullType) { serviceType in
                        Button {
                            Task { @MainActor in
                                withAnimation {
                                    selectedServiceType = serviceType
                                }
                            }
                        } label: {
                            TitleDetailStackView(
                                title: serviceType.name,
                                detail: serviceType.fullType
                            ) {
                                Image(systemName: selectedServiceType == serviceType ? "checkmark.circle.fill" : "circle")
                                    .font(.body).bold()
                                    .foregroundStyle(selectedServiceType == serviceType ? Color.kozBonBlue : .secondary)
                                    .accessibilityHidden(true)
                            }
                        }
                        .accessibilityLabel(serviceType.name)
                        .accessibilityValue(selectedServiceType == serviceType ? "Selected" : "Not selected")
                        .accessibilityHint("Double tap to select this service type")
                    }
                }
            }

            if !viewModel.filteredBuiltInServiceTypes.isEmpty {
                Section("Built-in Service Types") {
                    ForEach(viewModel.filteredBuiltInServiceTypes, id: \.fullType) { serviceType in
                        Button {
                            Task { @MainActor in
                                withAnimation {
                                    selectedServiceType = serviceType
                                }
                            }
                        } label: {
                            TitleDetailStackView(
                                title: serviceType.name,
                                detail: serviceType.fullType
                            ) {
                                Image(systemName: selectedServiceType == serviceType ? "checkmark.circle.fill" : "circle")
                                    .font(.body).bold()
                                    .foregroundStyle(selectedServiceType == serviceType ? Color.kozBonBlue : .secondary)
                                    .accessibilityHidden(true)
                            }
                        }
                        .accessibilityLabel(serviceType.name)
                        .accessibilityValue(selectedServiceType == serviceType ? "Selected" : "Not selected")
                        .accessibilityHint("Double tap to select this service type")
                    }
                }
            }
        }
        .contentMarginsBasedOnSizeClass()
        .navigationTitle("Supported services")
        .task {
            viewModel.load()
        }
        .searchable(
            text: $viewModel.searchText,
            prompt: "Search for ..."
        )
    }

    // MARK: - ViewModel

    @MainActor
    @Observable
    final class ViewModel {

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
                    if let detail = serviceType.detail {
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
                    if let detail = serviceType.detail {
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
}
