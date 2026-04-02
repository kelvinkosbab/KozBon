//
//  SupportedServiceDetailView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - SupportedServiceDetailView

struct SupportedServiceDetailView: View {

    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
                    withAnimation(reduceMotion ? nil : .default) {
                        isNavigationHeaderShown = false
                    }
                }
                .onDisappear {
                    withAnimation(reduceMotion ? nil : .default) {
                        isNavigationHeaderShown = true
                    }
                }
            }

            Section {
                copyableDetailRow(title: "Name", detail: serviceType.name)
                copyableDetailRow(title: "Type", detail: serviceType.type)
                TitleDetailStackView(
                    title: "Transport layer",
                    detail: serviceType.transportLayer.string
                )
                copyableDetailRow(title: "Full type", detail: serviceType.fullType)
                if let detail = serviceType.detail, !detail.isEmpty {
                    copyableDetailRow(title: "Details", detail: detail)
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
                                .font(.headline).bold()
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
                                .font(.headline).bold()
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

    // MARK: - Copyable Detail Row

    @ViewBuilder
    private func copyableDetailRow(title: String, detail: String) -> some View {
        TitleDetailStackView(title: title, detail: detail)
            .draggable(detail)
            .accessibilityHint("Long press to copy \(title.lowercased())")
            .contextMenu {
                Button {
                    Clipboard.copy(detail)
                } label: {
                    Label("Copy \(title)", systemImage: "doc.on.doc")
                }
            }
    }
}
