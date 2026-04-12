//
//  BonjourServiceDetailView.swift
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

// MARK: - BonjourServiceDetailView

/// Detail view displaying information about a single discovered or published Bonjour service.
///
/// Shows the service name, hostname, type, transport layer, domain, IP addresses,
/// and TXT records. Published services support editing and adding TXT records.
public struct BonjourServiceDetailView: View {

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.preferencesStore) private var preferencesStore

    @State private var viewModel: BonjourServiceDetailViewModel

    /// Creates a detail view for the given Bonjour service.
    ///
    /// - Parameters:
    ///   - service: The Bonjour service to display.
    ///   - isPublished: Whether the service was published by the current user.
    public init(service: BonjourService, isPublished: Bool = false) {
        self._viewModel = State(initialValue: BonjourServiceDetailViewModel(service: service, isPublished: isPublished))
    }

    init(viewModel: BonjourServiceDetailViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        List {
            Section {
                BlueSectionItemIconTitleDetailView(
                    imageSystemName: viewModel.serviceType.imageSystemName,
                    title: viewModel.service.service.name,
                    detail: viewModel.serviceType.name
                )
                .onAppear {
                    withAnimation(reduceMotion ? nil : .default) {
                        viewModel.isNavigationHeaderShown = false
                    }
                }
                .onDisappear {
                    withAnimation(reduceMotion ? nil : .default) {
                        viewModel.isNavigationHeaderShown = true
                    }
                }
            }

            Section(String(localized: Strings.Sections.information)) {
                TitleDetailStackView(
                    title: String(localized: Strings.DetailRows.name),
                    detail: viewModel.serviceType.name
                )
                .accessibilityHint(Strings.Accessibility.longPressToCopy(String(localized: Strings.DetailRows.name)))
                .contextMenu {
                    Button {
                        Clipboard.copy(viewModel.serviceType.name)
                    } label: {
                        Label(String(localized: Strings.Actions.copyName), systemImage: Iconography.copy)
                    }
                }
                TitleDetailStackView(
                    title: String(localized: Strings.DetailRows.hostname),
                    detail: viewModel.service.hostName
                )
                .accessibilityHint(Strings.Accessibility.longPressToCopy(String(localized: Strings.DetailRows.hostname)))
                .contextMenu {
                    Button {
                        Clipboard.copy(viewModel.service.hostName)
                    } label: {
                        Label(String(localized: Strings.Actions.copyHostname), systemImage: Iconography.copy)
                    }
                }
                TitleDetailStackView(
                    title: String(localized: Strings.DetailRows.fullType),
                    detail: viewModel.serviceType.fullType
                )
                .draggable(viewModel.serviceType.fullType)
                .accessibilityHint(Strings.Accessibility.longPressToCopy(String(localized: Strings.DetailRows.fullType)))
                .contextMenu {
                    Button {
                        Clipboard.copy(viewModel.serviceType.fullType)
                    } label: {
                        Label(String(localized: Strings.Actions.copyFullType), systemImage: Iconography.copy)
                    }
                }
                TitleDetailStackView(
                    title: String(localized: Strings.DetailRows.type),
                    detail: viewModel.serviceType.type
                )
                .accessibilityHint(Strings.Accessibility.longPressToCopy(String(localized: Strings.DetailRows.type)))
                .contextMenu {
                    Button {
                        Clipboard.copy(viewModel.serviceType.type)
                    } label: {
                        Label(String(localized: Strings.Actions.copyServiceType), systemImage: Iconography.copy)
                    }
                }
                TitleDetailStackView(
                    title: String(localized: Strings.DetailRows.transportLayer),
                    detail: viewModel.serviceType.transportLayer.string
                )
                TitleDetailStackView(
                    title: String(localized: Strings.DetailRows.domain),
                    detail: viewModel.service.service.domain
                )
                if let detail = viewModel.serviceType.localizedDetail {
                    TitleDetailStackView(
                        title: String(localized: Strings.DetailRows.protocolInformation),
                        detail: detail
                    )
                    .contextMenu {
                        #if canImport(FoundationModels)
                        if preferencesStore.aiAnalysisEnabled,
                           #available(iOS 26, macOS 26, visionOS 26, *),
                           SystemLanguageModel.default.isAvailable {
                            Button {
                                viewModel.isAIExplanationPresented = true
                            } label: {
                                Label(String(localized: Strings.AIInsights.explainWithAI), systemImage: Iconography.appleIntelligence)
                            }
                        }
                        #endif
                    }
                    .accessibilityHint(Strings.Accessibility.longPressToCopy(String(localized: Strings.DetailRows.protocolInformation)))
                }
            }

            if !viewModel.service.addresses.isEmpty {
                Section(String(localized: Strings.Sections.ipAddresses)) {
                    ForEach(viewModel.service.addresses, id: \.ipPortString) { address in
                        TitleDetailStackView(
                            title: address.ipPortString,
                            detail: address.protocol.stringRepresentation
                        )
                        .draggable(address.ipPortString)
                        .accessibilityHint(String(localized: Strings.Accessibility.longPressCopyAddress))
                        .contextMenu {
                            Button {
                                Clipboard.copy(address.ipPortString)
                            } label: {
                                Label(String(localized: Strings.Actions.copyAddress), systemImage: Iconography.copy)
                            }
                        }
                    }
                }
            }

            txtRecordsSection()
        }
        .contentMarginsBasedOnSizeClass()
        .navigationTitle(viewModel.service.service.name)
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            viewModel.service.resolve()
        }
        .toolbar {
            if viewModel.isNavigationHeaderShown {
                ToolbarItem(
                    placement: horizontalSizeClass == .compact ? .principal : .confirmationAction
                ) {
                    ServiceTypeBadge(serviceType: viewModel.serviceType, style: .basedOnSizeClass)
                }
            }
        }
        .sheet(
            isPresented: Binding(
                get: { viewModel.isCreateTxtRecordPresented },
                set: { viewModel.isCreateTxtRecordPresented = $0 }
            ),
            onDismiss: {
                viewModel.didFinishEditingTxtRecords()
            },
            content: {
                TxtRecordEditSheet(viewModel: viewModel)
            }
        )
        #if canImport(FoundationModels)
        .modifier(AIExplanationSheetModifier(viewModel: viewModel))
        #endif
    }

    // MARK: - TXT Records Section

    @ViewBuilder
    // swiftlint:disable:next function_body_length
    private func txtRecordsSection() -> some View {
        if viewModel.isPublished {
            Section(String(localized: Strings.Sections.txtRecords)) {
                ForEach(viewModel.dataRecords, id: \.key) { dataRecord in
                    Button {
                        viewModel.txtRecordToEdit = dataRecord
                        viewModel.isCreateTxtRecordPresented = true
                    } label: {
                        TitleDetailStackView(
                            title: dataRecord.key,
                            detail: dataRecord.value
                        )
                    }
                    .draggable("\(dataRecord.key)=\(dataRecord.value)")
                    .accessibilityHint(String(localized: Strings.Accessibility.editRecordHint))
                    .contextMenu {
                        Button {
                            Clipboard.copy("\(dataRecord.key)=\(dataRecord.value)")
                        } label: {
                            Label(String(localized: Strings.Actions.copyRecord), systemImage: Iconography.copy)
                        }

                        Button {
                            Clipboard.copy(dataRecord.value)
                        } label: {
                            Label(String(localized: Strings.Actions.copyValue), systemImage: Iconography.copyAlternate)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            viewModel.deleteTxtRecord(dataRecord)
                        } label: {
                            Label(String(localized: Strings.Buttons.remove), systemImage: Iconography.remove)
                        }
                        .accessibilityLabel(Strings.Accessibility.remove(dataRecord.key))
                        .tint(.red)
                    }
                }

                Button {
                    viewModel.txtRecordToEdit = nil
                    viewModel.isCreateTxtRecordPresented = true
                } label: {
                    Label(String(localized: Strings.Buttons.addTxtRecord), systemImage: Iconography.add)
                }
                .accessibilityHint(String(localized: Strings.Accessibility.addTxtRecordHint))
            }
        } else if !viewModel.dataRecords.isEmpty {
            Section(String(localized: Strings.Sections.txtRecords)) {
                ForEach(viewModel.dataRecords, id: \.key) { dataRecord in
                    TitleDetailStackView(
                        title: dataRecord.key,
                        detail: dataRecord.value
                    )
                    .draggable("\(dataRecord.key)=\(dataRecord.value)")
                    .accessibilityHint(String(localized: Strings.Accessibility.longPressCopyRecord))
                    .contextMenu {
                        Button {
                            Clipboard.copy("\(dataRecord.key)=\(dataRecord.value)")
                        } label: {
                            Label(String(localized: Strings.Actions.copyRecord), systemImage: Iconography.copy)
                        }

                        Button {
                            Clipboard.copy(dataRecord.value)
                        } label: {
                            Label(String(localized: Strings.Actions.copyValue), systemImage: Iconography.copyAlternate)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - AI Explanation Sheet Modifier

#if canImport(FoundationModels)

@available(iOS 26, macOS 26, visionOS 26, *)
private struct AIExplanationSheetAvailable: ViewModifier {
    @Bindable var viewModel: BonjourServiceDetailViewModel

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $viewModel.isAIExplanationPresented) {
                ServiceExplanationSheet(service: viewModel.service)
            }
    }
}

struct AIExplanationSheetModifier: ViewModifier {
    let viewModel: BonjourServiceDetailViewModel

    func body(content: Content) -> some View {
        if #available(iOS 26, macOS 26, visionOS 26, *) {
            content
                .modifier(AIExplanationSheetAvailable(viewModel: viewModel))
        } else {
            content
        }
    }
}
#endif
