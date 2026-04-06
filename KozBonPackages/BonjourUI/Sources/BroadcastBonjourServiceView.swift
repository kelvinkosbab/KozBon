//
//  BroadcastBonjourServiceView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourCore
import BonjourModels
import BonjourScanning

// MARK: - BroadcastBonjourServiceView

struct BroadcastBonjourServiceView: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dependencies) private var dependencies

    @Binding private var isPresented: Bool
    @Binding private var customPublishedServices: [BonjourService]
    private var serviceToUpdate: BonjourService

    @State private var serviceType: BonjourServiceType?
    @State private var serviceTypeError: String?
    @State private var port: Int?
    @State private var portError: String?
    @State private var domain: String = Constants.Network.defaultDomain
    @State private var dataRecords: [BonjourService.TxtDataRecord]
    @State private var domainError: String?
    @State private var isCreateTxtRecordViewPresented = false

    private var isCreatingBonjourService: Bool
    private let selectedTransportLayer: TransportLayer = .tcp

    init(
        isPresented: Binding<Bool>,
        customPublishedServices: Binding<[BonjourService]>
    ) {
        self._isPresented = isPresented
        self._customPublishedServices = customPublishedServices
        self.serviceToUpdate = BonjourService(
            service: .init(
                domain: Constants.Network.defaultDomain,
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
        domain = Constants.Network.defaultDomain
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
                serviceTypeSection()

                portNumberSection()

                serviceDomainSection()

                txtRecordsSection()
            }
            .contentMarginsBasedOnSizeClass()
            .navigationTitle("Broadcast service")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        isPresented = false
                    } label: {
                        Label("Cancel", systemImage: "x.circle.fill")
                    }
                    .keyboardShortcut(.cancelAction)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        doneButtonSelected()
                    } label: {
                        Label("Done", systemImage: "checkmark.circle.fill")
                    }
                    .keyboardShortcut(.defaultAction)
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

    // MARK: - Service Type Section

    private func serviceTypeSection() -> some View {
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
                    .accessibilityLabel("Error: \(serviceTypeError)")
            }
        }
        .onChange(of: [serviceType]) {
            withAnimation(reduceMotion ? nil : .default) {
                if serviceType != nil {
                    serviceTypeError = nil
                }
            }
        }
    }

    // MARK: - Port Number Section

    private func portNumberSection() -> some View {
        Section {
            TextField(
                "Service port number",
                value: $port,
                format: .number
            )
            .accessibilityLabel("Port number")
            .accessibilityHint("Enter the service port number, between \(Constants.Network.minimumPort) and \(Constants.Network.maximumPort)")
            .onSubmit {
                doneButtonSelected()
            }

        } header: {
            Text("Port Number")
        } footer: {
            if let portError {
                Text(verbatim: portError)
                    .foregroundStyle(.red)
                    .accessibilityLabel("Error: \(portError)")
            }
        }
        .onChange(of: [port]) {
            withAnimation(reduceMotion ? nil : .default) {
                if port != nil {
                    portError = nil
                }
            }
        }
    }

    // MARK: - Service Domain Section

    private func serviceDomainSection() -> some View {
        Section {
            TextField("Service domain", text: $domain)
                .accessibilityLabel("Service domain")
                .accessibilityHint("Enter the domain for the service, defaults to local")
                .onSubmit {
                    doneButtonSelected()
                }
                .disabled(false)
        } header: {
            Text("Service Domain")
        } footer: {
            if let domainError {
                Text(verbatim: domainError)
                    .foregroundStyle(.red)
                    .accessibilityLabel("Error: \(domainError)")
            }
        }
        .onChange(of: [domain]) {
            withAnimation(reduceMotion ? nil : .default) {
                if !domain.isEmpty {
                    domainError = nil
                }
            }
        }
    }

    // MARK: - TXT Records Section

    private func txtRecordsSection() -> some View {
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
                            _ = withAnimation(reduceMotion ? nil : .default) {
                                dataRecords.remove(at: indexToRemove)
                            }
                        }
                    } label: {
                        Label("Remove", systemImage: "minus.circle.fill")
                    }
                    .accessibilityLabel("Remove \(dataRecord.key)")
                    .tint(.red)
                }
            }

            Button {
                isCreateTxtRecordViewPresented = true
            } label: {
                Label("Add TXT Record", systemImage: "plus.circle.fill")
            }
            .accessibilityHint("Double tap to add a new TXT record")
        }
    }

    // MARK: - Done Action

    private func doneButtonSelected() {

        let transportLayer = selectedTransportLayer
        let domain = domain.trimmed

        withAnimation(reduceMotion ? nil : .default) {
            serviceTypeError = nil
            portError = nil
            domainError = nil
        }

        guard let serviceType else {
            withAnimation(reduceMotion ? nil : .default) {
                serviceTypeError = "Service type required"
            }
            return
        }

        guard let port else {
            withAnimation(reduceMotion ? nil : .default) {
                portError = "Port number required"
            }
            return
        }

        guard port >= Constants.Network.minimumPort else {
            withAnimation(reduceMotion ? nil : .default) {
                portError = "Port number must be at least \(Constants.Network.minimumPort)"
            }
            return
        }

        guard port <= Constants.Network.maximumPort else {
            withAnimation(reduceMotion ? nil : .default) {
                portError = "Port number must be \(Constants.Network.maximumPort) or less"
            }
            return
        }

        guard !domain.isEmpty else {
            withAnimation(reduceMotion ? nil : .default) {
                domainError = "Domain is required"
            }
            return
        }

        Task {
            do {
                let publishedService = try await dependencies.bonjourPublishManager.publish(
                    name: serviceType.name,
                    type: serviceType.type,
                    port: port,
                    domain: domain.trimmed,
                    transportLayer: transportLayer,
                    detail: serviceType.detail ?? "N/A"
                )

                publishedService.updateTXTRecords(dataRecords)

                let index = customPublishedServices.firstIndex(of: publishedService)
                if let index {
                    withAnimation(reduceMotion ? nil : .default) {
                        customPublishedServices[index] = publishedService
                    }
                } else {
                    withAnimation(reduceMotion ? nil : .default) {
                        customPublishedServices.append(publishedService)
                    }
                }

                isPresented = false

            } catch {
                serviceTypeError = "Failed to publish service: \(error.localizedDescription)"
            }
        }
    }
}
