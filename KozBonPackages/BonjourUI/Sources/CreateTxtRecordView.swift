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

/// Sheet that creates or edits a single TXT record on a
/// broadcast. The form's input state, error strings, and
/// validation pipeline live on ``CreateTxtRecordViewModel`` —
/// the View is a thin presenter that binds the controls to the
/// VM, forwards `@Environment(\.accessibilityReduceMotion)`
/// into the validate-and-commit call, and applies the VM's
/// returned array to the parent's `txtDataRecords` binding.
struct CreateTxtRecordView: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Binding private var isPresented: Bool
    @Binding private var txtDataRecords: [BonjourService.TxtDataRecord]
    @State private var viewModel: CreateTxtRecordViewModel

    init(
        isPresented: Binding<Bool>,
        txtDataRecords: Binding<[BonjourService.TxtDataRecord]>
    ) {
        self._isPresented = isPresented
        self._txtDataRecords = txtDataRecords
        self._viewModel = State(initialValue: .empty())
    }

    init(
        isPresented: Binding<Bool>,
        txtDataRecords: Binding<[BonjourService.TxtDataRecord]>,
        txtRecordToUpdate: BonjourService.TxtDataRecord
    ) {
        self._isPresented = isPresented
        self._txtDataRecords = txtDataRecords
        self._viewModel = State(initialValue: .editing(txtRecordToUpdate))
    }

    var body: some View {
        @Bindable var bindable = viewModel
        NavigationStack {
            List {
                Section {
                    TextField(
                        String(localized: Strings.Placeholders.txtRecordKey),
                        text: $bindable.key
                    )
                    .accessibilityLabel(String(localized: Strings.Accessibility.txtRecordKey))
                    .accessibilityHint(String(localized: Strings.Accessibility.txtRecordKeyHint))
                    .onSubmit {
                        commit()
                    }

                } header: {
                    Text(Strings.Sections.recordKey)
                        .accessibilityAddTraits(.isHeader)
                } footer: {
                    if let keyError = viewModel.keyError {
                        Text(verbatim: keyError)
                            .foregroundStyle(.red)
                            .accessibilityLabel(Strings.Accessibility.error(keyError))
                    }
                }

                Section {
                    TextField(
                        String(localized: Strings.Placeholders.txtRecordValue),
                        text: $bindable.value
                    )
                    .accessibilityLabel(String(localized: Strings.Accessibility.txtRecordValue))
                    .accessibilityHint(String(localized: Strings.Accessibility.txtRecordValueHint))
                    .onSubmit {
                        commit()
                    }

                } header: {
                    Text(Strings.Sections.recordValue)
                        .accessibilityAddTraits(.isHeader)
                } footer: {
                    // Stack the validation error (if any) above the
                    // form-wide guidance explaining what TXT records
                    // publish. Both live in the last section's footer
                    // rather than a separate trailing section — putting
                    // it in a separate section would add inset-grouped
                    // card spacing between the fields and the footnote.
                    VStack(alignment: .leading, spacing: 8) {
                        if let valueError = viewModel.valueError {
                            Text(verbatim: valueError)
                                .foregroundStyle(.red)
                                .accessibilityLabel(Strings.Accessibility.error(valueError))
                        }
                        Text(Strings.Guidance.txtRecord)
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
                        commit()
                    } label: {
                        Label(String(localized: Strings.Buttons.done), systemImage: Iconography.confirm)
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .onChange(of: [viewModel.key, viewModel.value]) {
                viewModel.clearErrorsOnEdit(reduceMotion: reduceMotion)
            }
        }
        #if os(macOS) || os(visionOS)
        // Inset card sizing on macOS and visionOS — without an explicit
        // frame, the simple key/value form sprawls across the full
        // window/ornament. Smaller than the broadcast/create-type
        // sheets because there are only two fields here.
        .frame(minWidth: 400, idealWidth: 450, minHeight: 300, idealHeight: 350)
        #endif
    }

    /// Validates via the VM, applies the returned array to the
    /// parent's binding, and dismisses the sheet on success.
    /// Wrapped in a single `withAnimation` so the array update
    /// and the sheet dismissal land together.
    private func commit() {
        guard let updated = viewModel.submit(
            currentRecords: txtDataRecords,
            reduceMotion: reduceMotion
        ) else {
            return
        }
        withAnimation(reduceMotion ? nil : .default) {
            txtDataRecords = updated
            isPresented = false
        }
    }
}
