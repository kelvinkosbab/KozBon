//
//  BonjourServiceDetailView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourCore
import BonjourLocalization
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

            Section(String(localized: Strings.Sections.information)) {
                TitleDetailStackView(
                    title: String(localized: Strings.DetailRows.name),
                    detail: viewModel.serviceType.name
                )
                TitleDetailStackView(
                    title: String(localized: Strings.DetailRows.hostname),
                    detail: viewModel.service.hostName
                )
                TitleDetailStackView(
                    title: String(localized: Strings.DetailRows.fullType),
                    detail: viewModel.serviceType.fullType
                )
                TitleDetailStackView(
                    title: String(localized: Strings.DetailRows.type),
                    detail: viewModel.serviceType.type
                )
                TitleDetailStackView(
                    title: String(localized: Strings.DetailRows.transportLayer),
                    detail: viewModel.serviceType.transportLayer.string
                )
                TitleDetailStackView(
                    title: String(localized: Strings.DetailRows.domain),
                    detail: viewModel.service.service.domain
                )
                if let detail = viewModel.serviceType.localizedDetail {
                    TitleDetailStackView(
                        title: String(localized: Strings.DetailRows.protocolInformation),
                        detail: detail
                    )
                }
            }

            if !viewModel.service.addresses.isEmpty {
                Section(String(localized: Strings.Sections.ipAddresses)) {
                    ForEach(viewModel.service.addresses, id: \.ipPortString) { address in
                        TitleDetailStackView(
                            title: address.ipPortString,
                            detail: address.protocol.stringRepresentation
                        )
                        .draggable(address.ipPortString)
                        .accessibilityHint(String(localized: Strings.Accessibility.longPressCopyAddress))
                        .contextMenu {
                            Button {
                                Clipboard.copy(address.ipPortString)
                            } label: {
                                Label(String(localized: Strings.Actions.copyAddress), systemImage: "doc.on.doc")
                            }

                            Button {
                                Clipboard.copy(address.ip)
                            } label: {
                                Label(String(localized: Strings.Actions.copyIpOnly), systemImage: "network")
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
            Section(String(localized: Strings.Sections.txtRecords)) {
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
                    .accessibilityHint(String(localized: Strings.Accessibility.editRecordHint))
                    .contextMenu {
                        Button {
                            Clipboard.copy("\(dataRecord.key)=\(dataRecord.value)")
                        } label: {
                            Label(String(localized: Strings.Actions.copyRecord), systemImage: "doc.on.doc")
                        }

                        Button {
                            Clipboard.copy(dataRecord.value)
                        } label: {
                            Label(String(localized: Strings.Actions.copyValue), systemImage: "doc.on.clipboard")
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            viewModel.deleteTxtRecord(dataRecord)
                        } label: {
                            Label(String(localized: Strings.Buttons.remove), systemImage: "minus.circle.fill")
                        }
                        .accessibilityLabel(Strings.Accessibility.remove(dataRecord.key))
                        .tint(.red)
                    }
                }

                Button {
                    viewModel.txtRecordToEdit = nil
                    viewModel.isCreateTxtRecordPresented = true
                } label: {
                    Label(String(localized: Strings.Buttons.addTxtRecord), systemImage: "plus.circle.fill")
                }
                .accessibilityHint(String(localized: Strings.Accessibility.addTxtRecordHint))
            }
        } else if !viewModel.dataRecords.isEmpty {
            Section(String(localized: Strings.Sections.txtRecords)) {
                ForEach(viewModel.dataRecords, id: \.key) { dataRecord in
                    TitleDetailStackView(
                        title: dataRecord.key,
                        detail: dataRecord.value
                    )
                    .draggable("\(dataRecord.key)=\(dataRecord.value)")
                    .accessibilityHint(String(localized: Strings.Accessibility.longPressCopyRecord))
                    .contextMenu {
                        Button {
                            Clipboard.copy("\(dataRecord.key)=\(dataRecord.value)")
                        } label: {
                            Label(String(localized: Strings.Actions.copyRecord), systemImage: "doc.on.doc")
                        }

                        Button {
                            Clipboard.copy(dataRecord.value)
                        } label: {
                            Label(String(localized: Strings.Actions.copyValue), systemImage: "doc.on.clipboard")
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
