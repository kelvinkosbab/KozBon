//
//  BonjourServiceDetailView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourCore
import BonjourModels

// MARK: - BonjourServiceDetailView

public struct BonjourServiceDetailView: View {

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var viewModel: ViewModel

    public init(service: BonjourService, isPublished: Bool = false) {
        self._viewModel = State(initialValue: ViewModel(service: service, isPublished: isPublished))
    }

    init(viewModel: ViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        List {
            Section {
                BlueSectionItemIconTitleDetailView(
                    imageSystemName: viewModel.serviceType.imageSystemName,
                    title: viewModel.service.service.name,
                    detail: viewModel.serviceType.name
                )
                .onAppear {
                    withAnimation(reduceMotion ? nil : .default) {
                        viewModel.isNavigationHeaderShown = false
                    }
                }
                .onDisappear {
                    withAnimation(reduceMotion ? nil : .default) {
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
                        .draggable(address.ipPortString)
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

            txtRecordsSection()
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
        .sheet(isPresented: Binding(
            get: { viewModel.isCreateTxtRecordPresented },
            set: { viewModel.isCreateTxtRecordPresented = $0 }
        ), onDismiss: {
            viewModel.didFinishEditingTxtRecords()
        }) {
            TxtRecordEditSheet(viewModel: viewModel)
        }
    }

    // MARK: - TXT Records Section

    @ViewBuilder
    private func txtRecordsSection() -> some View {
        if viewModel.isPublished {
            Section("TXT Records") {
                ForEach(viewModel.dataRecords, id: \.key) { dataRecord in
                    Button {
                        viewModel.txtRecordToEdit = dataRecord
                        viewModel.isCreateTxtRecordPresented = true
                    } label: {
                        TitleDetailStackView(
                            title: dataRecord.key,
                            detail: dataRecord.value
                        )
                    }
                    .draggable("\(dataRecord.key)=\(dataRecord.value)")
                    .accessibilityHint("Double tap to edit this record")
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
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            viewModel.deleteTxtRecord(dataRecord)
                        } label: {
                            Label("Remove", systemImage: "minus.circle.fill")
                        }
                        .accessibilityLabel("Remove \(dataRecord.key)")
                        .tint(.red)
                    }
                }

                Button {
                    viewModel.txtRecordToEdit = nil
                    viewModel.isCreateTxtRecordPresented = true
                } label: {
                    Label("Add TXT Record", systemImage: "plus.circle.fill")
                }
                .accessibilityHint("Double tap to add a new TXT record")
            }
        } else if !viewModel.dataRecords.isEmpty {
            Section("TXT Records") {
                ForEach(viewModel.dataRecords, id: \.key) { dataRecord in
                    TitleDetailStackView(
                        title: dataRecord.key,
                        detail: dataRecord.value
                    )
                    .draggable("\(dataRecord.key)=\(dataRecord.value)")
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

    // MARK: - TXT Record Edit Sheet

    private struct TxtRecordEditSheet: View {
        @Bindable var viewModel: ViewModel

        var body: some View {
            if let record = viewModel.txtRecordToEdit {
                CreateTxtRecordView(
                    isPresented: $viewModel.isCreateTxtRecordPresented,
                    txtDataRecords: $viewModel.dataRecords,
                    txtRecordToUpdate: record
                )
            } else {
                CreateTxtRecordView(
                    isPresented: $viewModel.isCreateTxtRecordPresented,
                    txtDataRecords: $viewModel.dataRecords
                )
            }
        }
    }

    // MARK: - ViewModel

    @MainActor
    @Observable
    final class ViewModel: MyNetServiceDelegate {

        let service: BonjourService
        let serviceType: BonjourServiceType
        let isPublished: Bool

        private(set) var addresses: [InternetAddress] = []
        var dataRecords: [BonjourService.TxtDataRecord] = []
        var isNavigationHeaderShown = false
        var isCreateTxtRecordPresented = false
        var txtRecordToEdit: BonjourService.TxtDataRecord?

        init(service: BonjourService, isPublished: Bool = false) {
            self.service = service
            self.serviceType = service.serviceType
            self.isPublished = isPublished
            self.dataRecords = service.dataRecords
            service.delegate = self
        }

        // MARK: - TXT Record Editing

        func deleteTxtRecord(_ record: BonjourService.TxtDataRecord) {
            dataRecords.removeAll { $0.key == record.key }
            service.updateTXTRecords(dataRecords)
        }

        func didFinishEditingTxtRecords() {
            service.updateTXTRecords(dataRecords)
        }

        // MARK: - MyNetServiceDelegate

        func serviceDidResolveAddress(_ service: BonjourService) {
            withAnimation {
                self.addresses = service.addresses
                self.dataRecords = service.dataRecords
            }
        }
    }
}
