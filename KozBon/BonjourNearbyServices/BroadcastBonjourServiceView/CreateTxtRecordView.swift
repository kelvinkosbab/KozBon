//
//  CreateTxtRecordView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
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
                    .accessibilityLabel("TXT record key")
                    .accessibilityHint("Enter the key for this TXT record")
                    .onSubmit {
                        doneButtonSelected()
                    }

                } header: {
                    Text("Record Key")
                } footer: {
                    if let keyError {
                        Text(verbatim: keyError)
                            .foregroundStyle(.red)
                            .accessibilityLabel("Error: \(keyError)")
                    }
                }

                Section {
                    TextField(
                        "TXT Record Value",
                        text: $value
                    )
                    .accessibilityLabel("TXT record value")
                    .accessibilityHint("Enter the value for this TXT record")
                    .onSubmit {
                        doneButtonSelected()
                    }

                } header: {
                    Text("Record Value")
                } footer: {
                    if let valueError {
                        Text(verbatim: valueError)
                            .foregroundStyle(.red)
                            .accessibilityLabel("Error: \(valueError)")
                    }
                }
            }
            .contentMarginsBasedOnSizeClass()
            .navigationTitle("Create Txt Record")
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
            .onChange(of: [key, value]) {
                withAnimation {
                    if keyError != nil {
                        keyError = nil
                    }

                    if valueError != nil {
                        valueError = nil
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
