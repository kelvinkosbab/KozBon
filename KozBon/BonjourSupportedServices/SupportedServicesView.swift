//
//  SupportedServicesView.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 6/18/24.
//  Copyright © 2024 Kozinga. All rights reserved.
//

import CoreUI
import SwiftUI

// MARK: - SupportedServicesView

struct SupportedServicesView: View {

    @StateObject private var viewModel = ViewModel()

    var body: some View {
        List {
            if !viewModel.filteredCustomServiceTypes.isEmpty {
                Section("Custom Service Types") {
                    ForEach(viewModel.filteredCustomServiceTypes, id: \.fullType) { serviceType in
                        NavigationLink {
                            SupportedServiceDetailView(serviceType: serviceType)
                        } label: {
                            TitleDetailStackView(
                                title: serviceType.name,
                                detail: serviceType.fullType
                            ) {
                                ServiceTypeBadge(serviceType: serviceType, style: .iconOnly)
                            }
                        }
                    }
                }
            }

            if !viewModel.filteredBuiltInServiceTypes.isEmpty {
                Section("Built-in Service Types") {
                    ForEach(viewModel.filteredBuiltInServiceTypes, id: \.fullType) { serviceType in
                        NavigationLink {
                            SupportedServiceDetailView(serviceType: serviceType)
                        } label: {
                            TitleDetailStackView(
                                title: serviceType.name,
                                detail: serviceType.fullType
                            ) {
                                ServiceTypeBadge(serviceType: serviceType, style: .iconOnly)
                            }
                        }
                    }
                }
            }
        }
        .contentMarginsBasedOnSizeClass()
        .navigationTitle("Supported services")
        .task {
            viewModel.load()
        }
        .searchable(text: $viewModel.searchText, prompt: "Search for ...")
        .sheet(isPresented: $viewModel.isCreateCustomServiceTypePresented) {
            CreateOrUpdateBonjourServiceTypeView(isPresented: $viewModel.isCreateCustomServiceTypePresented)
        }
        .toolbar {
            ToolbarItem {
                self.renderTrailingToolbarItems()
            }
        }
    }

    private func renderTrailingToolbarItems() -> some View {
        Menu {
            Button {
                viewModel.isCreateCustomServiceTypePresented = true
            } label: {
                Label {
                    Text("Create Custom Service Type")
                } icon: {
                    Image(systemName: "badge.plus.radiowaves.forward")
                        .renderingMode(.template)
                        .foregroundColor(.kozBonBlue)
                }
            }
        } label: {
            Label {
                Text(self.viewModel.createButtonString)
            } icon: {
                Image.plusCircleFill
                    .renderingMode(.template)
                    .foregroundColor(.kozBonBlue)
            }
        }
    }

    // MARK: - ViewModel

    @MainActor
    final class ViewModel: ObservableObject {

        @Published private var builtInServiceTypes: [BonjourServiceType] = []
        @Published private var customServiceTypes: [BonjourServiceType] = []

        @Published var searchText: String = ""
        @Published var isCreateCustomServiceTypePresented = false {
            didSet {
                if !isCreateCustomServiceTypePresented {
                    self.load()
                }
            }
        }

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

        let createButtonString = NSLocalizedString(
            "Create",
            comment: "Create service button string"
        )

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
