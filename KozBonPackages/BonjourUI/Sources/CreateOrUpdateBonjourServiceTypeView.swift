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

struct CreateOrUpdateBonjourServiceTypeView: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Binding private var isPresented: Bool
    @Binding private var serviceTypeToUpdate: BonjourServiceType

    @State private var name: String
    @State private var nameError: String?
    @State private var type: String
    @State private var typeError: String?
    @State private var details: String
    @State private var detailsError: String?

    /// Whether the form has valid inputs for creating or updating a service type.
    private var isFormValid: Bool {
        !name.trimmed.isEmpty && !type.trimmed.isEmpty && !details.trimmed.isEmpty
    }

    private var isCreatingBonjourService: Bool
    private let selectedTransportLayer: TransportLayer = .tcp

    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
        self.name = ""
        self.type = ""
        self.details = ""
        self._serviceTypeToUpdate = .constant(BonjourServiceType(
            name: "",
            type: "",
            transportLayer: .tcp,
            detail: ""
        ))
        self.isCreatingBonjourService = true
    }

    init(
        isPresented: Binding<Bool>,
        serviceToUpdate: Binding<BonjourServiceType>
    ) {
        self._isPresented = isPresented
        self.name = serviceToUpdate.wrappedValue.name
        self.type = serviceToUpdate.wrappedValue.type
        self.details = serviceToUpdate.wrappedValue.detail ?? ""
        self._serviceTypeToUpdate = serviceToUpdate
        self.isCreatingBonjourService = false
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField(String(localized: Strings.Placeholders.serviceName), text: $name)
                        .accessibilityLabel(String(localized: Strings.Accessibility.serviceName))
                        .accessibilityHint(String(localized: Strings.Accessibility.serviceNameHint))
                } header: {
                    Text(Strings.Sections.serviceName)
                } footer: {
                    if let nameError {
                        Text(verbatim: nameError)
                            .foregroundStyle(.red)
                            .accessibilityLabel(Strings.Accessibility.error(nameError))
                    }
                }

                Section {
                    TextField(String(localized: Strings.Placeholders.typeDefinition), text: $type)
                        .accessibilityLabel(String(localized: Strings.Accessibility.bonjourType))
                        .accessibilityHint(String(localized: Strings.Accessibility.bonjourTypeHint))
                        .disabled(!isCreatingBonjourService)
                        .disableAutocorrection(true)
                        #if !os(macOS)
                        .autocapitalization(.none)
                        #endif
                        .onSubmit {
                            doneButtonSelected()
                        }
                } header: {
                    Text(Strings.Sections.bonjourType)
                } footer: {
                    if let typeError, type.isEmpty {
                        Text(verbatim: typeError)
                            .foregroundStyle(.red)
                            .accessibilityLabel(Strings.Accessibility.error(typeError))

                    } else if let typeError, !type.isEmpty {
                        Text(verbatim: "\(fullType) · \(typeError)")
                            .foregroundStyle(.red)
                            .accessibilityLabel(Strings.Accessibility.error("\(typeError) for \(fullType)"))

                    } else if !type.isEmpty {
                        Text(verbatim: fullType)
                            .foregroundStyle(Color.kozBonBlue)

                    } else if !isCreatingBonjourService {
                        Text(verbatim: fullType)
                            .foregroundStyle(Color.kozBonBlue)
                    }
                }

                Section {
                    TextField(String(localized: Strings.Placeholders.additionalInformation), text: $details)
                        .accessibilityLabel(String(localized: Strings.Accessibility.additionalDetails))
                        .accessibilityHint(String(localized: Strings.Accessibility.additionalDetailsHint))
                        .onSubmit {
                            doneButtonSelected()
                        }
                } header: {
                    Text(Strings.Sections.additionalDetails)
                } footer: {
                    if let detailsError {
                        Text(verbatim: detailsError)
                            .foregroundStyle(.red)
                            .accessibilityLabel(Strings.Accessibility.error(detailsError))
                    }
                }
            }
            .contentMarginsBasedOnSizeClass()
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .navigationTitle(
                isCreatingBonjourService
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
                        doneButtonSelected()
                    } label: {
                        Label(String(localized: Strings.Buttons.done), systemImage: Iconography.confirm)
                    }
                    .disabled(!isFormValid)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .onChange(of: [name, type, details]) {
                withAnimation(reduceMotion ? nil : .default) {
                    if !name.trimmed.isEmpty {
                        nameError = nil
                    }

                    if !type.trimmed.isEmpty {
                        typeError = nil
                    }

                    if !details.trimmed.isEmpty {
                        detailsError = nil
                    }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 480, idealWidth: 520, minHeight: 400, idealHeight: 500)
        #endif
    }

    var fullType: String {
        "_\(type)._\(selectedTransportLayer.string)"
    }

    private func doneButtonSelected() {

        let transportLayer = selectedTransportLayer
        let name = name.trimmed
        let type = type.trimmed
        let details = details.trimmed

        withAnimation(reduceMotion ? nil : .default) {
            nameError = nil
            typeError = nil
            detailsError = nil
        }

        guard !name.isEmpty else {
            withAnimation(reduceMotion ? nil : .default) {
                nameError = String(localized: Strings.Errors.nameRequired)
            }
            return
        }

        guard !type.isEmpty else {
            withAnimation(reduceMotion ? nil : .default) {
                typeError = String(localized: Strings.Errors.typeRequired)
            }
            return
        }

        guard !details.isEmpty else {
            withAnimation(reduceMotion ? nil : .default) {
                detailsError = String(localized: Strings.Errors.detailsRequired)
            }
            return
        }

        if isCreatingBonjourService {
            guard !BonjourServiceType.exists(type: type, transportLayer: transportLayer) else {
                withAnimation(reduceMotion ? nil : .default) {
                    typeError = String(localized: Strings.Errors.alreadyExists)
                }
                return
            }
        }

        // Create the service type
        serviceTypeToUpdate.deletePersistentCopy()
        let serviceType = BonjourServiceType(
            name: name,
            type: type,
            transportLayer: transportLayer,
            detail: details
        )

        // Save a persistent copy of the service type
        serviceType.savePersistentCopy()

        serviceTypeToUpdate = serviceType
        isPresented = false
    }
}
