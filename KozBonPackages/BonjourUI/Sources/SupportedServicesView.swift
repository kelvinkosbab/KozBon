//
//  SupportedServicesView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import CoreUI
import SwiftUI
import BonjourCore
import BonjourLocalization
import BonjourModels
import BonjourAI
import BonjourStorage

#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - SupportedServicesView

/// Browsable list of all supported Bonjour service types (built-in and user-created).
///
/// Displays service types in a searchable navigation split view with detail on the trailing side.
/// Supports creating custom service types via a sheet.
public struct SupportedServicesView: View {

    @Environment(\.preferencesStore) private var preferencesStore
    @State private var viewModel = SupportedServicesViewModel()
    @State private var serviceTypeToExplain: BonjourServiceType?

    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    #endif

    public init() {}

    public var body: some View {
        NavigationSplitView {
            List(selection: $viewModel.selectedServiceType) {
                serviceTypeSection(
                    title: String(localized: Strings.Sections.customServiceTypes),
                    serviceTypes: viewModel.filteredCustomServiceTypes
                )
                serviceTypeSection(
                    title: String(localized: Strings.Sections.builtinServiceTypes),
                    serviceTypes: viewModel.filteredBuiltInServiceTypes
                )
            }
            .contentMarginsBasedOnSizeClass()
            #if os(macOS)
            .navigationSplitViewColumnWidth(min: 280, ideal: 320)
            #endif
            .navigationTitle(String(localized: Strings.NavigationTitles.supportedServices))
            .searchable(text: $viewModel.searchText, prompt: String(localized: Strings.Placeholders.search))
            .toolbar {
                ToolbarItem {
                    self.renderTrailingToolbarItems()
                }
            }
        } detail: {
            if let selectedServiceType = viewModel.selectedServiceType {
                SupportedServiceDetailView(serviceType: selectedServiceType)
                    .id(selectedServiceType.fullType)
            } else {
                ContentUnavailableView(
                    String(localized: Strings.EmptyStates.selectServiceType),
                    systemImage: Iconography.list,
                    description: Text(Strings.EmptyStates.selectServiceTypeDescription)
                )
            }
        }
        .task {
            viewModel.load()
        }
        .sheet(isPresented: $viewModel.isCreateCustomServiceTypePresented) {
            CreateOrUpdateBonjourServiceTypeView(isPresented: $viewModel.isCreateCustomServiceTypePresented)
        }
        #if canImport(FoundationModels)
        .modifier(AIServiceTypeListSheetModifier(serviceTypeToExplain: $serviceTypeToExplain))
        #endif
        .focusedSceneValue(\.isCreateServiceTypePresented, $viewModel.isCreateCustomServiceTypePresented)
    }

    @ViewBuilder
    private func serviceTypeSection(title: String, serviceTypes: [BonjourServiceType]) -> some View {
        if !serviceTypes.isEmpty {
            Section(title) {
                ForEach(serviceTypes, id: \.fullType) { serviceType in
                    NavigationLink(value: serviceType) {
                        TitleDetailStackView(
                            title: serviceType.name,
                            detail: serviceType.fullType
                        ) {
                            ServiceTypeBadge(serviceType: serviceType, style: .iconOnly)
                        }
                    }
                    .draggable(serviceType.fullType)
                    .accessibilityHint(Strings.Accessibility.viewDetails(serviceType.name))
                    .contextMenu {
                        serviceTypeContextMenu(serviceType: serviceType)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func serviceTypeContextMenu(serviceType: BonjourServiceType) -> some View {
        Button {
            Clipboard.copy(serviceType.fullType)
        } label: {
            Label(String(localized: Strings.Actions.copyFullType), systemImage: Iconography.copy)
        }

        Button {
            Clipboard.copy(serviceType.name)
        } label: {
            Label(String(localized: Strings.Actions.copyName), systemImage: Iconography.copyAlternate)
        }

        if let detail = serviceType.localizedDetail {
            Button {
                Clipboard.copy(detail)
            } label: {
                Label(String(localized: Strings.Actions.copyDetails), systemImage: Iconography.info)
            }
        }

        #if canImport(FoundationModels)
        if preferencesStore.aiAnalysisEnabled,
           #available(iOS 26, macOS 26, visionOS 26, *),
           SystemLanguageModel.default.isAvailable {
            Divider()

            Button {
                serviceTypeToExplain = serviceType
            } label: {
                Label(String(localized: Strings.AIInsights.explainWithAI), systemImage: Iconography.appleIntelligence)
            }
        }
        #endif

        #if os(macOS)
        Divider()

        Button {
            openWindow(value: serviceType)
        } label: {
            Label(String(localized: Strings.Actions.openNewWindow), systemImage: Iconography.openInNewWindow)
        }
        #endif
    }

    private func renderTrailingToolbarItems() -> some View {
        Menu {
            Button {
                viewModel.isCreateCustomServiceTypePresented = true
            } label: {
                Label(String(localized: Strings.Buttons.createCustomServiceType), systemImage: Iconography.createServiceType)
            }
        } label: {
            Label(String(localized: Strings.Buttons.create), systemImage: Iconography.add)
                .tint(.primary)
        }
        .accessibilityLabel(String(localized: Strings.Accessibility.create))
        .accessibilityHint(String(localized: Strings.Accessibility.createServiceTypeHint))
    }
}

// MARK: - AI Service Type List Sheet Modifier

#if canImport(FoundationModels)

@available(iOS 26, macOS 26, visionOS 26, *)
private struct AIServiceTypeListSheetAvailable: ViewModifier {
    @Binding var serviceTypeToExplain: BonjourServiceType?

    func body(content: Content) -> some View {
        content
            .sheet(item: $serviceTypeToExplain) { serviceType in
                ServiceExplanationSheet(serviceType: serviceType)
            }
    }
}

struct AIServiceTypeListSheetModifier: ViewModifier {
    @Binding var serviceTypeToExplain: BonjourServiceType?

    func body(content: Content) -> some View {
        if #available(iOS 26, macOS 26, visionOS 26, *) {
            content.modifier(AIServiceTypeListSheetAvailable(
                serviceTypeToExplain: $serviceTypeToExplain
            ))
        } else {
            content
        }
    }
}

#endif
