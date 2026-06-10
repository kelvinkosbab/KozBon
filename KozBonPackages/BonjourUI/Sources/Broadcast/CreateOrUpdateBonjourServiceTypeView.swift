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
import BonjourStorage

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
    @Environment(\.preferencesStore) private var preferencesStore

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
                        .accessibilityLabel(Strings.Accessibility.serviceName)
                        .accessibilityHint(Strings.Accessibility.serviceNameHint)
                } header: {
                    Text(Strings.Sections.serviceName)
                        .accessibilityAddTraits(.isHeader)
                } footer: {
                    // Always show the field hint; layer the validation
                    // error on top when present. Stacked in a VStack
                    // (same pattern as the details section below) to
                    // keep both lines readable instead of one
                    // shadowing the other.
                    VStack(alignment: .leading, spacing: 8) {
                        if let nameError = viewModel.nameError {
                            Text(verbatim: nameError)
                                .foregroundStyle(.red)
                                .accessibilityLabel(Strings.Accessibility.error(nameError))
                        }
                        Text(Strings.Guidance.serviceNameHint)
                    }
                }

                Section {
                    TextField(String(localized: Strings.Placeholders.typeDefinition), text: $bindable.type)
                        .accessibilityLabel(Strings.Accessibility.bonjourType)
                        .accessibilityHint(Strings.Accessibility.bonjourTypeHint)
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
                    // Two lines of footer content:
                    //   1. Validation error or `_type._transport`
                    //      preview (mutually exclusive — preview is
                    //      blue, error is red).
                    //   2. The discovery-semantic hint, always shown.
                    // The preview/error sits above the hint so the
                    // user's typing-feedback line stays adjacent to
                    // the field; the hint is reference text below.
                    VStack(alignment: .leading, spacing: 8) {
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
                        Text(Strings.Guidance.bonjourTypeHint)
                    }
                }

                Section {
                    TextField(
                        String(localized: Strings.Placeholders.additionalInformation),
                        text: $bindable.details,
                        axis: .vertical
                    )
                    .lineLimit(3...8)
                    .accessibilityLabel(Strings.Accessibility.additionalDetails)
                    .accessibilityHint(Strings.Accessibility.additionalDetailsHint)
                    .onSubmit {
                        commit()
                    }
                } header: {
                    Text(Strings.Sections.additionalDetails)
                        .accessibilityAddTraits(.isHeader)
                } footer: {
                    // Stack the footnotes under the details field:
                    // any validation error, the Insights context note
                    // (only when AI is enabled — the field exists for
                    // forward-compat when AI is off, but mentioning
                    // Insights would be misleading), and the form-wide
                    // best-practices guidance. Putting them in this
                    // section's footer — instead of a separate empty
                    // section below — avoids the visible gap that
                    // inset-grouped card spacing introduces between
                    // sections.
                    VStack(alignment: .leading, spacing: 8) {
                        if let detailsError = viewModel.detailsError {
                            Text(verbatim: detailsError)
                                .foregroundStyle(.red)
                                .accessibilityLabel(Strings.Accessibility.error(detailsError))
                        }
                        if preferencesStore.aiAnalysisEnabled {
                            Text(Strings.Sections.aiContextFooter)
                        }
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
                        Label(Strings.Buttons.cancel, systemImage: Iconography.cancel)
                    }
                    .keyboardShortcut(.cancelAction)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        commit()
                    } label: {
                        Label(Strings.Buttons.done, systemImage: Iconography.confirm)
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
