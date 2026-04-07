//
//  SelectServiceTypeView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourCore
import BonjourLocalization
import BonjourModels

// MARK: - SelectServiceTypeView

struct SelectServiceTypeView: View {

    @Binding var selectedServiceType: BonjourServiceType?
    @State private var viewModel = SelectServiceTypeViewModel()

    init(selectedServiceType: Binding<BonjourServiceType?>) {
        self._selectedServiceType = selectedServiceType
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
                        Button {
                            Task { @MainActor in
                                withAnimation {
                                    selectedServiceType = serviceType
                                }
                            }
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
                        .accessibilityValue(selectedServiceType == serviceType ? String(localized: Strings.Accessibility.selected) : String(localized: Strings.Accessibility.notSelected))
                        .accessibilityHint(String(localized: Strings.Accessibility.selectServiceTypeHint))
                    }
                }
            }

            if !viewModel.filteredBuiltInServiceTypes.isEmpty {
                Section(String(localized: Strings.Sections.builtinServiceTypes)) {
                    ForEach(viewModel.filteredBuiltInServiceTypes, id: \.fullType) { serviceType in
                        Button {
                            Task { @MainActor in
                                withAnimation {
                                    selectedServiceType = serviceType
                                }
                            }
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
                        .accessibilityValue(selectedServiceType == serviceType ? String(localized: Strings.Accessibility.selected) : String(localized: Strings.Accessibility.notSelected))
                        .accessibilityHint(String(localized: Strings.Accessibility.selectServiceTypeHint))
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
    }
}
