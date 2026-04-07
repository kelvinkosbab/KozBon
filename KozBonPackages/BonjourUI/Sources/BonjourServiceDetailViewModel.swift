//
//  BonjourServiceDetailViewModel.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourCore
import BonjourModels

// MARK: - TxtRecordEditSheet

struct TxtRecordEditSheet: View {
    @Bindable var viewModel: BonjourServiceDetailViewModel

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

// MARK: - BonjourServiceDetailViewModel

@MainActor
@Observable
final class BonjourServiceDetailViewModel: MyNetServiceDelegate {

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
