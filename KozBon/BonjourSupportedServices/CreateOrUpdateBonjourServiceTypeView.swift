//
//  CreateOrUpdateBonjourServiceTypeView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import CoreUI
import SwiftUI

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
                    TextField("Service name", text: $name)
                        .accessibilityLabel("Service name")
                        .accessibilityHint("Enter a display name for this service type")
                } header: {
                    Text("Service name")
                } footer: {
                    if let nameError {
                        Text(verbatim: nameError)
                            .foregroundStyle(.red)
                            .accessibilityLabel("Error: \(nameError)")
                    }
                }

                Section {
                    TextField("Type definition", text: $type)
                        .accessibilityLabel("Bonjour type")
                        .accessibilityHint("Enter the Bonjour type identifier, for example http or ssh")
                        .disabled(!isCreatingBonjourService)
                        .disableAutocorrection(true)
                        #if !os(macOS)
                        .autocapitalization(.none)
                        #endif
                        .onSubmit {
                            doneButtonSelected()
                        }
                } header: {
                    Text("Bonjour type")
                } footer: {
                    if let typeError, type.isEmpty {
                        Text(verbatim: typeError)
                            .foregroundStyle(.red)
                            .accessibilityLabel("Error: \(typeError)")

                    } else if let typeError, !type.isEmpty {
                        Text(verbatim: "\(fullType) · \(typeError)")
                            .foregroundStyle(.red)
                            .accessibilityLabel("Error: \(typeError) for \(fullType)")

                    } else if !type.isEmpty {
                        Text(verbatim: fullType)
                            .foregroundStyle(Color.kozBonBlue)

                    } else if !isCreatingBonjourService {
                        Text(verbatim: fullType)
                            .foregroundStyle(Color.kozBonBlue)
                    }
                }

                Section {
                    TextField("Additional information", text: $details)
                        .accessibilityLabel("Additional details")
                        .accessibilityHint("Enter a description of this service type")
                        .onSubmit {
                            doneButtonSelected()
                        }
                } header: {
                    Text("Additional details")
                } footer: {
                    if let detailsError {
                        Text(verbatim: detailsError)
                            .foregroundStyle(.red)
                            .accessibilityLabel("Error: \(detailsError)")
                    }
                }
            }
            .contentMarginsBasedOnSizeClass()
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .navigationTitle(isCreatingBonjourService ? "Create service type" : "Edit service type")
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
                nameError = "Name required"
            }
            return
        }

        guard !type.isEmpty else {
            withAnimation(reduceMotion ? nil : .default) {
                typeError = "Type required"
            }
            return
        }

        guard !details.isEmpty else {
            withAnimation(reduceMotion ? nil : .default) {
                detailsError = "Details required"
            }
            return
        }

        if isCreatingBonjourService {
            guard !BonjourServiceType.exists(type: type, transportLayer: transportLayer) else {
                withAnimation(reduceMotion ? nil : .default) {
                    typeError = "Already Exists"
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
