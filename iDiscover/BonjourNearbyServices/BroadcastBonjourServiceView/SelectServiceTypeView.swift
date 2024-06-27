//
//  SelectServiceTypeView.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 6/26/24.
//  Copyright © 2024 Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - SelectServiceTypeView

struct SelectServiceTypeView: View {
    
    @Binding var selectedServiceType: BonjourServiceType?
    @StateObject private var viewModel = ViewModel()
    
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
                                    .font(.system(.body).bold())
                                    .foregroundStyle(selectedServiceType == serviceType ? Color.kozBonBlue : .secondary)
                            }
                        }
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
                                    .font(.system(.body).bold())
                                    .foregroundStyle(selectedServiceType == serviceType ? Color.kozBonBlue : .secondary)
                            }
                        }
                    }
                }
            }
        }
        .contentMarginsBasedOnSizeClass()
        .navigationTitle("Supported services")
        .task {
            await viewModel.load()
        }
        .searchable(
            text: $viewModel.searchText,
            prompt: "Search for ..."
        )
    }
    
    // MARK: - ViewModel

    class ViewModel: ObservableObject {
        
        @MainActor @Published private var builtInServiceTypes: [BonjourServiceType] = []
        @MainActor @Published private var customServiceTypes: [BonjourServiceType] = []
        
        @MainActor @Published var searchText: String = ""
        
        @MainActor var filteredBuiltInServiceTypes: [BonjourServiceType] {
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

        @MainActor var filteredCustomServiceTypes: [BonjourServiceType] {
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
        
        func load() async {
            let sortedServiceTypes = BonjourServiceType.fetchAll().sorted { lhs, rhs -> Bool in
                lhs.name < rhs.name
            }
            let builtInServiceTypes = sortedServiceTypes.filter { $0.isBuiltIn }
            let customServiceTypes = sortedServiceTypes.filter { !$0.isBuiltIn }

            await MainActor.run {
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
}
