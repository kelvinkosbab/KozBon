//
//  SelectServiceTypeView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourAI
import BonjourCore
import BonjourLocalization
import BonjourModels
import BonjourStorage

#if canImport(UIKit)
import UIKit
#endif

// MARK: - SelectServiceTypeView

struct SelectServiceTypeView: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.preferencesStore) private var preferencesStore
    @Binding var selectedServiceType: BonjourServiceType?
    @State private var viewModel = SelectServiceTypeViewModel()
    @State private var serviceTypeToExplain: BonjourServiceType?

    init(selectedServiceType: Binding<BonjourServiceType?>) {
        self._selectedServiceType = selectedServiceType
    }

    private func select(_ serviceType: BonjourServiceType) {
        withAnimation(reduceMotion ? nil : .default) {
            selectedServiceType = serviceType
        }
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    var body: some View {
        List {
            if let selectedServiceType {
                Section {
                    BlueSectionItemIconTitleDetailView(
                        imageSystemName: selectedServiceType.imageSystemName,
                        title: selectedServiceType.name,
                        detail: selectedServiceType.fullType
                    )
                }
            }

            if !viewModel.filteredCustomServiceTypes.isEmpty {
                Section(String(localized: Strings.Sections.customServiceTypes)) {
                    ForEach(viewModel.filteredCustomServiceTypes, id: \.fullType) { serviceType in
                        row(for: serviceType)
                    }
                }
            }

            if !viewModel.filteredBuiltInServiceTypes.isEmpty {
                Section(String(localized: Strings.Sections.builtinServiceTypes)) {
                    ForEach(viewModel.filteredBuiltInServiceTypes, id: \.fullType) { serviceType in
                        row(for: serviceType)
                    }
                }
            }
        }
        .contentMarginsBasedOnSizeClass()
        .navigationTitle(String(localized: Strings.NavigationTitles.supportedServices))
        .task {
            viewModel.load()
        }
        .searchable(
            text: $viewModel.searchText,
            prompt: String(localized: Strings.Placeholders.search)
        )
        #if os(macOS)
        .frame(minWidth: 480, minHeight: 400)
        #endif
        #if canImport(FoundationModels)
        .modifier(SelectServiceTypeAISheetModifier(serviceTypeToExplain: $serviceTypeToExplain))
        #endif
    }

    // MARK: - Row

    @ViewBuilder
    private func row(for serviceType: BonjourServiceType) -> some View {
        Button {
            select(serviceType)
        } label: {
            TitleDetailStackView(
                title: serviceType.name,
                detail: serviceType.fullType
            ) {
                Image(systemName: selectedServiceType == serviceType ? Iconography.selected : Iconography.unselected)
                    .font(.body).bold()
                    .foregroundStyle(selectedServiceType == serviceType ? Color.kozBonBlue : .secondary)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityLabel(serviceType.name)
        .accessibilityValue(
            selectedServiceType == serviceType
                ? String(localized: Strings.Accessibility.selected)
                : String(localized: Strings.Accessibility.notSelected)
        )
        .accessibilityHint(String(localized: Strings.Accessibility.selectServiceTypeHint))
        .contextMenu {
            #if canImport(FoundationModels)
            if #available(iOS 26, macOS 26, visionOS 26, *) {
                AIContextMenuItems(
                    aiAnalysisEnabled: preferencesStore.aiAnalysisEnabled,
                    action: { serviceTypeToExplain = serviceType }
                )
            }
            #endif
        }
    }
}

// MARK: - AI Sheet Modifier

#if canImport(FoundationModels)

@available(iOS 26, macOS 26, visionOS 26, *)
private struct SelectServiceTypeAISheetAvailable: ViewModifier {
    @Binding var serviceTypeToExplain: BonjourServiceType?

    func body(content: Content) -> some View {
        content
            .sheet(item: $serviceTypeToExplain) { serviceType in
                ServiceExplanationSheet(serviceType: serviceType)
            }
    }
}

struct SelectServiceTypeAISheetModifier: ViewModifier {
    @Binding var serviceTypeToExplain: BonjourServiceType?

    func body(content: Content) -> some View {
        if #available(iOS 26, macOS 26, visionOS 26, *) {
            content.modifier(SelectServiceTypeAISheetAvailable(
                serviceTypeToExplain: $serviceTypeToExplain
            ))
        } else {
            content
        }
    }
}

#endif
