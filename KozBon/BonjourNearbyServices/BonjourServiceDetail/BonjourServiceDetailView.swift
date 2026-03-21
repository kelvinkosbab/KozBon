//
//  BonjourServiceDetailView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - BonjourServiceDetailView

struct BonjourServiceDetailView: View {

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @StateObject private var viewModel: ViewModel

    init(service: BonjourService) {
        self.init(viewModel: ViewModel(service: service))
    }

    init(viewModel: ViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                BlueSectionItemIconTitleDetailView(
                    imageSystemName: viewModel.serviceType.imageSystemName,
                    title: viewModel.service.service.name,
                    detail: viewModel.serviceType.name
                )
                .onAppear {
                    withAnimation {
                        viewModel.isNavigationHeaderShown = false
                    }
                }
                .onDisappear {
                    withAnimation {
                        viewModel.isNavigationHeaderShown = true
                    }
                }
            }

            Section("Information") {
                TitleDetailStackView(
                    title: "Name",
                    detail: viewModel.serviceType.name
                )
                TitleDetailStackView(
                    title: "Hostname",
                    detail: viewModel.service.hostName
                )
                TitleDetailStackView(
                    title: "Full type",
                    detail: viewModel.serviceType.fullType
                )
                TitleDetailStackView(
                    title: "Type",
                    detail: viewModel.serviceType.type
                )
                TitleDetailStackView(
                    title: "Transport layer",
                    detail: viewModel.serviceType.transportLayer.string
                )
                TitleDetailStackView(
                    title: "Domain",
                    detail: viewModel.service.service.domain
                )
                if let detail = viewModel.serviceType.detail {
                    TitleDetailStackView(
                        title: "Protocol information",
                        detail: detail
                    )
                }
            }

            if !viewModel.service.addresses.isEmpty {
                Section("IP Addresses") {
                    ForEach(viewModel.service.addresses, id: \.ipPortString) { address in
                        TitleDetailStackView(
                            title: address.ipPortString,
                            detail: address.protocol.stringRepresentation
                        )
                        .accessibilityHint("Long press to copy address")
                        .contextMenu {
                            Button {
                                Clipboard.copy(address.ipPortString)
                            } label: {
                                Label("Copy Address", systemImage: "doc.on.doc")
                            }

                            Button {
                                Clipboard.copy(address.ip)
                            } label: {
                                Label("Copy IP Only", systemImage: "network")
                            }
                        }
                    }
                }
            }

            if !viewModel.service.dataRecords.isEmpty {
                Section("TXT Records") {
                    ForEach(viewModel.service.dataRecords, id: \.key) { dataRecord in
                        TitleDetailStackView(
                            title: dataRecord.key,
                            detail: dataRecord.value
                        )
                        .accessibilityHint("Long press to copy record")
                        .contextMenu {
                            Button {
                                Clipboard.copy("\(dataRecord.key)=\(dataRecord.value)")
                            } label: {
                                Label("Copy Record", systemImage: "doc.on.doc")
                            }

                            Button {
                                Clipboard.copy(dataRecord.value)
                            } label: {
                                Label("Copy Value", systemImage: "doc.on.clipboard")
                            }
                        }
                    }
                }
            }
        }
        .contentMarginsBasedOnSizeClass()
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            viewModel.service.resolve()
        }
        .toolbar {
            if viewModel.isNavigationHeaderShown {
                ToolbarItem(
                    placement: horizontalSizeClass == .compact ? .principal : .confirmationAction
                ) {
                    ServiceTypeBadge(serviceType: viewModel.serviceType, style: .basedOnSizeClass)
                }
            }
        }
    }

    // MARK: - ViewModel

    @MainActor
    final class ViewModel: ObservableObject {

        let service: BonjourService
        let serviceType: BonjourServiceType

        @Published private(set) var addresses: [InternetAddress] = []
        @Published private(set) var dataRecords: [BonjourService.TxtDataRecord] = []
        @Published var isNavigationHeaderShown = false

        init(service: BonjourService) {
            self.service = service
            serviceType = service.serviceType

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.reloadAddressesAndTxtRecords),
                name: .netServiceResolveAddressComplete,
                object: service
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.reloadAddressesAndTxtRecords),
                name: .netServiceDidPublish,
                object: service
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.reloadAddressesAndTxtRecords),
                name: .netServiceDidUnPublish,
                object: service
            )
        }

        @objc
        private func reloadAddressesAndTxtRecords() {
            withAnimation {
                self.addresses = service.addresses
                self.dataRecords = service.dataRecords
            }
        }
    }
}
