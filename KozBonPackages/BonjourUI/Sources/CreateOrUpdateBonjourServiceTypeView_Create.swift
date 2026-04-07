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

    @Binding var isPresented: Bool

    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }

    init(
        isPresented: Binding<Bool>,
        serviceToUpdate: BonjourServiceType
    ) {
        self._isPresented = isPresented
        self.name = serviceToUpdate.name
        self.type = serviceToUpdate.type
        self.details = serviceToUpdate.detail ?? ""
        self.isCreatingBonjourService = false
    }

    @State private var name = ""
    @State private var nameError: String?
    @State private var type = ""
    @State private var typeError: String?
    @State private var details = ""
    @State private var detailsError: String?

    private var isCreatingBonjourService: Bool = true
    private let selectedTransportLayer: TransportLayer = .tcp

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField(String(localized: Strings.Placeholders.serviceName), text: $name)
                } header: {
                    Text(Strings.Sections.serviceName)
                } footer: {
                    if let nameError {
                        Text(verbatim: nameError)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    TextField(String(localized: Strings.Placeholders.typeDefinition), text: $type)
                        .disableAutocorrection(true)
                        #if !os(macOS)
                        .textInputAutocapitalization(.never)
                        #endif
                        .onSubmit {
                            createButtonSelected()
                        }
                } header: {
                    Text(Strings.Sections.bonjourType)
                } footer: {
                    if let typeError, type.isEmpty {
                        Text(verbatim: typeError)
                            .foregroundStyle(.red)

                    } else if let typeError, !type.isEmpty {
                        Text(verbatim: "\(fullType) · \(typeError)")
                            .foregroundStyle(.red)

                    } else if !type.isEmpty {
                        Text(verbatim: fullType)
                            .foregroundStyle(Color.kozBonBlue)
                    }
                }

                Section {
                    TextField(String(localized: Strings.Placeholders.additionalInformation), text: $details)
                        .onSubmit {
                            createButtonSelected()
                        }
                } header: {
                    Text(Strings.Sections.additionalDetails)
                } footer: {
                    if let detailsError {
                        Text(verbatim: detailsError)
                            .foregroundStyle(.red)
                    }
                }
            }
            .contentMarginsBasedOnSizeClass()
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .navigationTitle(String(localized: Strings.NavigationTitles.createServiceType))
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
                        createButtonSelected()
                    } label: {
                        Label(String(localized: Strings.Buttons.create), systemImage: Iconography.confirm)
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
    }

    var fullType: String {
        "_\(type)._\(selectedTransportLayer.string)"
    }

    private func createButtonSelected() {

        let transportLayer = selectedTransportLayer
        let name = name.trimmed
        let type = type.trimmed
        let details = details.trimmed

        Task { @MainActor in
            withAnimation {
                nameError = nil
                typeError = nil
                detailsError = nil
            }
        }

        guard !name.isEmpty else {
            Task { @MainActor in
                withAnimation {
                    nameError = String(localized: Strings.Errors.nameRequired)
                }
            }
            return
        }

        guard !type.isEmpty else {
            Task { @MainActor in
                withAnimation {
                    typeError = String(localized: Strings.Errors.typeRequired)
                }
            }
            return
        }

        guard !details.isEmpty else {
            Task { @MainActor in
                withAnimation {
                    detailsError = String(localized: Strings.Errors.detailsRequired)
                }
            }
            return
        }

        // Check that type does not match existing service types
        guard !BonjourServiceType.exists(type: type, transportLayer: transportLayer) else {
            Task { @MainActor in
                withAnimation {
                    typeError = String(localized: Strings.Errors.alreadyExists)
                }
            }
          return
        }

        // Create the service type
        let serviceType = BonjourServiceType(
            name: name,
            type: type,
            transportLayer: transportLayer,
            detail: details
        )

        // Save a persistent copy of the service type
        serviceType.savePersistentCopy()

        Task { @MainActor in
            isPresented = false
        }
    }
}
