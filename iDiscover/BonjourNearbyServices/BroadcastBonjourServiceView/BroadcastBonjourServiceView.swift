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
                Section(header: Text("Service Type")) {
                    if let serviceType {
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
                }
            }
            .contentMarginsBasedOnSizeClass()
            .navigationTitle("Broadcast service")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
