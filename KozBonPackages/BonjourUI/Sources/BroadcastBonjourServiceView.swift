//
//  BroadcastBonjourServiceView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourAI
import BonjourCore
import BonjourLocalization
import BonjourModels
import BonjourScanning
import BonjourStorage

// MARK: - BroadcastBonjourServiceView

// swiftlint:disable:next type_body_length
struct BroadcastBonjourServiceView: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dependencies) private var dependencies
    @Environment(\.preferencesStore) private var preferencesStore

    @Binding private var isPresented: Bool
    @Binding private var customPublishedServices: [BonjourService]
    private var serviceToUpdate: BonjourService

    @State private var serviceType: BonjourServiceType?
    @State private var serviceTypeError: String?
    @State private var port: Int?
    @State private var portError: String?
    @State private var domain: String = Constants.Network.defaultDomain
    @State private var dataRecords: [BonjourService.TxtDataRecord]
    @State private var domainError: String?
    @State private var isCreateTxtRecordViewPresented = false

    /// Drives the Apple Intelligence Insights sheet from the
    /// service-type row's long-press menu.
    @State private var serviceTypeToExplain: BonjourServiceType?

    /// Whether the form has valid inputs for broadcasting a service.
    private var isFormValid: Bool {
        serviceType != nil &&
        port != nil &&
        (port ?? 0) >= Constants.Network.minimumPort &&
        (port ?? 0) <= Constants.Network.maximumPort &&
        !domain.trimmed.isEmpty
    }

    private var isCreatingBonjourService: Bool
    private let selectedTransportLayer: TransportLayer = .tcp

    init(
        isPresented: Binding<Bool>,
        customPublishedServices: Binding<[BonjourService]>
    ) {
        self._isPresented = isPresented
        self._customPublishedServices = customPublishedServices
        self.serviceToUpdate = BonjourService(
            service: .init(
                domain: Constants.Network.defaultDomain,
                type: "",
                name: "",
                port: 0
            ),
            serviceType: BonjourServiceType(
                name: "",
                type: "",
                transportLayer: .tcp
            )
        )
        isCreatingBonjourService = true
        serviceType = nil
        domain = Constants.Network.defaultDomain
        port = nil
        dataRecords = []
    }

    init(
        isPresented: Binding<Bool>,
        serviceToUpdate: BonjourService,
        customPublishedServices: Binding<[BonjourService]>
    ) {
        self._isPresented = isPresented
        self._customPublishedServices = customPublishedServices
        self.serviceToUpdate = serviceToUpdate
        isCreatingBonjourService = false
        self.serviceType = serviceToUpdate.serviceType
        self.domain = serviceToUpdate.service.domain
        self.port = serviceToUpdate.service.port
        self.dataRecords = serviceToUpdate.dataRecords
    }

    var body: some View {
        NavigationStack {
            List {
                serviceTypeSection()

                portNumberSection()

                serviceDomainSection()

                txtRecordsSection()
            }
            .contentMarginsBasedOnSizeClass()
            .navigationTitle(String(localized: Strings.NavigationTitles.broadcastService))
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        isPresented = false
                    } label: {
                        Label(String(localized: Strings.Buttons.cancel), systemImage: Iconography.cancel)
                    }
                    .keyboardShortcut(.cancelAction)
                    .accessibilityIdentifier("broadcast_cancel_button")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        doneButtonSelected()
                    } label: {
                        Label(String(localized: Strings.Buttons.done), systemImage: Iconography.confirm)
                    }
                    .disabled(!isFormValid)
                    .keyboardShortcut(.defaultAction)
                    .accessibilityIdentifier("broadcast_done_button")
                }
            }
            .sheet(isPresented: $isCreateTxtRecordViewPresented) {
                CreateTxtRecordView(
                    isPresented: $isCreateTxtRecordViewPresented,
                    txtDataRecords: $dataRecords
                )
            }
        }
        #if os(macOS) || os(visionOS)
        // Same min/ideal sizing on macOS and visionOS — without it,
        // Vision Pro sheets render at the system's full ornament-ish
        // default which dwarfs the content. Pin a content-shaped size
        // so the form reads as an inset card on both platforms.
        .frame(minWidth: 480, idealWidth: 520, minHeight: 400, idealHeight: 500)
        #endif
        #if canImport(FoundationModels)
        // Shared with `SupportedServicesView`; gates on iOS/macOS/visionOS 26 internally.
        .modifier(AIServiceTypeListSheetModifier(serviceTypeToExplain: $serviceTypeToExplain))
        #endif
    }

    // MARK: - Service Type Section

    private func serviceTypeSection() -> some View {
        Section {
            if !isCreatingBonjourService, let serviceType {
                BlueSectionItemIconTitleDetailView(
                    imageSystemName: serviceType.imageSystemName,
                    title: serviceType.name,
                    detail: serviceType.fullType
                )
                .contextMenu { aiInsightsContextMenu(for: serviceType) }
            } else {
                NavigationLink {
                    SelectServiceTypeView(selectedServiceType: $serviceType)
                } label: {
                    BlueSectionItemIconTitleDetailView(
                        imageSystemName: serviceType?.imageSystemName,
                        title: serviceType?.name ?? String(localized: Strings.Placeholders.selectServiceType),
                        detail: serviceType?.fullType
                    )
                }
                .listRowBackground(
                    // Capsule clip mirrors `BlueSectionItemIconTitleDetailView`'s
                    // own row background; without it the override falls back to
                    // the system's rounded-rectangle row shape. The 40% opacity
                    // keeps the unselected state reading as "tap to choose."
                    Color.kozBonBlue
                        .opacity(0.4)
                        .clipShape(.capsule)
                )
                .contextMenu {
                    // Skip the menu before a selection — empty menus consume
                    // the long-press gesture without showing anything.
                    if let serviceType {
                        aiInsightsContextMenu(for: serviceType)
                    }
                }
            }
        } header: {
            Text(Strings.Sections.serviceType)
                .accessibilityAddTraits(.isHeader)
        } footer: {
            if let serviceTypeError {
                Text(verbatim: serviceTypeError)
                    .foregroundStyle(.red)
                    .accessibilityLabel(Strings.Accessibility.error(serviceTypeError))
            }
        }
        .onChange(of: [serviceType]) {
            withAnimation(reduceMotion ? nil : .default) {
                if serviceType != nil {
                    serviceTypeError = nil
                }
            }
        }
    }

    // MARK: - Port Number Section

    private func portNumberSection() -> some View {
        Section {
            TextField(
                String(localized: Strings.Placeholders.servicePortNumber),
                value: $port,
                format: .number
            )
            #if !os(macOS)
            .keyboardType(.numberPad)
            #endif
            // macOS hover tooltip; other platforms ignore `.help`.
            .help(Text(Strings.Guidance.servicePortHint))
            .onSubmit {
                doneButtonSelected()
            }
            .accessibilityLabel(String(localized: Strings.Accessibility.portNumber))
            .accessibilityHint(Strings.Accessibility.portHint(min: Constants.Network.minimumPort, max: Constants.Network.maximumPort))
            .accessibilityValue(port.map { "\($0)" } ?? "")

        } header: {
            Text(Strings.Sections.portNumber)
                .accessibilityAddTraits(.isHeader)
        } footer: {
            // Dual-purpose footer: red error when validation fails, hint otherwise.
            if let portError {
                Text(verbatim: portError)
                    .foregroundStyle(.red)
                    .accessibilityLabel(Strings.Accessibility.error(portError))
            } else {
                Text(Strings.Guidance.servicePortHint)
            }
        }
        .onChange(of: [port]) {
            withAnimation(reduceMotion ? nil : .default) {
                if port != nil {
                    portError = nil
                }
            }
        }
    }

    // MARK: - Service Domain Section

    private func serviceDomainSection() -> some View {
        Section {
            TextField(String(localized: Strings.Placeholders.serviceDomain), text: $domain)
                .accessibilityLabel(String(localized: Strings.Accessibility.serviceDomain))
                .accessibilityHint(String(localized: Strings.Accessibility.serviceDomainHint))
                // macOS hover tooltip; other platforms ignore `.help`.
                .help(Text(Strings.Guidance.serviceDomainHint))
                .onSubmit {
                    doneButtonSelected()
                }
                .disabled(false)
        } header: {
            Text(Strings.Sections.serviceDomain)
                .accessibilityAddTraits(.isHeader)
        } footer: {
            // Dual-purpose footer: red error when validation fails, hint otherwise.
            if let domainError {
                Text(verbatim: domainError)
                    .foregroundStyle(.red)
                    .accessibilityLabel(Strings.Accessibility.error(domainError))
            } else {
                Text(Strings.Guidance.serviceDomainHint)
            }
        }
        .onChange(of: [domain]) {
            withAnimation(reduceMotion ? nil : .default) {
                if !domain.isEmpty {
                    domainError = nil
                }
            }
        }
    }

    // MARK: - TXT Records Section

    private func txtRecordsSection() -> some View {
        Section {
            ForEach(dataRecords, id: \.key) { dataRecord in
                TitleDetailStackView(
                    title: dataRecord.key,
                    detail: dataRecord.value
                )
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        let indexToRemove = dataRecords.firstIndex { record in
                            record.key == dataRecord.key
                        }
                        if let indexToRemove {
                            _ = withAnimation(reduceMotion ? nil : .default) {
                                dataRecords.remove(at: indexToRemove)
                            }
                        }
                    } label: {
                        Label(String(localized: Strings.Buttons.remove), systemImage: Iconography.remove)
                    }
                    .accessibilityLabel(Strings.Accessibility.remove(dataRecord.key))
                    .accessibilityHint(String(localized: Strings.Accessibility.deleteTxtRecordHint))
                    .tint(.red)
                }
            }

            Button {
                isCreateTxtRecordViewPresented = true
            } label: {
                Label(String(localized: Strings.Buttons.addTxtRecord), systemImage: Iconography.add)
            }
            .accessibilityHint(String(localized: Strings.Accessibility.addTxtRecordHint))
        } header: {
            Text(Strings.Sections.txtRecords)
                .accessibilityAddTraits(.isHeader)
        } footer: {
            // TXT-record-specific explanation rather than form-wide
            // tips. The other fields (Service Type, Port, Domain) all
            // have their own per-field hints in their section footers
            // now, so this footer can stay focused on the section it
            // sits under: what TXT records are, when to add them, and
            // when to leave the list empty.
            Text(Strings.Guidance.txtRecord)
        }
    }

    // MARK: - Validated Inputs

    /// The validated, ready-to-publish form values returned by
    /// ``validateForm()``. Bundling them in a struct keeps the
    /// `doneButtonSelected` body short and makes the Task closure
    /// receive a single value instead of capturing five.
    private struct ValidatedInputs {
        let serviceType: BonjourServiceType
        let port: Int
        let domain: String
    }

    // MARK: - Done Action

    private func doneButtonSelected() {
        clearAllErrors()
        guard let inputs = validateForm() else { return }
        publish(inputs: inputs)
    }

    /// Validates every field on the form, animating the appropriate
    /// inline error if anything is missing or out of range. Returns
    /// `nil` after surfacing the first failure so the caller knows
    /// not to proceed with a publish.
    private func validateForm() -> ValidatedInputs? {
        guard let serviceType else {
            withAnimation(reduceMotion ? nil : .default) {
                serviceTypeError = String(localized: Strings.Errors.serviceTypeRequired)
            }
            return nil
        }

        guard let port else {
            withAnimation(reduceMotion ? nil : .default) {
                portError = String(localized: Strings.Errors.portNumberRequired)
            }
            return nil
        }

        guard port >= Constants.Network.minimumPort else {
            withAnimation(reduceMotion ? nil : .default) {
                portError = Strings.Errors.portMin(Constants.Network.minimumPort)
            }
            return nil
        }

        guard port <= Constants.Network.maximumPort else {
            withAnimation(reduceMotion ? nil : .default) {
                portError = Strings.Errors.portMax(Constants.Network.maximumPort)
            }
            return nil
        }

        let trimmedDomain = domain.trimmed
        guard !trimmedDomain.isEmpty else {
            withAnimation(reduceMotion ? nil : .default) {
                domainError = String(localized: Strings.Errors.domainRequired)
            }
            return nil
        }

        return ValidatedInputs(
            serviceType: serviceType,
            port: port,
            domain: trimmedDomain
        )
    }

    /// Publishes the validated inputs and updates the parent
    /// view's published-services list with the new or replaced
    /// service. Wraps the network call in an animated Task so
    /// the list change reads as a smooth append/replace and any
    /// publish error surfaces inline on the form.
    private func publish(inputs: ValidatedInputs) {
        Task {
            do {
                let publishedService = try await dependencies.bonjourPublishManager.publish(
                    name: inputs.serviceType.name,
                    type: inputs.serviceType.type,
                    port: inputs.port,
                    domain: inputs.domain,
                    transportLayer: selectedTransportLayer,
                    detail: inputs.serviceType.localizedDetail ?? "N/A"
                )

                publishedService.updateTXTRecords(dataRecords)
                upsert(publishedService)
                isPresented = false
            } catch {
                serviceTypeError = Strings.Errors.publishFailed(error.localizedDescription)
            }
        }
    }

    /// Inserts or replaces `service` in the parent view's
    /// `customPublishedServices` binding, with a respect-Reduce-Motion
    /// animation on the change.
    private func upsert(_ service: BonjourService) {
        withAnimation(reduceMotion ? nil : .default) {
            if let index = customPublishedServices.firstIndex(of: service) {
                customPublishedServices[index] = service
            } else {
                customPublishedServices.append(service)
            }
        }
    }

    /// Clears all three inline errors with a single Reduce-Motion-aware
    /// animation. Called at the top of every submit so a re-tap after
    /// fixing one field clears the stale message.
    private func clearAllErrors() {
        withAnimation(reduceMotion ? nil : .default) {
            serviceTypeError = nil
            portError = nil
            domainError = nil
        }
    }

    // MARK: - AI Insights Menu

    /// Long-press menu shown on the selected service-type row that
    /// surfaces Apple Intelligence's "Insights" affordance — the same
    /// component used by the Library and Discover rows. Tapping the
    /// menu item plays a medium haptic and triggers the AI
    /// explanation sheet via the `serviceTypeToExplain` binding.
    /// Internally `AIContextMenuItems` checks the device's Apple
    /// Intelligence availability and the user's preference, so this
    /// view doesn't have to duplicate any of that gating logic.
    @ViewBuilder
    private func aiInsightsContextMenu(for serviceType: BonjourServiceType) -> some View {
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
