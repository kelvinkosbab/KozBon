//
//  BonjourScanForServicesView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourCore
import BonjourLocalization
import BonjourModels
import BonjourAI
import BonjourScanning
import BonjourStorage

#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - BonjourScanForServicesView

/// The main view for discovering and listing nearby Bonjour services on the local network.
///
/// Displays a navigation split view with discovered services on the leading side and
/// service details on the trailing side. Supports pull-to-refresh, sorting, and broadcasting
/// new services.
///
/// - Parameter dependencies: The dependency container providing scanner and publish manager.
public struct BonjourScanForServicesView: View {

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.preferencesStore) private var preferencesStore
    @State private var viewModel: BonjourServicesViewModel
    @State private var serviceToExplain: BonjourService?

    @MainActor
    public init(dependencies: DependencyContainer) {
        _viewModel = State(initialValue: BonjourServicesViewModel(
            serviceScanner: dependencies.bonjourServiceScanner,
            publishManager: dependencies.bonjourPublishManager
        ))
    }

    public var body: some View {
        NavigationSplitView {
            List(selection: $viewModel.selectedService) {
                if !viewModel.sortedPublishedServices.isEmpty {
                    Section {
                        forEach(services: viewModel.sortedPublishedServices)
                    } header: {
                        Text(Strings.Sections.published)
                            .font(.caption)
                            .accessibilityAddTraits(.isHeader)
                    }
                }

                if !viewModel.flatActiveServices.isEmpty {
                    Section {
                        forEach(services: viewModel.flatActiveServices)
                    }
                }
            }
            .contentMarginsBasedOnSizeClass()
            #if os(macOS)
            .navigationSplitViewColumnWidth(min: 280, ideal: 320)
            #endif
            .overlay {
                if viewModel.isInitialLoad {
                    ProgressView {
                        Text(Strings.Buttons.scanningForServices)
                    }
                } else if viewModel.flatActiveServices.isEmpty,
                          let sortType = viewModel.sortType, sortType.isFilter {
                    ContentUnavailableView(
                        Strings.EmptyStates.noFilteredServices(sortType.title),
                        systemImage: sortType.iconName
                    )
                } else if viewModel.flatActiveServices.isEmpty {
                    EmptyStateOverlayView(
                        image: nil,
                        title: self.viewModel.noActiveServicesString,
                        actionTitle: String(localized: Strings.Buttons.startScanning),
                        action: { viewModel.load() }
                    )
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    BonjourServiceListSortMenu(sortType: self.$viewModel.sortType)

                    Button {
                        viewModel.isBroadcastBonjourServicePresented = true
                    } label: {
                        Label(String(localized: Strings.Buttons.broadcast), systemImage: Iconography.antenna)
                    }
                    .accessibilityLabel(String(localized: Strings.Accessibility.create))
                    .accessibilityHint(String(localized: Strings.Accessibility.createHint))
                }
            }
            .navigationTitle(String(localized: Strings.NavigationTitles.nearbyServices))
            .refreshable {
                guard !self.viewModel.serviceScanner.isProcessing else {
                    return
                }

                self.viewModel.load()
            }
        } detail: {
            if let selectedService = viewModel.selectedService {
                BonjourServiceDetailView(
                    service: selectedService,
                    isPublished: viewModel.isPublishedService(selectedService)
                )
                .id(selectedService.id)
            } else {
                ContentUnavailableView(
                    String(localized: Strings.EmptyStates.selectService),
                    systemImage: Iconography.antenna,
                    description: Text(Strings.EmptyStates.selectServiceDescription)
                )
            }
        }
        .task {
            if viewModel.isInitialLoad {
                // Apply persisted sort order on first load
                if viewModel.sortType == nil, !preferencesStore.defaultSortOrder.isEmpty {
                    let stored = BonjourServiceSortType.allCases.first {
                        $0.id == preferencesStore.defaultSortOrder
                    }
                    if let stored {
                        viewModel.sort(sortType: stored)
                    }
                }
                viewModel.load()
            }
        }
        .onDisappear {
            viewModel.serviceScanner.stopScan()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                if viewModel.shouldRefreshOnForeground() {
                    viewModel.load()
                }
            case .background:
                viewModel.serviceScanner.stopScan()
            default:
                break
            }
        }
        .alert(
            String(localized: Strings.Alerts.scanError),
            isPresented: Binding(
                get: { viewModel.scanError != nil },
                set: { if !$0 { viewModel.scanError = nil } }
            )
        ) {
            Button(String(localized: Strings.Buttons.ok)) { viewModel.scanError = nil }
        } message: {
            Text(viewModel.scanError ?? "")
        }
        .sheet(isPresented: $viewModel.isBroadcastBonjourServicePresented) {
            NavigationStack {
                BroadcastBonjourServiceView(
                    isPresented: $viewModel.isBroadcastBonjourServicePresented,
                    customPublishedServices: $viewModel.customPublishedServices
                )
            }
        }
        .focusedSceneValue(\.isBroadcastServicePresented, $viewModel.isBroadcastBonjourServicePresented)
        .focusedSceneValue(\.refreshScan, { [viewModel] in viewModel.load() })
        #if canImport(FoundationModels)
        .modifier(AIServiceExplanationSheetModifier(serviceToExplain: $serviceToExplain))
        #endif
    }

    @ViewBuilder
    private func forEach(services: [BonjourService]) -> some View {
        ForEach(services) { service in
            TitleDetailStackView(
                title: service.service.name,
                detail: service.serviceType.name
            ) {
                ServiceTypeBadge(serviceType: service.serviceType, style: .iconOnly)
            }
            .tag(service)
            .draggable(service.hostName)
            .accessibilityHint(Strings.Accessibility.viewDetails(service.service.name))
            .accessibilityActions {
                Button(Strings.Accessibility.copyField(service.hostName)) {
                    Clipboard.copy(service.hostName)
                }
            }
            .contextMenu {
                Button {
                    Clipboard.copy(service.hostName)
                } label: {
                    Label(String(localized: Strings.Actions.copyHostname), systemImage: Iconography.copy)
                }

                Button {
                    Clipboard.copy(service.serviceType.name)
                } label: {
                    Label(String(localized: Strings.Actions.copyName), systemImage: Iconography.copy)
                }

                Button {
                    Clipboard.copy(service.serviceType.fullType)
                } label: {
                    Label(String(localized: Strings.Actions.copyServiceType), systemImage: Iconography.copyAlternate)
                }

                if !service.addresses.isEmpty {
                    Divider()

                    ForEach(service.addresses, id: \.ipPortString) { address in
                        Button {
                            Clipboard.copy(address.ipPortString)
                        } label: {
                            Label(address.ipPortString, systemImage: Iconography.network)
                        }
                    }
                }

                #if canImport(FoundationModels)
                if preferencesStore.aiAnalysisEnabled,
                   #available(iOS 26, macOS 26, visionOS 26, *),
                   SystemLanguageModel.default.isAvailable {
                    Divider()

                    Button {
                        serviceToExplain = service
                    } label: {
                        Label(String(localized: Strings.AIInsights.explainWithAI), systemImage: Iconography.appleIntelligence)
                    }
                }
                #endif
            }
        }
    }

}

// MARK: - AI Service Explanation Sheet Modifier

#if canImport(FoundationModels)

@available(iOS 26, macOS 26, visionOS 26, *)
private struct AIServiceExplanationSheetAvailable: ViewModifier {
    @Binding var serviceToExplain: BonjourService?

    func body(content: Content) -> some View {
        content
            .sheet(item: $serviceToExplain) { service in
                ServiceExplanationSheet(service: service)
            }
    }
}

struct AIServiceExplanationSheetModifier: ViewModifier {
    @Binding var serviceToExplain: BonjourService?

    func body(content: Content) -> some View {
        if #available(iOS 26, macOS 26, visionOS 26, *) {
            content
                .modifier(AIServiceExplanationSheetAvailable(serviceToExplain: $serviceToExplain))
        } else {
            content
        }
    }
}
#endif
