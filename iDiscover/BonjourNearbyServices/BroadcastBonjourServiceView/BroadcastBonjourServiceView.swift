//
//  BroadcastBonjourServiceView.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 6/17/24.
//  Copyright © 2024 Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - BroadcastBonjourServiceView

struct BroadcastBonjourServiceView: View {
    
    @Binding private var isPresented: Bool
    private var serviceToUpdate: BonjourService
    
    @State private var serviceType: BonjourServiceType?
    @State private var serviceTypeError: String?
    @State private var port: Int?
    @State private var portError: String?
    @State private var domain: String
    @State private var domainError: String?
    @State private var dataRecords: [BonjourService.TxtDataRecord]

    private var isCreatingBonjourService: Bool
    private let selectedTransportLayer: TransportLayer = .tcp
    private let servicePublishManger = MyBonjourPublishManager.shared
    
    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
        self.serviceToUpdate = BonjourService(
            service: .init(
                domain: "",
                type: "",
                name: "",
                port: 0
            ),
            serviceType: BonjourServiceType(
                name: "",
                type: "",
                transportLayer: .tcp
            )
        )
        isCreatingBonjourService = true
        serviceType = nil
        domain = ""
        port = nil
        dataRecords = []
    }
    
    init(
        isPresented: Binding<Bool>,
        serviceToUpdate: BonjourService
    ) {
        self._isPresented = isPresented
        self.serviceToUpdate = serviceToUpdate
        isCreatingBonjourService = false
        self.serviceType = serviceToUpdate.serviceType
        self.domain = serviceToUpdate.service.domain
        self.port = serviceToUpdate.service.port
        self.dataRecords = serviceToUpdate.dataRecords
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let serviceType, !isCreatingBonjourService {
                        BlueSectionItemIconTitleDetailView(
                            imageSystemName: serviceType.imageSystemName,
                            title: serviceType.name,
                            detail: serviceType.fullType
                        )
                    } else {
                        NavigationLink {
                            SelectServiceTypeView(selectedServiceType: $serviceType)
                        } label: {
                            BlueSectionItemIconTitleDetailView(
                                imageSystemName: serviceType?.imageSystemName ?? "",
                                title: serviceType?.name ?? "Select a service type to broadcast",
                                detail: serviceType?.fullType
                            )
                        }
                        .listRowBackground(
                            Color.kozBonBlue
                                .opacity(0.4)
                        )
                    }
                } header: {
                    Text("Service Type")
                } footer: {
                    if let serviceTypeError {
                        Text(verbatim: serviceTypeError)
                            .foregroundStyle(.red)
                    }
                }
                
                Section {
                    TextField(
                        "Service port number",
                        value: $port,
                        format: .number
                    )
                    .onSubmit {
                        doneButtonSelected()
                    }
                    
                } header: {
                    Text("Port Number")
                } footer: {
                    if let portError {
                        Text(verbatim: portError)
                            .foregroundStyle(.red)
                    }
                }
                
                Section {
                    TextField("Service domain", text: $domain)
                        .onSubmit {
                            doneButtonSelected()
                        }
                } header: {
                    Text("Service Domain")
                } footer: {
                    if let domainError {
                        Text(verbatim: domainError)
                            .foregroundStyle(.red)
                    }
                }
                
                Section("TXT Records") {
                    ForEach(dataRecords, id: \.key) { dataRecord in
                        TitleDetailStackView(
                            title: dataRecord.key,
                            detail: dataRecord.value
                        )
                    }
                    
                    Button {
                        // do something
                    } label: {
                        Label("Add TXT Record", systemImage: "plus.circle.fill")
                    }
                }
            }
            .contentMarginsBasedOnSizeClass()
            .navigationTitle("Broadcast service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .cancel) {
                        isPresented = false
                    } label: {
                        Label("Cancel", systemImage: "x.circle.fill")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        doneButtonSelected()
                    } label: {
                        Label("Done", systemImage: "checkmark.circle.fill")
                    }
                }
            }
            .onChange(of: serviceType) { newValue in
                Task { @MainActor in
                    withAnimation {
                        if serviceType != nil {
                            serviceTypeError = nil
                        }
                    }
                }
            }
            .onChange(of: port) { newValue in
                Task { @MainActor in
                    withAnimation {
                        if port != nil {
                            portError = nil
                        }
                    }
                }
            }
        }
    }
    
    private func doneButtonSelected() {
        
        let transportLayer = selectedTransportLayer
        let domain = domain.trimmed
        
        Task { @MainActor in
            withAnimation {
                serviceTypeError = nil
                domainError = nil
                portError = nil
            }
        }
        
        guard let serviceType else {
            Task { @MainActor in
                withAnimation {
                    serviceTypeError = "Service type required"
                }
            }
            return
        }
        
        guard let port else {
            Task { @MainActor in
                withAnimation {
                    portError = "Port number required"
                }
            }
            return
        }
        
        guard port > 3000 else {
            Task { @MainActor in
                withAnimation {
                    portError = "Port number must be greater than 3000"
                }
            }
            return
        }
        
        guard !domain.isEmpty else {
            Task { @MainActor in
                withAnimation {
                    portError = "Port number required"
                }
            }
            return
        }
        
        Task {
            do {
                try await servicePublishManger.publish(
                    name: serviceType.name,
                    type: serviceType.fullType,
                    port: port,
                    domain: domain,
                    transportLayer: selectedTransportLayer,
                    detail: serviceType.detail ?? "N/A"
                )
            } catch {
                serviceTypeError = "Something happened. Try again...\n\n\(error)"
            }
        }
    }
}
