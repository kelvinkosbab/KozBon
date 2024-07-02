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

    @StateObject var viewModel = BonjourServicesViewModel()

    var body: some View {
        List {
            if viewModel.sortedPublishedServices.count > 0 {
                Section {
                    forEach(services: viewModel.sortedPublishedServices)
                } header: {
                    Text(verbatim: "Published")
                        .font(.system(.caption))
                }
            }
            
            if viewModel.sortedActiveServices.count > 0 {
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
            if self.viewModel.sortedActiveServices.count == 0 {
                EmptyStateOverlayView(
                    image: nil,
                    title: self.viewModel.noActiveServicesString
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                BonjourServiceListSortMenu(sortType: self.$viewModel.sortType)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
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
        .sheet(isPresented: $viewModel.isBroadcastBonjourServicePresented) {
            NavigationStack {
                BroadcastBonjourServiceView(
                    isPresented: $viewModel.isBroadcastBonjourServicePresented,
                    customPublishedServices: $viewModel.customPublishedServices
                )
            }
        }
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
                    Image(systemName: service.serviceType.imageSystemName)
                        .font(.system(.body).bold())
                }
            }
        }
    }
}
