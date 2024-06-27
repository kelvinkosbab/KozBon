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
    @State private var domain: String
    @State private var domainError: String?
    @State private var type: String
    @State private var typeError: String?
    @State private var name: String
    @State private var nameError: String?
    @State private var port: Int
    @State private var portError: String?

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
                port: 0),
            serviceType: BonjourServiceType(
                name: "",
                type: "",
                transportLayer: .tcp
            )
        )
        isCreatingBonjourService = true
        serviceType = nil
        domain = ""
        type = ""
        name = ""
        port = 0
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
        self.type = serviceToUpdate.service.type
        self.name = serviceToUpdate.service.name
        self.port = serviceToUpdate.service.port
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
                if serviceType != nil {
                    serviceTypeError = nil
                }
            }
        }
    }
    
    private func doneButtonSelected() {
        
        let transportLayer = selectedTransportLayer
        let domain = domain.trimmed
        let type = type.trimmed
        let name = name.trimmed
        
        Task { @MainActor in
            withAnimation {
                serviceTypeError = nil
                domainError = nil
                typeError = nil
                nameError = nil
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
    }
}
