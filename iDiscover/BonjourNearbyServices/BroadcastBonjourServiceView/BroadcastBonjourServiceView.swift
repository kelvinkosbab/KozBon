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
    @State private var allServiceTypes: [BonjourServiceType] = []
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
                    Picker("Service Type", selection: $serviceType) {
                        ForEach(allServiceTypes, id: \.self) { serviceType in
                            Text(serviceType.name)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .disabled(!isCreatingBonjourService)
                }
                
//                if serviceToUpdate.is
            }
            .navigationTitle("Broadcast service")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                allServiceTypes = BonjourServiceType.fetchAll().sorted { lhs, rhs in
                    lhs.name < rhs.name
                }
            }
        }
    }
}
