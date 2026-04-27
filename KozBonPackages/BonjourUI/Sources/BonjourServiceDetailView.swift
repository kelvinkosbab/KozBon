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

// MARK: - BonjourServiceDetailView

/// Detail view displaying information about a single discovered or published Bonjour service.
///
/// Shows the service name, hostname, type, transport layer, domain, IP addresses,
/// and TXT records. Published services support editing and adding TXT records.
public struct BonjourServiceDetailView: View {

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.preferencesStore) private var preferencesStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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
                .accessibilityActions {
                    Button(Strings.Accessibility.copyField(String(localized: Strings.DetailRows.name))) {
                        Clipboard.copy(viewModel.serviceType.name)
                    }
                }
                deviceIdentityRows()
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
                .accessibilityActions {
                    Button(Strings.Accessibility.copyField(String(localized: Strings.DetailRows.fullType))) {
                        Clipboard.copy(viewModel.serviceType.fullType)
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
                .accessibilityActions {
                    Button(Strings.Accessibility.copyField(String(localized: Strings.DetailRows.type))) {
                        Clipboard.copy(viewModel.serviceType.type)
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
                        if #available(iOS 26, macOS 26, visionOS 26, *) {
                            AIContextMenuItems(
                                aiAnalysisEnabled: preferencesStore.aiAnalysisEnabled,
                                action: { viewModel.isAIExplanationPresented = true }
                            )
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
                        .accessibilityLabel("\(address.ipPortString), \(address.protocol.stringRepresentation)")
                        .accessibilityHint(String(localized: Strings.Accessibility.longPressCopyAddress))
                        .contextMenu {
                            Button {
                                Clipboard.copy(address.ipPortString)
                            } label: {
                                Label(String(localized: Strings.Actions.copyAddress), systemImage: Iconography.copy)
                            }
                        }
                        .accessibilityActions {
                            Button(String(localized: Strings.Actions.copyAddress)) {
                                Clipboard.copy(address.ipPortString)
                            }
                        }
                    }
                }
            }

            txtRecordsSection()
        }
        .accessibilityIdentifier("service_detail_list")
        .contentMarginsBasedOnSizeClass()
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
                    ServiceTypeBadge(
                        serviceType: viewModel.serviceType,
                        style: .basedOnSizeClass,
                        size: .compact
                    )
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
    private func txtRecordsSection() -> some View {
        if viewModel.isPublished {
            editableTxtRecordsSection()
        } else if !viewModel.dataRecords.isEmpty {
            readOnlyTxtRecordsSection()
        }
    }

    @ViewBuilder
    private func editableTxtRecordsSection() -> some View {
        Section(String(localized: Strings.Sections.txtRecords)) {
            ForEach(viewModel.dataRecords, id: \.key) { dataRecord in
                editableTxtRecordRow(dataRecord)
            }

            Button {
                viewModel.txtRecordToEdit = nil
                viewModel.isCreateTxtRecordPresented = true
            } label: {
                Label(String(localized: Strings.Buttons.addTxtRecord), systemImage: Iconography.add)
            }
            .accessibilityHint(String(localized: Strings.Accessibility.addTxtRecordHint))
            .accessibilityIdentifier("txt_record_add_button")
        }
    }

    @ViewBuilder
    private func editableTxtRecordRow(_ dataRecord: BonjourService.TxtDataRecord) -> some View {
        Button {
            viewModel.txtRecordToEdit = dataRecord
            viewModel.isCreateTxtRecordPresented = true
        } label: {
            TitleDetailStackView(title: dataRecord.key, detail: dataRecord.value)
        }
        .draggable("\(dataRecord.key)=\(dataRecord.value)")
        .accessibilityLabel("\(dataRecord.key): \(dataRecord.value)")
        .accessibilityHint(String(localized: Strings.Accessibility.editRecordHint))
        .accessibilityActions {
            Button(String(localized: Strings.Accessibility.copyRecord)) {
                Clipboard.copy("\(dataRecord.key)=\(dataRecord.value)")
            }
            Button(String(localized: Strings.Accessibility.copyValueOnly)) {
                Clipboard.copy(dataRecord.value)
            }
            Button(String(localized: Strings.Accessibility.editRecord)) {
                viewModel.txtRecordToEdit = dataRecord
                viewModel.isCreateTxtRecordPresented = true
            }
            Button(String(localized: Strings.Accessibility.deleteRecord), role: .destructive) {
                viewModel.deleteTxtRecord(dataRecord)
            }
        }
        .contextMenu { copyRecordContextMenu(for: dataRecord) }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                viewModel.deleteTxtRecord(dataRecord)
            } label: {
                Label(String(localized: Strings.Buttons.remove), systemImage: Iconography.remove)
            }
            .accessibilityLabel(Strings.Accessibility.remove(dataRecord.key))
            .accessibilityHint(String(localized: Strings.Accessibility.deleteTxtRecordHint))
            .tint(.red)
        }
    }

    @ViewBuilder
    private func readOnlyTxtRecordsSection() -> some View {
        Section(String(localized: Strings.Sections.txtRecords)) {
            ForEach(viewModel.dataRecords, id: \.key) { dataRecord in
                TitleDetailStackView(title: dataRecord.key, detail: dataRecord.value)
                    .draggable("\(dataRecord.key)=\(dataRecord.value)")
                    .accessibilityLabel("\(dataRecord.key): \(dataRecord.value)")
                    .accessibilityHint(String(localized: Strings.Accessibility.longPressCopyRecord))
                    .accessibilityActions {
                        Button(String(localized: Strings.Accessibility.copyRecord)) {
                            Clipboard.copy("\(dataRecord.key)=\(dataRecord.value)")
                        }
                        Button(String(localized: Strings.Accessibility.copyValueOnly)) {
                            Clipboard.copy(dataRecord.value)
                        }
                    }
                    .contextMenu { copyRecordContextMenu(for: dataRecord) }
            }
        }
    }

    /// Shared "Copy record / Copy value" context menu used by both editable
    /// and read-only TXT record rows. Centralized here so the two sections
    /// stay in sync if the menu evolves.
    @ViewBuilder
    private func copyRecordContextMenu(for dataRecord: BonjourService.TxtDataRecord) -> some View {
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

// MARK: - Device Identity Rows
//
// Lives in an extension so the rows don't bloat
// `BonjourServiceDetailView`'s primary type body past SwiftLint's
// `type_body_length` floor. Same-file extensions can still reach
// the struct's `private` state (`viewModel`), so visibility is
// preserved.

private extension BonjourServiceDetailView {

    /// Surfaces three rows that together answer "who is this":
    /// the user-given device name (always), the deduced Apple model
    /// when one is recognized, and the DNS hostname (always).
    @ViewBuilder
    func deviceIdentityRows() -> some View {
        // Service Name — `NetService.name`. On Apple devices this is
        // usually the user-given device name from Settings → About →
        // Name (e.g., "Kelvin's iPhone"), but for some service types
        // it's a UUID- or MAC-flavored identifier — hence the
        // technically-honest "Service Name" label rather than
        // "Device Name".
        TitleDetailStackView(
            title: String(localized: Strings.DetailRows.serviceName),
            detail: viewModel.service.service.name
        )
        .accessibilityHint(Strings.Accessibility.longPressToCopy(String(localized: Strings.DetailRows.serviceName)))
        .contextMenu {
            Button {
                Clipboard.copy(viewModel.service.service.name)
            } label: {
                Label(String(localized: Strings.Actions.copyName), systemImage: Iconography.copy)
            }
        }
        .accessibilityActions {
            Button(Strings.Accessibility.copyField(String(localized: Strings.DetailRows.serviceName))) {
                Clipboard.copy(viewModel.service.service.name)
            }
        }

        // Device Type — only when `BonjourDeviceIdentifier` resolves
        // a device. Covers Apple models (high-confidence TXT lookup),
        // device families from hostnames (medium-confidence —
        // including non-Apple vendors like Sonos, Roku, Synology),
        // and DNS-SD service-type fallbacks (low-confidence, e.g.
        // `_ipp._tcp` → "Printer"). Hidden when no strategy matches
        // so the row doesn't render with an empty or unhelpful value.
        if let identification = BonjourDeviceIdentifier.identify(service: viewModel.service) {
            TitleDetailStackView(
                title: String(localized: Strings.DetailRows.deviceType),
                detail: identification.friendlyName
            )
            .accessibilityHint(Strings.Accessibility.longPressToCopy(String(localized: Strings.DetailRows.deviceType)))
            .contextMenu {
                Button {
                    Clipboard.copy(identification.friendlyName)
                } label: {
                    Label(String(localized: Strings.Actions.copyName), systemImage: Iconography.copy)
                }
            }
            .accessibilityActions {
                Button(Strings.Accessibility.copyField(String(localized: Strings.DetailRows.deviceType))) {
                    Clipboard.copy(identification.friendlyName)
                }
            }
        }

        // Hostname — the device's DNS name. Often less readable than
        // the device-name and device-type rows above, but kept for
        // power users who want the raw `hostname.local.` string for
        // direct DNS / SSH workflows.
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
        .accessibilityActions {
            Button(Strings.Accessibility.copyField(String(localized: Strings.DetailRows.hostname))) {
                Clipboard.copy(viewModel.service.hostName)
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
                ServiceExplanationSheet(service: viewModel.service, isPublished: viewModel.isPublished)
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
