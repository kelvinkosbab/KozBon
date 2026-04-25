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

// MARK: - SupportedServicesView

/// Browsable list of all supported Bonjour service types (built-in and user-created).
///
/// Displays service types in a searchable navigation split view with detail on the trailing side.
/// Supports creating custom service types via a sheet.
public struct SupportedServicesView: View {

    @Environment(\.preferencesStore) private var preferencesStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel = SupportedServicesViewModel()
    @State private var serviceTypeToExplain: BonjourServiceType?

    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    #endif

    public init() {}

    public var body: some View {
        NavigationSplitView {
            List(selection: $viewModel.selectedServiceType) {
                // User-created types appear ABOVE the built-in catalog so
                // the user's own content is the first thing they see.
                serviceTypeSection(
                    title: String(localized: Strings.Sections.customServiceTypes),
                    serviceTypes: viewModel.filteredCustomServiceTypes
                )
                // The "Built-in service types" header is only meaningful
                // when a preceding custom section exists — the header
                // primarily exists to separate *user content* from the
                // system catalog. When there are no custom types, the
                // built-in list is the only section and the header adds
                // no signal, so we pass `nil` and the section renders
                // unlabeled.
                serviceTypeSection(
                    title: viewModel.filteredCustomServiceTypes.isEmpty
                        ? nil
                        : String(localized: Strings.Sections.builtinServiceTypes),
                    serviceTypes: viewModel.filteredBuiltInServiceTypes
                )
            }
            .contentMarginsBasedOnSizeClass()
            #if os(macOS)
            .navigationSplitViewColumnWidth(min: 280, ideal: 320)
            #endif
            .navigationTitle(String(localized: Strings.NavigationTitles.supportedServices))
            .searchable(text: $viewModel.searchText, prompt: String(localized: Strings.Placeholders.search))
            .overlay {
                // When an active category filter narrows the list to
                // zero results we surface a `ContentUnavailableView`
                // instead of an empty list. Search-only emptiness is
                // left to the system's standard "No Results" search
                // overlay (built into `.searchable`), so this only
                // fires for the filter case.
                if viewModel.isFilteredResultEmpty,
                   let category = viewModel.filterCategory,
                   viewModel.searchText.isEmpty {
                    ContentUnavailableView {
                        Label(
                            Strings.Filters.noServicesInCategory(String(localized: category.title)),
                            systemImage: category.iconName
                        )
                    } description: {
                        Text(Strings.Filters.noServicesInCategoryHint)
                    }
                }
            }
            .toolbar {
                ToolbarItem {
                    self.renderFilterMenu()
                }
                ToolbarItem {
                    self.renderCreateMenu()
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

    /// Renders a list section for a group of service types, omitting
    /// the whole section when empty and omitting just the header when
    /// `title` is `nil`.
    ///
    /// A `nil` title is how we render the built-in catalog as an
    /// unlabeled primary list in the no-custom-types case — the
    /// "Built-in service types" header only earns its space when there's
    /// a preceding custom section to differentiate from.
    @ViewBuilder
    private func serviceTypeSection(title: String?, serviceTypes: [BonjourServiceType]) -> some View {
        if !serviceTypes.isEmpty {
            if let title {
                Section {
                    serviceTypeRows(for: serviceTypes)
                } header: {
                    Text(verbatim: title)
                        .accessibilityAddTraits(.isHeader)
                }
            } else {
                Section {
                    serviceTypeRows(for: serviceTypes)
                }
            }
        }
    }

    /// The shared row content used by both the custom and built-in
    /// sections. Extracted so the section body can be rendered inside
    /// either the `Section(content:header:)` or `Section(content:)`
    /// overload without duplicating the row wiring.
    @ViewBuilder
    private func serviceTypeRows(for serviceTypes: [BonjourServiceType]) -> some View {
        ForEach(serviceTypes, id: \.fullType) { serviceType in
            NavigationLink(value: serviceType) {
                TitleDetailStackView(
                    title: serviceType.name,
                    detail: serviceType.fullType
                ) {
                    ServiceTypeBadge(serviceType: serviceType, style: .iconOnly)
                }
            }
            // macOS users expect double-click to open in a new window, the
            // same way Finder, Mail, and Notes work. The right-click
            // "Open in New Window" menu item still exists for
            // discoverability, but this is the muscle-memory shortcut. We
            // attach it as a `.simultaneousGesture` so the single-tap
            // navigation behavior of `NavigationLink` is preserved.
            #if os(macOS)
            .simultaneousGesture(
                TapGesture(count: 2).onEnded {
                    openWindow(value: serviceType)
                }
            )
            #endif
            .draggable(serviceType.fullType)
            .accessibilityLabel("\(serviceType.name), \(serviceType.fullType)")
            .accessibilityHint(Strings.Accessibility.viewDetails(serviceType.name))
            .accessibilityActions {
                Button(Strings.Accessibility.copyField(serviceType.name)) {
                    Clipboard.copy(serviceType.fullType)
                }
            }
            .contextMenu {
                serviceTypeContextMenu(serviceType: serviceType)
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
        if #available(iOS 26, macOS 26, visionOS 26, *) {
            AIContextMenuItems(
                aiAnalysisEnabled: preferencesStore.aiAnalysisEnabled,
                action: { serviceTypeToExplain = serviceType }
            )
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

    private func renderCreateMenu() -> some View {
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
        .accessibilityIdentifier("create_service_type_menu")
    }

    /// Category filter menu — mirrors the filter section of the
    /// Discover tab's combined sort/filter menu, but limited to
    /// just the 5 categories plus an "All categories" reset.
    /// Selecting the active category clears the filter.
    @ViewBuilder
    private func renderFilterMenu() -> some View {
        Menu {
            Button {
                setFilter(nil)
            } label: {
                if viewModel.filterCategory == nil {
                    Label(String(localized: Strings.Filters.allCategories), systemImage: Iconography.selected)
                } else {
                    Text(Strings.Filters.allCategories)
                }
            }

            Divider()

            ForEach(BonjourServiceCategory.allCases) { category in
                Button {
                    // Toggling: tapping the active category clears
                    // it. Otherwise sets it.
                    setFilter(viewModel.filterCategory == category ? nil : category)
                } label: {
                    if viewModel.filterCategory == category {
                        Label(category.title, systemImage: Iconography.selected)
                    } else {
                        Label(category.title, systemImage: category.iconName)
                    }
                }
            }
        } label: {
            Label(String(localized: Strings.Filters.filterByCategory), systemImage: Iconography.filter)
                .tint(.primary)
        }
        .accessibilityLabel(String(localized: Strings.Filters.filterByCategory))
        .accessibilityIdentifier("filter_category_menu")
    }

    /// Wraps `filterCategory` mutation with motion-respecting
    /// animation so list rows animate in/out cleanly when the user
    /// changes the filter.
    private func setFilter(_ category: BonjourServiceCategory?) {
        withAnimation(reduceMotion ? nil : .default) {
            viewModel.filterCategory = category
        }
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
