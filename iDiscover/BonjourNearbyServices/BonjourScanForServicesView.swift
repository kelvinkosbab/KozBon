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
            Section {
                activeServices
            } header: {
                HStack {
                    Text(verbatim: (viewModel.sortType?.hostOrServiceTitle ?? "Bonjour").uppercased())
                        .font(.system(.caption))

                    Spacer()

                    BonjourServiceListSortMenu(sortType: self.$viewModel.sortType)
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
                self.renderTrailingToolbarItems()
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
                BroadcastBonjourServiceView(isPresented: $viewModel.isBroadcastBonjourServicePresented)
            }
        }
    }

    @ViewBuilder private var activeServices: some View {
        ForEach(viewModel.sortedActiveServices) { service in
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

    private func renderTrailingToolbarItems() -> some View {
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
