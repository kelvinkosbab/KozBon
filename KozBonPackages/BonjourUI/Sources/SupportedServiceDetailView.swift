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
import BonjourAI
import BonjourStorage

#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - SupportedServiceDetailView

/// Detail view for a supported Bonjour service type, showing its name, type string,
/// transport layer, and description. Custom (non-built-in) types can be edited or deleted.
public struct SupportedServiceDetailView: View {

    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.preferencesStore) private var preferencesStore

    /// Creates a detail view for the given service type.
    ///
    /// - Parameter serviceType: The Bonjour service type to display.
    public init(serviceType: BonjourServiceType) {
        self.serviceType = serviceType
    }

    @State private var serviceType: BonjourServiceType
    @State private var showDeleteConfirmation = false
    @State private var showEditConfirmation = false
    @State private var isNavigationHeaderShown = false
    @State private var isAIExplanationPresented = false

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
                TitleDetailStackView(
                    title: String(localized: Strings.DetailRows.fullType),
                    detail: serviceType.fullType
                )
                .draggable(serviceType.fullType)
                .accessibilityHint(Strings.Accessibility.longPressToCopy(
                    String(localized: Strings.DetailRows.fullType).lowercased()
                ))
                .contextMenu {
                    Button {
                        Clipboard.copy(serviceType.fullType)
                    } label: {
                        Label(
                            String(localized: Strings.Actions.copyFullType),
                            systemImage: Iconography.copy
                        )
                    }

                    #if canImport(FoundationModels)
                    if preferencesStore.aiAnalysisEnabled,
                       #available(iOS 26, macOS 26, visionOS 26, *),
                       SystemLanguageModel.default.isAvailable {
                        Divider()

                        Button {
                            isAIExplanationPresented = true
                        } label: {
                            Label(
                                String(localized: Strings.AIInsights.explainWithAI),
                                systemImage: Iconography.appleIntelligence
                            )
                        }
                    }
                    #endif
                }
                .accessibilityActions {
                    Button(Strings.Accessibility.copyField(String(localized: Strings.DetailRows.fullType).lowercased())) {
                        Clipboard.copy(serviceType.fullType)
                    }
                }
                if let detail = serviceType.localizedDetail, !detail.isEmpty {
                    TitleDetailStackView(
                        title: String(localized: Strings.DetailRows.details),
                        detail: detail
                    )
                    .draggable(detail)
                    .accessibilityHint(Strings.Accessibility.longPressToCopy(
                        String(localized: Strings.DetailRows.details).lowercased()
                    ))
                    .contextMenu {
                        Button {
                            Clipboard.copy(detail)
                        } label: {
                            Label(
                                String(localized: Strings.Actions.copyDetails),
                                systemImage: Iconography.copy
                            )
                        }

                        #if canImport(FoundationModels)
                        if preferencesStore.aiAnalysisEnabled,
                           #available(iOS 26, macOS 26, visionOS 26, *),
                           SystemLanguageModel.default.isAvailable {
                            Divider()

                            Button {
                                isAIExplanationPresented = true
                            } label: {
                                Label(
                                    String(localized: Strings.AIInsights.explainWithAI),
                                    systemImage: Iconography.appleIntelligence
                                )
                            }
                        }
                        #endif
                    }
                    .accessibilityActions {
                        Button(Strings.Accessibility.copyField(String(localized: Strings.DetailRows.details).lowercased())) {
                            Clipboard.copy(detail)
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
                            Label(String(localized: Strings.Buttons.delete), systemImage: Iconography.remove)
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
        .navigationTitle(serviceType.name)
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
        #if canImport(FoundationModels)
        .modifier(AIServiceTypeSheetModifier(
            serviceType: serviceType,
            isPresented: $isAIExplanationPresented
        ))
        #endif
    }

    // MARK: - Copyable Detail Row

    @ViewBuilder
    private func copyableDetailRow(title: String, detail: String, copyLabel: String) -> some View {
        TitleDetailStackView(title: title, detail: detail)
            .draggable(detail)
            .accessibilityLabel("\(title), \(detail)")
            .accessibilityHint(Strings.Accessibility.longPressToCopy(title.lowercased()))
            .accessibilityActions {
                Button(Strings.Accessibility.copyField(title.lowercased())) {
                    Clipboard.copy(detail)
                }
            }
            .contextMenu {
                Button {
                    Clipboard.copy(detail)
                } label: {
                    Label(copyLabel, systemImage: Iconography.copy)
                }
            }
    }
}

// MARK: - AI Service Type Sheet Modifier

#if canImport(FoundationModels)

@available(iOS 26, macOS 26, visionOS 26, *)
private struct AIServiceTypeSheetAvailable: ViewModifier {
    let serviceType: BonjourServiceType
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                ServiceExplanationSheet(serviceType: serviceType)
            }
    }
}

struct AIServiceTypeSheetModifier: ViewModifier {
    let serviceType: BonjourServiceType
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26, macOS 26, visionOS 26, *) {
            content.modifier(AIServiceTypeSheetAvailable(
                serviceType: serviceType,
                isPresented: $isPresented
            ))
        } else {
            content
        }
    }
}

#endif
