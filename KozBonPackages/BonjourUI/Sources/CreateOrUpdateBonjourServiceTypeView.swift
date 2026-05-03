//
//  CreateOrUpdateBonjourServiceTypeView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import CoreUI
import SwiftUI
import BonjourCore
import BonjourLocalization
import BonjourModels

// MARK: - CreateOrUpdateBonjourServiceTypeView

/// Sheet that creates or edits a custom Bonjour service type.
/// The form's input state, error strings, and validation
/// pipeline live on ``CreateOrUpdateBonjourServiceTypeViewModel``;
/// the View is a thin presenter that binds the controls to the
/// VM, forwards `@Environment(\.accessibilityReduceMotion)`
/// into the validate call, and applies the validated result to
/// the Core Data persistent store and the parent's
/// `serviceTypeToUpdate` binding.
struct CreateOrUpdateBonjourServiceTypeView: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Binding private var isPresented: Bool
    @Binding private var serviceTypeToUpdate: BonjourServiceType
    @State private var viewModel: CreateOrUpdateBonjourServiceTypeViewModel

    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
        self._serviceTypeToUpdate = .constant(BonjourServiceType(
            name: "",
            type: "",
            transportLayer: .tcp,
            detail: ""
        ))
        self._viewModel = State(initialValue: .empty())
    }

    /// Create-mode init pre-filled with values supplied by the chat
    /// assistant's `prepareCustomServiceType` tool. The form's
    /// regular validation still gates the Done button, so an empty
    /// or otherwise-invalid pre-fill simply renders an editable
    /// form with that text preloaded — exactly what happens when
    /// the user starts typing themselves.
    init(
        isPresented: Binding<Bool>,
        prefilledName: String,
        prefilledType: String,
        prefilledDetails: String
    ) {
        self._isPresented = isPresented
        self._serviceTypeToUpdate = .constant(BonjourServiceType(
            name: "",
            type: "",
            transportLayer: .tcp,
            detail: ""
        ))
        self._viewModel = State(initialValue: .prefilled(
            name: prefilledName,
            type: prefilledType,
            details: prefilledDetails
        ))
    }

    init(
        isPresented: Binding<Bool>,
        serviceToUpdate: Binding<BonjourServiceType>
    ) {
        self._isPresented = isPresented
        self._serviceTypeToUpdate = serviceToUpdate
        self._viewModel = State(initialValue: .editing(serviceToUpdate.wrappedValue))
    }

    var body: some View {
        @Bindable var bindable = viewModel
        NavigationStack {
            List {
                Section {
                    TextField(String(localized: Strings.Placeholders.serviceName), text: $bindable.name)
                        .accessibilityLabel(String(localized: Strings.Accessibility.serviceName))
                        .accessibilityHint(String(localized: Strings.Accessibility.serviceNameHint))
                } header: {
                    Text(Strings.Sections.serviceName)
                        .accessibilityAddTraits(.isHeader)
                } footer: {
                    if let nameError = viewModel.nameError {
                        Text(verbatim: nameError)
                            .foregroundStyle(.red)
                            .accessibilityLabel(Strings.Accessibility.error(nameError))
                    }
                }

                Section {
                    TextField(String(localized: Strings.Placeholders.typeDefinition), text: $bindable.type)
                        .accessibilityLabel(String(localized: Strings.Accessibility.bonjourType))
                        .accessibilityHint(String(localized: Strings.Accessibility.bonjourTypeHint))
                        .disabled(!viewModel.isCreatingBonjourService)
                        .disableAutocorrection(true)
                        #if !os(macOS)
                        .autocapitalization(.none)
                        #endif
                        .onSubmit {
                            commit()
                        }
                } header: {
                    Text(Strings.Sections.bonjourType)
                        .accessibilityAddTraits(.isHeader)
                } footer: {
                    if let typeError = viewModel.typeError, viewModel.type.isEmpty {
                        Text(verbatim: typeError)
                            .foregroundStyle(.red)
                            .accessibilityLabel(Strings.Accessibility.error(typeError))

                    } else if let typeError = viewModel.typeError, !viewModel.type.isEmpty {
                        Text(verbatim: "\(viewModel.fullType) · \(typeError)")
                            .foregroundStyle(.red)
                            .accessibilityLabel(Strings.Accessibility.error("\(typeError) for \(viewModel.fullType)"))

                    } else if !viewModel.type.isEmpty {
                        Text(verbatim: viewModel.fullType)
                            .foregroundStyle(Color.kozBonBlue)

                    } else if !viewModel.isCreatingBonjourService {
                        Text(verbatim: viewModel.fullType)
                            .foregroundStyle(Color.kozBonBlue)
                    }
                }

                Section {
                    TextField(
                        String(localized: Strings.Placeholders.additionalInformation),
                        text: $bindable.details,
                        axis: .vertical
                    )
                    .lineLimit(3...8)
                    .accessibilityLabel(String(localized: Strings.Accessibility.additionalDetails))
                    .accessibilityHint(String(localized: Strings.Accessibility.additionalDetailsHint))
                    .onSubmit {
                        commit()
                    }
                } header: {
                    Text(Strings.Sections.additionalDetails)
                        .accessibilityAddTraits(.isHeader)
                } footer: {
                    // Stack the three footnotes that belong under the
                    // details field: any validation error, the Insights
                    // context note (what this text is used for), and
                    // the form-wide best-practices guidance. Putting
                    // them in the last section's footer — instead of a
                    // separate empty section below it — avoids the
                    // visible gap that inset-grouped card spacing
                    // introduces between sections.
                    VStack(alignment: .leading, spacing: 8) {
                        if let detailsError = viewModel.detailsError {
                            Text(verbatim: detailsError)
                                .foregroundStyle(.red)
                                .accessibilityLabel(Strings.Accessibility.error(detailsError))
                        }
                        Text(Strings.Sections.aiContextFooter)
                        Text(Strings.Guidance.createServiceType)
                    }
                }
            }
            .contentMarginsBasedOnSizeClass()
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .navigationTitle(
                viewModel.isCreatingBonjourService
                    ? String(localized: Strings.NavigationTitles.createServiceType)
                    : String(localized: Strings.NavigationTitles.editServiceType)
            )
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
                    .disabled(!viewModel.isFormValid)
                    .accessibilityHint(
                        viewModel.isFormValid
                            ? ""
                            : String(localized: Strings.Accessibility.formIncompleteHint)
                    )
                    .keyboardShortcut(.defaultAction)
                }
            }
            .onChange(of: [viewModel.name, viewModel.type, viewModel.details]) {
                viewModel.clearErrorsOnEdit(reduceMotion: reduceMotion)
            }
        }
        #if os(macOS) || os(visionOS)
        // Inset card sizing on macOS and visionOS — see the matching
        // comment in `BroadcastBonjourServiceView` for rationale.
        .frame(minWidth: 480, idealWidth: 520, minHeight: 400, idealHeight: 500)
        #endif
    }

    /// Validates via the VM and, on success, performs the Core
    /// Data side effects (delete the previous persistent copy
    /// in update mode, save the new one) and dismisses the
    /// sheet. The deletePersistentCopy on the bound
    /// `serviceTypeToUpdate` is keyed on the *original*
    /// `(type, transport)` pair — that's the row Core Data
    /// will find. In create mode the bound value is the empty
    /// placeholder, so the lookup returns nil and the delete
    /// no-ops, matching the original code's behavior.
    private func commit() {
        guard let inputs = viewModel.validate(reduceMotion: reduceMotion) else {
            return
        }
        serviceTypeToUpdate.deletePersistentCopy()
        inputs.serviceType.savePersistentCopy()
        serviceTypeToUpdate = inputs.serviceType
        isPresented = false
    }
}
