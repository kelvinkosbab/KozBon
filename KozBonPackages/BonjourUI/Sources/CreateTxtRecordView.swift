//
//  CreateTxtRecordView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourCore
import BonjourLocalization
import BonjourModels

// MARK: - CreateTxtRecordView

struct CreateTxtRecordView: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
                        String(localized: Strings.Placeholders.txtRecordKey),
                        text: $key
                    )
                    .accessibilityLabel(String(localized: Strings.Accessibility.txtRecordKey))
                    .accessibilityHint(String(localized: Strings.Accessibility.txtRecordKeyHint))
                    .onSubmit {
                        doneButtonSelected()
                    }

                } header: {
                    Text(Strings.Sections.recordKey)
                        .accessibilityAddTraits(.isHeader)
                } footer: {
                    if let keyError {
                        Text(verbatim: keyError)
                            .foregroundStyle(.red)
                            .accessibilityLabel(Strings.Accessibility.error(keyError))
                    }
                }

                Section {
                    TextField(
                        String(localized: Strings.Placeholders.txtRecordValue),
                        text: $value
                    )
                    .accessibilityLabel(String(localized: Strings.Accessibility.txtRecordValue))
                    .accessibilityHint(String(localized: Strings.Accessibility.txtRecordValueHint))
                    .onSubmit {
                        doneButtonSelected()
                    }

                } header: {
                    Text(Strings.Sections.recordValue)
                        .accessibilityAddTraits(.isHeader)
                } footer: {
                    if let valueError {
                        Text(verbatim: valueError)
                            .foregroundStyle(.red)
                            .accessibilityLabel(Strings.Accessibility.error(valueError))
                    }
                }
            }
            .contentMarginsBasedOnSizeClass()
            .navigationTitle(String(localized: Strings.NavigationTitles.createTxtRecord))
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        isPresented = false
                    } label: {
                        Label(String(localized: Strings.Buttons.cancel), systemImage: Iconography.cancel)
                    }
                    .keyboardShortcut(.cancelAction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        doneButtonSelected()
                    } label: {
                        Label(String(localized: Strings.Buttons.done), systemImage: Iconography.confirm)
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .onChange(of: [key, value]) {
                withAnimation(reduceMotion ? nil : .default) {
                    if keyError != nil {
                        keyError = nil
                    }

                    if valueError != nil {
                        valueError = nil
                    }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 400, idealWidth: 450, minHeight: 300, idealHeight: 350)
        #endif
    }

    private func doneButtonSelected() {

        let key = key.trimmed
        let value = value.trimmed

        withAnimation(reduceMotion ? nil : .default) {
            keyError = nil
            valueError = nil
        }

        guard !key.isEmpty else {
            withAnimation(reduceMotion ? nil : .default) {
                keyError = String(localized: Strings.Errors.txtKeyRequired)
            }
            return
        }

        guard !value.isEmpty else {
            withAnimation(reduceMotion ? nil : .default) {
                valueError = String(localized: Strings.Errors.txtValueRequired)
            }
            return
        }

        // Check for duplicate key (unless we're updating the same record)
        let isDuplicate = txtDataRecords.contains { $0.key == key }
        guard txtRecordToUpdate != nil || !isDuplicate else {
            withAnimation(reduceMotion ? nil : .default) {
                keyError = String(localized: Strings.Errors.txtKeyDuplicate)
            }
            return
        }

        withAnimation(reduceMotion ? nil : .default) {
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
