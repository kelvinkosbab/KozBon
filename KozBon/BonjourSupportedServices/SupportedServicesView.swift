//
//  SupportedServicesView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import CoreUI
import SwiftUI

// MARK: - SupportedServicesView

struct SupportedServicesView: View {

    @StateObject private var viewModel = ViewModel()

    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    #endif

    var body: some View {
        NavigationSplitView {
            List(selection: $viewModel.selectedServiceType) {
                if !viewModel.filteredCustomServiceTypes.isEmpty {
                    Section("Custom Service Types") {
                        ForEach(viewModel.filteredCustomServiceTypes, id: \.fullType) { serviceType in
                            NavigationLink(value: serviceType) {
                                TitleDetailStackView(
                                    title: serviceType.name,
                                    detail: serviceType.fullType
                                ) {
                                    ServiceTypeBadge(serviceType: serviceType, style: .iconOnly)
                                }
                            }
                            .draggable(serviceType.fullType)
                            .accessibilityHint("View details for \(serviceType.name)")
                            .contextMenu {
                                serviceTypeContextMenu(serviceType: serviceType)
                            }
                        }
                    }
                }

                if !viewModel.filteredBuiltInServiceTypes.isEmpty {
                    Section("Built-in Service Types") {
                        ForEach(viewModel.filteredBuiltInServiceTypes, id: \.fullType) { serviceType in
                            NavigationLink(value: serviceType) {
                                TitleDetailStackView(
                                    title: serviceType.name,
                                    detail: serviceType.fullType
                                ) {
                                    ServiceTypeBadge(serviceType: serviceType, style: .iconOnly)
                                }
                            }
                            .draggable(serviceType.fullType)
                            .accessibilityHint("View details for \(serviceType.name)")
                            .contextMenu {
                                serviceTypeContextMenu(serviceType: serviceType)
                            }
                        }
                    }
                }
            }
            .contentMarginsBasedOnSizeClass()
            .navigationTitle("Supported services")
            .searchable(text: $viewModel.searchText, prompt: "Search for ...")
            .toolbar {
                ToolbarItem {
                    self.renderTrailingToolbarItems()
                }
            }
            #if os(visionOS)
            .ornament(attachmentAnchor: .scene(.bottom)) {
                HStack(spacing: 16) {
                    Button {
                        viewModel.isCreateCustomServiceTypePresented = true
                    } label: {
                        Label("Create Service Type", systemImage: "badge.plus.radiowaves.forward")
                    }
                }
                .padding(12)
                .glassBackgroundEffect()
            }
            #endif
        } detail: {
            if let selectedServiceType = viewModel.selectedServiceType {
                SupportedServiceDetailView(serviceType: selectedServiceType)
            } else {
                ContentUnavailableView(
                    "Select a Service Type",
                    systemImage: "list.dash",
                    description: Text("Choose a service type to view its details.")
                )
            }
        }
        .task {
            viewModel.load()
        }
        .sheet(isPresented: $viewModel.isCreateCustomServiceTypePresented) {
            CreateOrUpdateBonjourServiceTypeView(isPresented: $viewModel.isCreateCustomServiceTypePresented)
        }
        .focusedSceneValue(\.isCreateServiceTypePresented, $viewModel.isCreateCustomServiceTypePresented)
    }

    @ViewBuilder
    private func serviceTypeContextMenu(serviceType: BonjourServiceType) -> some View {
        Button {
            Clipboard.copy(serviceType.fullType)
        } label: {
            Label("Copy Full Type", systemImage: "doc.on.doc")
        }

        Button {
            Clipboard.copy(serviceType.name)
        } label: {
            Label("Copy Name", systemImage: "doc.on.clipboard")
        }

        if let detail = serviceType.detail {
            Button {
                Clipboard.copy(detail)
            } label: {
                Label("Copy Details", systemImage: "info.circle")
            }
        }

        #if os(macOS)
        Divider()

        Button {
            openWindow(value: serviceType)
        } label: {
            Label("Open in New Window", systemImage: "macwindow.badge.plus")
        }
        #endif
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
        .accessibilityLabel("Create")
        .accessibilityHint("Create a custom service type")
    }

    // MARK: - ViewModel

    @MainActor
    final class ViewModel: ObservableObject {

        @Published private var builtInServiceTypes: [BonjourServiceType] = []
        @Published private var customServiceTypes: [BonjourServiceType] = []

        @Published var selectedServiceType: BonjourServiceType?
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
