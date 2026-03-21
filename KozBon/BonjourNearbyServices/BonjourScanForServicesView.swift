//
//  BonjourScanForServicesView.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 8/20/23.
//  Copyright © 2023 Kozinga. All rights reserved.
//

import SwiftUI
import CoreUI

// MARK: - BonjourScanForServicesView

struct BonjourScanForServicesView: View {

    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel: BonjourServicesViewModel

    @MainActor
    init(scanner: (any BonjourServiceScannerProtocol)? = nil) {
        _viewModel = StateObject(wrappedValue: BonjourServicesViewModel(
            serviceScanner: scanner ?? BonjourServiceScanner.shared
        ))
    }

    var body: some View {
        List {
            if !viewModel.sortedPublishedServices.isEmpty {
                Section {
                    forEach(services: viewModel.sortedPublishedServices)
                } header: {
                    Text(verbatim: "Published")
                        .font(.system(.caption))
                }
            }

            if !viewModel.sortedActiveServices.isEmpty {
                Section {
                    forEach(services: viewModel.sortedActiveServices)
                } header: {
                    Text(verbatim: "Nearby " + (viewModel.sortType?.hostOrServiceTitle ?? "Services"))
                        .font(.system(.caption))
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
        .navigationTitle("Nearby services")
        .refreshable {
            guard !self.viewModel.serviceScanner.isProcessing else {
                return
            }

            self.viewModel.serviceScanner.startScan()
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
            NavigationLink {
                BonjourServiceDetailView(service: service)
            } label: {
                TitleDetailStackView(
                    title: service.service.name,
                    detail: service.serviceType.name
                ) {
                    ServiceTypeBadge(serviceType: service.serviceType, style: .iconOnly)
                }
            }
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
