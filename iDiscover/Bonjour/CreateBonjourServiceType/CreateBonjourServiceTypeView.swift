//
//  CreateBonjourServiceTypeView.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 6/17/24.
//  Copyright © 2024 Kozinga. All rights reserved.
//

import CoreUI
import SwiftUI

// MARK: - CreateBonjourServiceTypeView

struct CreateBonjourServiceTypeView: View {
    
    let toastApi = ToastApi(options: ToastOptions(
        position: .top,
        shape: .capsule,
        style: .slide
    ))

    @Binding var isPresented: Bool
    
    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }

    @State private var name = ""
    @State private var type = ""
    @State private var details = ""
    
    private let selectedTransportLayer: TransportLayer = .tcp

    var body: some View {
        NavigationStack {
            List {
                Section("Service name") {
                    TextField("Service name", text: $name)
                }

                Section {
                    TextField("Type definition", text: $type)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                        .onSubmit {
                            createButtonSelected()
                        }
                } header: {
                    Text("Bonjour type")
                } footer: {
                    if !type.isEmpty {
                        Text(verbatim: "_\(type)._\(selectedTransportLayer.string)")
                            .foregroundStyle(Color.kozBonBlue)
                    }
                }

                Section("Additional details") {
                    TextField("Additional information", text: $details)
                        .onSubmit {
                            createButtonSelected()
                        }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Create service type")
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
                        createButtonSelected()
                    } label: {
                        Label("Create", systemImage: "checkmark.circle.fill")
                    }
                }
            }
        }
        .toastableContainer(toastApi: toastApi)
    }
    
    private func createButtonSelected() {
        
        let transportLayer = selectedTransportLayer
        let name = name.trimmed
        let type = type.trimmed
        let details = details.trimmed
        
        guard !name.isEmpty else {
            toastApi.show(title: "Service Name Required")
            return
        }
        
        guard !type.isEmpty else {
            toastApi.show(title: "Service Type Required")
            return
        }
        
        guard !details.isEmpty else {
            toastApi.show(title: "Service Details Required")
            return
        }
        
        // Check that type does not match existing service types
        guard !BonjourServiceType.exists(type: type, transportLayer: transportLayer) else {
            toastApi.show(
                title: "Invalid Type",
                description: "The entered service type \(type) is already taken."
            )
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
