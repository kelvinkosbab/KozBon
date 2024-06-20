//
//  SupportedServiceDetailView.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 6/18/24.
//  Copyright © 2024 Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - SupportedServiceDetailView

struct SupportedServiceDetailView: View {

    let serviceType: BonjourServiceType

    init(serviceType: BonjourServiceType) {
        self.serviceType = serviceType
    }
    
    @State private var showDeleteConfirmation = false
    @State private var showEditConfirmation = false

    var body: some View {
        List {
            Section {
                HStack(spacing: 10) {
                    Image(systemName: serviceType.imageSystemName)
                        .font(.system(.title3).bold())

                    VStack(alignment: .leading) {
                        Text(verbatim: serviceType.name)
                            .font(.system(.headline).bold())

                        Text(verbatim: serviceType.fullType)
                            .font(.system(.caption).bold())
                    }
                    Spacer()
                }
                .padding(.vertical, 10)
                .listRowBackground(
                    Color.kozBonBlue
                        .opacity(0.4)
                        .cornerRadius(10)
                )
            }

            Section {
                TitleDetailStackView(
                    title: "Name",
                    detail: serviceType.name
                )
                TitleDetailStackView(
                    title: "Type",
                    detail: serviceType.type
                )
                TitleDetailStackView(
                    title: "Transport layer",
                    detail: serviceType.transportLayer.string
                )
                TitleDetailStackView(
                    title: "Full type",
                    detail: serviceType.fullType
                )
            }
            
            if !serviceType.isBuiltIn {
                Section {
                    Button {
                        showEditConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Edit")
                                .font(.system(.headline).bold())
                                .padding(.vertical)
                            Spacer()
                        }
                    }
                    .foregroundStyle(.yellow)
                    .sheet(isPresented: $showEditConfirmation) {
                        CreateOrUpdateBonjourServiceTypeView(
                            isPresented: $showEditConfirmation,
                            serviceToUpdate: serviceType
                        )
                    }
                    .listRowBackground(
                        Color.yellow
                            .opacity(0.4)
                    )
                }
                
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Delete")
                                .font(.system(.headline).bold())
                                .padding(.vertical)
                            Spacer()
                        }
                    }
                    .confirmationDialog(
                        "Are you sure you want to delete this service type?",
                        isPresented: $showDeleteConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button(role: .destructive) {
                            // TODO: Delete the service and dismiss
                        } label: {
                            Label("Delete", systemImage: "minus.circle.fill")
                        }
                        .foregroundStyle(.red)
                    }
                    .listRowBackground(
                        Color.red
                            .opacity(0.4)
                    )
                }
            }
        }
        .contentMarginsBasedOnSizeClass()
    }
}
