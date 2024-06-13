//
//  BonjourServiceDetailView.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 6/13/24.
//  Copyright © 2024 Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - BonjourServiceDetailView

struct BonjourServiceDetailView: View {
    
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
                Group {
                    if let serviceTypeSystemName = viewModel.serviceType.imageSystemName {
                        Label(viewModel.service.service.name, systemImage: serviceTypeSystemName)
                    } else {
                        Text(verbatim: viewModel.service.service.name)
                    }
                }
                .font(.system(.headline).bold())
                .foregroundStyle(.white)
                .padding()
                .padding(.horizontal)
                .background(.secondary)
                .clipShape(.capsule)
                .listRowBackground(Color(.clear))
                .frame(maxWidth: .infinity)
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
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.service.resolve()
        }
    }
    
    // MARK: - ViewModel
    
    class ViewModel: ObservableObject {
        
        let service: BonjourService
        let serviceType: BonjourServiceType
        
        @MainActor @Published private(set) var addresses: [InternetAddress] = []
        @MainActor @Published private(set) var dataRecords: [BonjourService.MyDataRecord] = []
        
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
            update(addresses: service.addresses, dataRecords: service.dataRecords)
        }
        
        private func update(addresses: [InternetAddress], dataRecords: [BonjourService.MyDataRecord]) {
            Task { @MainActor in
                withAnimation {
                    self.addresses = addresses
                    self.dataRecords = dataRecords
                }
            }
        }
    }
}
