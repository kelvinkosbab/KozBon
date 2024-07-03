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

    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    init(serviceType: BonjourServiceType) {
        self.serviceType = serviceType
    }

    @State private var serviceType: BonjourServiceType
    @State private var showDeleteConfirmation = false
    @State private var showEditConfirmation = false
    
    #if !os(macOS)
    @State private var isNavigationHeaderShown = false
    #endif

    var body: some View {
        List {
            Section {
                BlueSectionItemIconTitleDetailView(
                    imageSystemName: serviceType.imageSystemName,
                    title: serviceType.name,
                    detail: serviceType.fullType
                )
                #if !os(macOS)
                .onAppear {
                    withAnimation {
                        isNavigationHeaderShown = false
                    }
                }
                .onDisappear {
                    withAnimation {
                        isNavigationHeaderShown = true
                    }
                }
                #endif
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
                if let detail = serviceType.detail, !detail.isEmpty {
                    TitleDetailStackView(
                        title: "Details",
                        detail: detail
                    )
                }
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
                            serviceToUpdate: $serviceType
                        )
                    }
                    .listRowBackground(
                        Color.yellow
                            .opacity(0.2)
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
                            serviceType.deletePersistentCopy()
                            dismiss()
                        } label: {
                            Label("Delete", systemImage: "minus.circle.fill")
                        }
                        .foregroundStyle(.red)
                    }
                    .listRowBackground(
                        Color.red
                            .opacity(0.2)
                    )
                }
            }
        }
        .contentMarginsBasedOnSizeClass()
        #if !os(macOS)
        .toolbar {
            if isNavigationHeaderShown {
                ToolbarItem(
                    placement: horizontalSizeClass == .compact ? .principal : .topBarTrailing
                ) {
                    HStack {
                        Label(serviceType.name, systemImage: serviceType.imageSystemName)
                            .padding(.vertical, 5)
                            .padding(.horizontal)
                    }
                    .background(
                        Color.kozBonBlue
                            .opacity(0.4)
                    )
                    .clipShape(.capsule)
                }
            }
        }
        #endif
    }
}
