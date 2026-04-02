//
//  BonjourScanForServicesView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import CoreUI

// MARK: - BonjourScanForServicesView

struct BonjourScanForServicesView: View {

    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel: BonjourServicesViewModel

    @MainActor
    init(scanner: (any BonjourServiceScannerProtocol)? = nil) {
        _viewModel = State(initialValue: BonjourServicesViewModel(
            serviceScanner: scanner ?? BonjourServiceScanner.shared
        ))
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $viewModel.selectedService) {
                if !viewModel.sortedPublishedServices.isEmpty {
                    Section {
                        forEach(services: viewModel.sortedPublishedServices)
                    } header: {
                        Text(verbatim: "Published")
                            .font(.caption)
                    }
                }

                if !viewModel.sortedActiveServices.isEmpty {
                    Section {
                        forEach(services: viewModel.sortedActiveServices)
                    } header: {
                        Text(verbatim: "Nearby " + (viewModel.sortType?.hostOrServiceTitle ?? "Services"))
                            .font(.caption)
                    }
                }
            }
            .contentMarginsBasedOnSizeClass()
            .overlay {
                if self.viewModel.sortedActiveServices.isEmpty {
                    EmptyStateOverlayView(
                        image: nil,
                        title: self.viewModel.noActiveServicesString
                    )
                }
            }
            .toolbar {
                ToolbarItem {
                    BonjourServiceListSortMenu(sortType: self.$viewModel.sortType)
                }

                ToolbarItem {
                    Menu {
                        Button {
                            viewModel.isBroadcastBonjourServicePresented = true
                        } label: {
                            Label {
                                Text("Broadcast Bonjour Service")
                            } icon: {
                                Image(systemName: "antenna.radiowaves.left.and.right")
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
                    .accessibilityHint("Create or broadcast a new service")
                }
            }
            #if os(visionOS)
            .ornament(attachmentAnchor: .scene(.bottom)) {
                HStack(spacing: 16) {
                    BonjourServiceListSortMenu(sortType: self.$viewModel.sortType)
                    Button {
                        viewModel.isBroadcastBonjourServicePresented = true
                    } label: {
                        Label("Broadcast", systemImage: "antenna.radiowaves.left.and.right")
                    }
                }
                .padding(12)
                .glassBackgroundEffect()
            }
            #endif
            .navigationTitle("Nearby services")
            .refreshable {
                guard !self.viewModel.serviceScanner.isProcessing else {
                    return
                }

                self.viewModel.serviceScanner.startScan()
            }
        } detail: {
            if let selectedService = viewModel.selectedService {
                BonjourServiceDetailView(service: selectedService)
            } else {
                ContentUnavailableView(
                    "Select a Service",
                    systemImage: "antenna.radiowaves.left.and.right",
                    description: Text("Choose a nearby service to view its details.")
                )
            }
        }
        .task {
            if viewModel.isInitialLoad {
                viewModel.load()
            }
        }
        .onDisappear {
            viewModel.serviceScanner.stopScan()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                if viewModel.shouldRefreshOnForeground() {
                    viewModel.load()
                }
            case .background:
                viewModel.serviceScanner.stopScan()
            default:
                break
            }
        }
        .alert(
            "Scan Error",
            isPresented: Binding(
                get: { viewModel.scanError != nil },
                set: { if !$0 { viewModel.scanError = nil } }
            )
        ) {
            Button("OK") { viewModel.scanError = nil }
        } message: {
            Text(viewModel.scanError ?? "")
        }
        .sheet(isPresented: $viewModel.isBroadcastBonjourServicePresented) {
            NavigationStack {
                BroadcastBonjourServiceView(
                    isPresented: $viewModel.isBroadcastBonjourServicePresented,
                    customPublishedServices: $viewModel.customPublishedServices
                )
            }
        }
        .focusedSceneValue(\.isBroadcastServicePresented, $viewModel.isBroadcastBonjourServicePresented)
    }

    @ViewBuilder
    private func forEach(services: [BonjourService]) -> some View {
        ForEach(services) { service in
            NavigationLink(value: service) {
                TitleDetailStackView(
                    title: service.service.name,
                    detail: service.serviceType.name
                ) {
                    ServiceTypeBadge(serviceType: service.serviceType, style: .iconOnly)
                }
            }
            .draggable(service.hostName)
            .accessibilityHint("View details for \(service.service.name)")
            .contextMenu {
                Button {
                    Clipboard.copy(service.hostName)
                } label: {
                    Label("Copy Hostname", systemImage: "doc.on.doc")
                }

                if let firstAddress = service.addresses.first {
                    Button {
                        Clipboard.copy(firstAddress.ipPortString)
                    } label: {
                        Label("Copy IP Address", systemImage: "network")
                    }
                }

                Button {
                    Clipboard.copy(service.serviceType.fullType)
                } label: {
                    Label("Copy Service Type", systemImage: "doc.on.clipboard")
                }
            }
        }
    }

}
