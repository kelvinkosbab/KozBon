//
//  CreateOrUpdateBonjourServiceTypeView.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 6/17/24.
//  Copyright © 2024 Kozinga. All rights reserved.
//

import CoreUI
import SwiftUI

// MARK: - CreateOrUpdateBonjourServiceTypeView

struct CreateOrUpdateBonjourServiceTypeView: View {

    @Binding var isPresented: Bool
    
    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
        self.name = ""
        self.type = ""
        self.details = ""
        self.isCreatingBonjourService = true
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

    @State private var name: String
    @State private var nameError: String?
    @State private var type: String
    @State private var typeError: String?
    @State private var details: String
    @State private var detailsError: String?
    
    private var isCreatingBonjourService: Bool
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
                        .disabled(!isCreatingBonjourService)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                        .onSubmit {
                            doneButtonSelected()
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
                        
                    } else if !isCreatingBonjourService {
                        Text(verbatim: fullType)
                            .foregroundStyle(Color.kozBonBlue)
                    }
                }

                Section {
                    TextField("Additional information", text: $details)
                        .onSubmit {
                            doneButtonSelected()
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
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(isCreatingBonjourService ? "Create service type" : "Edit service type")
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
                        // TODO: update content when edit completes
                        doneButtonSelected()
                    } label: {
                        Label("Done", systemImage: "checkmark.circle.fill")
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
        
        if isCreatingBonjourService {
            guard !BonjourServiceType.exists(type: type, transportLayer: transportLayer) else {
                Task { @MainActor in
                    withAnimation {
                        typeError = "Already Exists"
                    }
                }
                return
            }
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
