//
//  CreateOrUpdateBonjourServiceTypeView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import CoreUI
import SwiftUI
import BonjourCore
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
                    TextField("Service name", text: $name)
                } header: {
                    Text("Service name")
                } footer: {
                    if let nameError {
                        Text(verbatim: nameError)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    TextField("Type definition", text: $type)
                        .disableAutocorrection(true)
                        #if !os(macOS)
                        .textInputAutocapitalization(.never)
                        #endif
                        .onSubmit {
                            createButtonSelected()
                        }
                } header: {
                    Text("Bonjour type")
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
                    TextField("Additional information", text: $details)
                        .onSubmit {
                            createButtonSelected()
                        }
                } header: {
                    Text("Additional details")
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
            .navigationTitle("Create service type")
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
                        createButtonSelected()
                    } label: {
                        Label("Create", systemImage: "checkmark.circle.fill")
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
                    nameError = "Name required"
                }
            }
            return
        }

        guard !type.isEmpty else {
            Task { @MainActor in
                withAnimation {
                    typeError = "Type required"
                }
            }
            return
        }

        guard !details.isEmpty else {
            Task { @MainActor in
                withAnimation {
                    detailsError = "Details required"
                }
            }
            return
        }

        // Check that type does not match existing service types
        guard !BonjourServiceType.exists(type: type, transportLayer: transportLayer) else {
            Task { @MainActor in
                withAnimation {
                    typeError = "Already Exists"
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
