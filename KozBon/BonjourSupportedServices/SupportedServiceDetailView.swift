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
    @State private var isNavigationHeaderShown = false

    var body: some View {
        List {
            Section {
                BlueSectionItemIconTitleDetailView(
                    imageSystemName: serviceType.imageSystemName,
                    title: serviceType.name,
                    detail: serviceType.fullType
                )
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
            }

            Section {
                TitleDetailStackView(
                    title: "Name",
                    detail: serviceType.name
                )
                .accessibilityHint("Long press to copy name")
                .contextMenu {
                    Button {
                        Clipboard.copy(serviceType.name)
                    } label: {
                        Label("Copy Name", systemImage: "doc.on.doc")
                    }
                }
                TitleDetailStackView(
                    title: "Type",
                    detail: serviceType.type
                )
                .accessibilityHint("Long press to copy type")
                .contextMenu {
                    Button {
                        Clipboard.copy(serviceType.type)
                    } label: {
                        Label("Copy Type", systemImage: "doc.on.doc")
                    }
                }
                TitleDetailStackView(
                    title: "Transport layer",
                    detail: serviceType.transportLayer.string
                )
                TitleDetailStackView(
                    title: "Full type",
                    detail: serviceType.fullType
                )
                .accessibilityHint("Long press to copy full type")
                .contextMenu {
                    Button {
                        Clipboard.copy(serviceType.fullType)
                    } label: {
                        Label("Copy Full Type", systemImage: "doc.on.doc")
                    }
                }
                if let detail = serviceType.detail, !detail.isEmpty {
                    TitleDetailStackView(
                        title: "Details",
                        detail: detail
                    )
                    .accessibilityHint("Long press to copy details")
                    .contextMenu {
                        Button {
                            Clipboard.copy(detail)
                        } label: {
                            Label("Copy Details", systemImage: "doc.on.doc")
                        }
                    }
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
                    .accessibilityLabel("Edit \(serviceType.name)")
                    .accessibilityHint("Double tap to edit this service type")
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
                    .accessibilityLabel("Delete \(serviceType.name)")
                    .accessibilityHint("Double tap to delete this service type")
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
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            if isNavigationHeaderShown {
                ToolbarItem(
                    placement: horizontalSizeClass == .compact ? .principal : .confirmationAction
                ) {
                    ServiceTypeBadge(serviceType: serviceType, style: .basedOnSizeClass)
                }
            }
        }
    }

}
