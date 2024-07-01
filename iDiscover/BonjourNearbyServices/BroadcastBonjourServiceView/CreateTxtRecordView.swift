//
//  CreateTxtRecordView.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 7/1/24.
//  Copyright © 2024 Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - CreateTxtRecordView

struct CreateTxtRecordView: View {
    
    @Binding private var isPresented: Bool
    @Binding private var txtDataRecords: [BonjourService.TxtDataRecord]
    private let txtRecordToUpdate: BonjourService.TxtDataRecord?
    
    @State private var key: String
    @State private var keyError: String?
    @State private var value: String
    @State private var valueError: String?
    
    init(
        isPresented: Binding<Bool>,
        txtDataRecords: Binding<[BonjourService.TxtDataRecord]>
    ) {
        self._isPresented = isPresented
        self._txtDataRecords = txtDataRecords
        key = ""
        value = ""
        txtRecordToUpdate = nil
    }
    
    init(
        isPresented: Binding<Bool>,
        txtDataRecords: Binding<[BonjourService.TxtDataRecord]>,
        txtRecordToUpdate: BonjourService.TxtDataRecord
    ) {
        self._isPresented = isPresented
        self._txtDataRecords = txtDataRecords
        key = txtRecordToUpdate.key
        value = txtRecordToUpdate.value
        self.txtRecordToUpdate = txtRecordToUpdate
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField(
                        "TXT Record Key",
                        text: $key
                    )
                    .onSubmit {
                        doneButtonSelected()
                    }
                    
                } header: {
                    Text("Record Key")
                } footer: {
                    if let keyError {
                        Text(verbatim: keyError)
                            .foregroundStyle(.red)
                    }
                }
                
                Section {
                    TextField(
                        "TXT Record Value",
                        text: $value
                    )
                    .onSubmit {
                        doneButtonSelected()
                    }
                    
                } header: {
                    Text("Record Value")
                } footer: {
                    if let valueError {
                        Text(verbatim: valueError)
                            .foregroundStyle(.red)
                    }
                }
            }
            .contentMarginsBasedOnSizeClass()
            .navigationTitle("Create Txt Record")
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
            .onChange(of: key) { newValue in
                Task { @MainActor in
                    withAnimation {
                        if keyError != nil {
                            keyError = nil
                        }
                    }
                }
            }
            .onChange(of: value) { newValue in
                Task { @MainActor in
                    withAnimation {
                        if valueError != nil {
                            valueError = nil
                        }
                    }
                }
            }
        }
    }
    
    private func doneButtonSelected() {
        
        let key = key.trimmed
        let value = value.trimmed
        
        Task { @MainActor in
            withAnimation {
                keyError = nil
                valueError = nil
            }
        }
        
        guard !key.trimmed.isEmpty else {
            Task { @MainActor in
                withAnimation {
                    keyError = "TXT record key required"
                }
            }
            return
        }
        
        guard !value.trimmed.isEmpty else {
            Task { @MainActor in
                withAnimation {
                    valueError = "TXT record value required"
                }
            }
            return
        }
        
        Task { @MainActor in
            withAnimation {
                let newRecord = BonjourService.TxtDataRecord(key: key, value: value)
                let oldIndex = txtDataRecords.firstIndex { $0.key == txtRecordToUpdate?.key }
                if let oldIndex {
                    txtDataRecords[oldIndex] = newRecord
                } else {
                    txtDataRecords.append(newRecord)
                }
                
                isPresented = false
            }
        }
    }
}
