//
//  SupportedServiceDetailView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourCore
import BonjourLocalization
import BonjourModels

// MARK: - SupportedServiceDetailView

public struct SupportedServiceDetailView: View {

    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(serviceType: BonjourServiceType) {
        self.serviceType = serviceType
    }

    @State private var serviceType: BonjourServiceType
    @State private var showDeleteConfirmation = false
    @State private var showEditConfirmation = false
    @State private var isNavigationHeaderShown = false

    public var body: some View {
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
                copyableDetailRow(
                    title: String(localized: Strings.DetailRows.name),
                    detail: serviceType.name,
                    copyLabel: String(localized: Strings.Actions.copyName)
                )
                copyableDetailRow(
                    title: String(localized: Strings.DetailRows.type),
                    detail: serviceType.type,
                    copyLabel: String(localized: Strings.Actions.copyType)
                )
                TitleDetailStackView(
                    title: String(localized: Strings.DetailRows.transportLayer),
                    detail: serviceType.transportLayer.string
                )
                copyableDetailRow(
                    title: String(localized: Strings.DetailRows.fullType),
                    detail: serviceType.fullType,
                    copyLabel: String(localized: Strings.Actions.copyFullType)
                )
                if let detail = serviceType.localizedDetail, !detail.isEmpty {
                    copyableDetailRow(
                        title: String(localized: Strings.DetailRows.details),
                        detail: detail,
                        copyLabel: String(localized: Strings.Actions.copyDetails)
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
                            Text(Strings.Buttons.edit)
                                .font(.headline).bold()
                                .padding(.vertical)
                            Spacer()
                        }
                    }
                    .accessibilityLabel(Strings.Accessibility.edit(serviceType.name))
                    .accessibilityHint(String(localized: Strings.Accessibility.editHint))
                    .foregroundStyle(.yellow)
                    .sheet(isPresented: $showEditConfirmation) {
                        CreateOrUpdateBonjourServiceTypeView_Edit(
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
                            Text(Strings.Buttons.delete)
                                .font(.headline).bold()
                                .padding(.vertical)
                            Spacer()
                        }
                    }
                    .accessibilityLabel(Strings.Accessibility.delete(serviceType.name))
                    .accessibilityHint(String(localized: Strings.Accessibility.deleteHint))
                    .confirmationDialog(
                        String(localized: Strings.Alerts.deleteServiceType),
                        isPresented: $showDeleteConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button(role: .destructive) {
                            serviceType.deletePersistentCopy()
                            dismiss()
                        } label: {
                            Label(String(localized: Strings.Buttons.delete), systemImage: "minus.circle.fill")
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
    private func copyableDetailRow(title: String, detail: String, copyLabel: String) -> some View {
        TitleDetailStackView(title: title, detail: detail)
            .draggable(detail)
            .accessibilityHint(Strings.Accessibility.longPressToCopy(title.lowercased()))
            .contextMenu {
                Button {
                    Clipboard.copy(detail)
                } label: {
                    Label(copyLabel, systemImage: "doc.on.doc")
                }
            }
    }
}
