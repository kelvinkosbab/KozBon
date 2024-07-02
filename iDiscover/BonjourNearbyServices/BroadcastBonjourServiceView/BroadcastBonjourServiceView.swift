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
    @Binding private var customPublishedServices: [BonjourService]
    private var serviceToUpdate: BonjourService

    @State private var serviceType: BonjourServiceType?
    @State private var serviceTypeError: String?
    @State private var port: Int?
    @State private var portError: String?
    @State private var domain: String = "local."
    @State private var dataRecords: [BonjourService.TxtDataRecord]
    @State private var isCreateTxtRecordViewPresented = false

    private var isCreatingBonjourService: Bool
    private let selectedTransportLayer: TransportLayer = .tcp
    private let servicePublishManger = MyBonjourPublishManager.shared

    init(
        isPresented: Binding<Bool>,
        customPublishedServices: Binding<[BonjourService]>
    ) {
        self._isPresented = isPresented
        self._customPublishedServices = customPublishedServices
        self.serviceToUpdate = BonjourService(
            service: .init(
                domain: "local.",
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
        domain = "local."
        port = nil
        dataRecords = []
    }

    init(
        isPresented: Binding<Bool>,
        serviceToUpdate: BonjourService,
        customPublishedServices: Binding<[BonjourService]>
    ) {
        self._isPresented = isPresented
        self._customPublishedServices = customPublishedServices
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
                    if !isCreatingBonjourService, let serviceType {
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
                                imageSystemName: serviceType?.imageSystemName,
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

                Section("Service Domain") {
                    TextField("Service domain", text: $domain)
                        .onSubmit {
                            doneButtonSelected()
                        }
                        .disabled(false)
                }

                Section("TXT Records") {
                    ForEach(dataRecords, id: \.key) { dataRecord in
                        TitleDetailStackView(
                            title: dataRecord.key,
                            detail: dataRecord.value
                        )
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                let indexToRemove = dataRecords.firstIndex { record in
                                    record.key == dataRecord.key
                                }
                                if let indexToRemove {
                                    Task { @MainActor in
                                        withAnimation {
                                            dataRecords.remove(at: indexToRemove)
                                        }
                                    }
                                }
                            } label: {
                                Label("Remove", systemImage: "minus.circle.fill")
                            }
                            .tint(.red)
                        }
                    }

                    Button {
                        isCreateTxtRecordViewPresented = true
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
            .onChange(of: serviceType) { _ in
                Task { @MainActor in
                    withAnimation {
                        if serviceType != nil {
                            serviceTypeError = nil
                        }
                    }
                }
            }
            .onChange(of: port) { _ in
                Task { @MainActor in
                    withAnimation {
                        if port != nil {
                            portError = nil
                        }
                    }
                }
            }
            .sheet(isPresented: $isCreateTxtRecordViewPresented) {
                CreateTxtRecordView(
                    isPresented: $isCreateTxtRecordViewPresented,
                    txtDataRecords: $dataRecords
                )
            }
        }
    }

    private func doneButtonSelected() {

        let transportLayer = selectedTransportLayer
        let domain = domain.trimmed

        Task { @MainActor in
            withAnimation {
                serviceTypeError = nil
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

        Task {
            do {
                let publishedService = try await servicePublishManger.publish(
                    name: serviceType.name,
                    type: serviceType.type,
                    port: port,
                    domain: domain.trimmed,
                    transportLayer: transportLayer,
                    detail: serviceType.detail ?? "N/A"
                )

                var txtRecords: [String: Data] = [:]
                for record in dataRecords {
                    txtRecords[record.key] = record.value.data(using: String.Encoding.utf8)
                }
                let txtRecordData = NetService.data(fromTXTRecord: txtRecords)
                _ = publishedService.service.setTXTRecord(txtRecordData)
                
                let index = customPublishedServices.firstIndex(of: publishedService)
                await MainActor.run {
                    if let index {
                        withAnimation {
                            customPublishedServices[index] = publishedService
                        }
                    } else {
                        withAnimation {
                            customPublishedServices.append(publishedService)
                        }
                    }
                }

                isPresented = false

            } catch {
                serviceTypeError = "Something happened. Try again..."
            }
        }
    }
}
