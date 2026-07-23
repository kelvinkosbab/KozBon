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

// One cohesive form view: service-type picker, port + domain
// inputs, TXT-record list, and the AI Insights long-press menu —
// each piece reads context (`isCreatingBonjourService`,
// validation state, the broadcast-form prefill paths used by
// the chat assistant's `prepareBroadcast` tool) from the view
// model's state, so splitting across files would force the
// state through bindings or environment for no structural
// benefit. Form state, validation, and the publish call moved
// to `BroadcastBonjourServiceViewModel`.

// MARK: - BroadcastBonjourServiceView

struct BroadcastBonjourServiceView: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.preferencesStore) private var preferencesStore

    @Binding private var isPresented: Bool
    @Binding private var customPublishedServices: [BonjourService]

    @State private var viewModel: BroadcastBonjourServiceViewModel
    @State private var isCreateTxtRecordViewPresented = false

    /// Drives the Apple Intelligence Insights sheet from the
    /// service-type row's long-press menu. Stays on the View
    /// because the Insights sheet is a UI-presentation concern,
    /// not a piece of form state — the VM doesn't need to know
    /// about it.
    @State private var serviceTypeToExplain: BonjourServiceType?

    /// The form's error footers, for VoiceOver focus routing.
    private enum ValidationErrorField: Hashable {
        case serviceType, port, domain
    }

    /// Moves VoiceOver focus onto the first error footer after a
    /// failed submit. Without it, a VoiceOver user who taps Done
    /// stays focused on the button and is never told the submit
    /// failed — the red footers are only discovered by manually
    /// navigating.
    @AccessibilityFocusState private var focusedError: ValidationErrorField?

    init(
        isPresented: Binding<Bool>,
        customPublishedServices: Binding<[BonjourService]>,
        publishManager: any BonjourPublishManagerProtocol
    ) {
        self._isPresented = isPresented
        self._customPublishedServices = customPublishedServices
        self._viewModel = State(
            initialValue: .empty(publishManager: publishManager)
        )
    }

    init(
        isPresented: Binding<Bool>,
        serviceToUpdate: BonjourService,
        customPublishedServices: Binding<[BonjourService]>,
        publishManager: any BonjourPublishManagerProtocol
    ) {
        self._isPresented = isPresented
        self._customPublishedServices = customPublishedServices
        self._viewModel = State(
            initialValue: .editing(serviceToUpdate, publishManager: publishManager)
        )
    }

    /// Create-mode init that pre-fills the form with values
    /// supplied by the chat assistant's `prepareBroadcast`
    /// tool. Routes through ``BroadcastBonjourServiceViewModel/prefilled(serviceType:port:domain:dataRecords:publishManager:)``
    /// so the empty-domain → default-domain fallback lives in
    /// one place.
    init(
        isPresented: Binding<Bool>,
        customPublishedServices: Binding<[BonjourService]>,
        prefilledServiceType: BonjourServiceType?,
        prefilledPort: Int?,
        prefilledDomain: String,
        prefilledDataRecords: [BonjourService.TxtDataRecord],
        publishManager: any BonjourPublishManagerProtocol
    ) {
        self._isPresented = isPresented
        self._customPublishedServices = customPublishedServices
        self._viewModel = State(initialValue: .prefilled(
            serviceType: prefilledServiceType,
            port: prefilledPort,
            domain: prefilledDomain,
            dataRecords: prefilledDataRecords,
            publishManager: publishManager
        ))
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
                        Label(Strings.Buttons.cancel, systemImage: Iconography.cancel)
                    }
                    .keyboardShortcut(.cancelAction)
                    .accessibilityIdentifier("broadcast_cancel_button")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        commit()
                    } label: {
                        Label(Strings.Buttons.done, systemImage: Iconography.confirm)
                    }
                    .disabled(!viewModel.isFormValid)
                    .keyboardShortcut(.defaultAction)
                    .accessibilityIdentifier("broadcast_done_button")
                }
            }
            .sheet(isPresented: $isCreateTxtRecordViewPresented) {
                @Bindable var bindable = viewModel
                CreateTxtRecordView(
                    isPresented: $isCreateTxtRecordViewPresented,
                    txtDataRecords: $bindable.dataRecords
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

    @ViewBuilder
    private func serviceTypeSection() -> some View {
        @Bindable var bindable = viewModel
        Section {
            if !viewModel.isCreatingBonjourService, let serviceType = viewModel.serviceType {
                BlueSectionItemIconTitleDetailView(
                    imageSystemName: serviceType.imageSystemName,
                    title: serviceType.name,
                    detail: serviceType.fullType
                )
                .contextMenu { aiInsightsContextMenu(for: serviceType) }
                // VoiceOver / Switch Control mirror — context menus
                // aren't reachable from the rotor.
                .accessibilityActions {
                    InsightsAccessibilityAction(action: { serviceTypeToExplain = serviceType })
                }
            } else {
                NavigationLink {
                    SelectServiceTypeView(selectedServiceType: $bindable.serviceType)
                } label: {
                    BlueSectionItemIconTitleDetailView(
                        imageSystemName: viewModel.serviceType?.imageSystemName,
                        title: viewModel.serviceType?.name ?? String(localized: Strings.Placeholders.selectServiceType),
                        detail: viewModel.serviceType?.fullType
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
                    if let serviceType = viewModel.serviceType {
                        aiInsightsContextMenu(for: serviceType)
                    }
                }
                // VoiceOver / Switch Control mirror — context menus
                // aren't reachable from the rotor. Same pre-selection
                // gate as the menu above.
                .accessibilityActions {
                    if let serviceType = viewModel.serviceType {
                        InsightsAccessibilityAction(action: { serviceTypeToExplain = serviceType })
                    }
                }
            }
        } header: {
            Text(Strings.Sections.serviceType)
                .accessibilityAddTraits(.isHeader)
        } footer: {
            if let serviceTypeError = viewModel.serviceTypeError {
                Text(verbatim: serviceTypeError)
                    .foregroundStyle(.red)
                    .accessibilityLabel(Strings.Accessibility.error(serviceTypeError))
                    .accessibilityFocused($focusedError, equals: .serviceType)
            }
        }
        .onChange(of: [viewModel.serviceType]) {
            viewModel.clearServiceTypeErrorIfResolved(reduceMotion: reduceMotion)
        }
    }

    // MARK: - Port Number Section

    @ViewBuilder
    private func portNumberSection() -> some View {
        @Bindable var bindable = viewModel
        Section {
            TextField(
                String(localized: Strings.Placeholders.servicePortNumber),
                value: $bindable.port,
                format: .number
            )
            #if !os(macOS)
            .keyboardType(.numberPad)
            #endif
            // macOS hover tooltip; other platforms ignore `.help`.
            .help(Text(Strings.Guidance.servicePortHint))
            .onSubmit {
                commit()
            }
            .accessibilityLabel(Strings.Accessibility.portNumber)
            .accessibilityHint(Strings.Accessibility.portHint(min: Constants.Network.minimumPort, max: Constants.Network.maximumPort))
            .accessibilityValue(viewModel.port.map { "\($0)" } ?? "")

        } header: {
            Text(Strings.Sections.portNumber)
                .accessibilityAddTraits(.isHeader)
        } footer: {
            // Dual-purpose footer: red error when validation fails, hint otherwise.
            if let portError = viewModel.portError {
                Text(verbatim: portError)
                    .foregroundStyle(.red)
                    .accessibilityLabel(Strings.Accessibility.error(portError))
                    .accessibilityFocused($focusedError, equals: .port)
            } else {
                Text(Strings.Guidance.servicePortHint)
            }
        }
        .onChange(of: [viewModel.port]) {
            viewModel.clearPortErrorIfResolved(reduceMotion: reduceMotion)
        }
    }

    // MARK: - Service Domain Section

    @ViewBuilder
    private func serviceDomainSection() -> some View {
        @Bindable var bindable = viewModel
        Section {
            TextField(String(localized: Strings.Placeholders.serviceDomain), text: $bindable.domain)
                .accessibilityLabel(Strings.Accessibility.serviceDomain)
                .accessibilityHint(Strings.Accessibility.serviceDomainHint)
                // macOS hover tooltip; other platforms ignore `.help`.
                .help(Text(Strings.Guidance.serviceDomainHint))
                .onSubmit {
                    commit()
                }
                .disabled(false)
        } header: {
            Text(Strings.Sections.serviceDomain)
                .accessibilityAddTraits(.isHeader)
        } footer: {
            // Dual-purpose footer: red error when validation fails, hint otherwise.
            if let domainError = viewModel.domainError {
                Text(verbatim: domainError)
                    .foregroundStyle(.red)
                    .accessibilityLabel(Strings.Accessibility.error(domainError))
                    .accessibilityFocused($focusedError, equals: .domain)
            } else {
                Text(Strings.Guidance.serviceDomainHint)
            }
        }
        .onChange(of: [viewModel.domain]) {
            viewModel.clearDomainErrorIfResolved(reduceMotion: reduceMotion)
        }
    }

    // MARK: - TXT Records Section

    @ViewBuilder
    private func txtRecordsSection() -> some View {
        Section {
            ForEach(viewModel.dataRecords, id: \.key) { dataRecord in
                TitleDetailStackView(
                    title: dataRecord.key,
                    detail: dataRecord.value
                )
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        removeDataRecord(dataRecord)
                    } label: {
                        Label(Strings.Buttons.remove, systemImage: Iconography.remove)
                    }
                    .accessibilityLabel(Strings.Accessibility.remove(dataRecord.key))
                    .accessibilityHint(Strings.Accessibility.deleteTxtRecordHint)
                    .tint(.red)
                }
                // Swipe actions are gesture-only — mirror delete so
                // VoiceOver / Switch Control users can remove records.
                .accessibilityActions {
                    Button(Strings.Accessibility.remove(dataRecord.key)) {
                        removeDataRecord(dataRecord)
                    }
                }
            }

            Button {
                isCreateTxtRecordViewPresented = true
            } label: {
                Label(Strings.Buttons.addTxtRecord, systemImage: Iconography.add)
            }
            .accessibilityHint(Strings.Accessibility.addTxtRecordHint)
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

    // MARK: - Error Focus

    /// Routes VoiceOver focus to the first error footer, in form
    /// order. Deferred one runloop tick so the footer views exist
    /// before focus is assigned — assigning accessibility focus to
    /// a not-yet-rendered element is silently dropped.
    private func moveAccessibilityFocusToFirstError() {
        Task { @MainActor in
            await Task.yield()
            if viewModel.serviceTypeError != nil {
                focusedError = .serviceType
            } else if viewModel.portError != nil {
                focusedError = .port
            } else if viewModel.domainError != nil {
                focusedError = .domain
            }
        }
    }

    // MARK: - TXT Record Removal

    /// Removes the given TXT record with the standard animation.
    /// Shared by the swipe-delete button and its VoiceOver
    /// accessibility-action mirror so the two paths can't drift.
    private func removeDataRecord(_ dataRecord: BonjourService.TxtDataRecord) {
        guard let indexToRemove = viewModel.dataRecords.firstIndex(where: { record in
            record.key == dataRecord.key
        }) else { return }
        withAnimation(reduceMotion ? nil : .default) {
            // `Array.remove(at:)` returns the removed element;
            // Xcode 27's `#NoUsage` diagnostic flags discarded
            // results from `withAnimation` single-expression
            // closures. Discard explicitly.
            _ = viewModel.dataRecords.remove(at: indexToRemove)
        }
    }

    // MARK: - Done Action

    /// Validates via the VM, awaits the publish call, applies
    /// the upserted array to the parent's binding, and dismisses
    /// the sheet on success. The Task is fire-and-forget at the
    /// SwiftUI body level — `commit` returns immediately so the
    /// button action is sync; the dismissal happens inside the
    /// Task once the publish settles.
    private func commit() {
        Task {
            viewModel.clearAllErrors(reduceMotion: reduceMotion)
            guard let inputs = viewModel.validate(reduceMotion: reduceMotion) else {
                moveAccessibilityFocusToFirstError()
                return
            }
            guard let published = await viewModel.publish(
                inputs: inputs,
                reduceMotion: reduceMotion
            ) else { return }
            withAnimation(reduceMotion ? nil : .default) {
                customPublishedServices = viewModel.upsert(
                    published,
                    into: customPublishedServices
                )
                isPresented = false
            }
        }
    }

    // MARK: - AI Insights Menu

    /// Long-press menu shown on the selected service-type row that
    /// surfaces the Insights affordance — the same component used
    /// by the Library and Discover rows. Tapping the menu item
    /// plays a medium haptic and triggers the AI explanation sheet
    /// via the `serviceTypeToExplain` binding.
    ///
    /// `InsightsContextMenuItems` is backend-aware (ADR 0005): on
    /// iOS 26+ devices with Apple Intelligence selected it renders
    /// the on-device path; on devices with the Anthropic backend
    /// selected and a key configured it renders "Explain with
    /// Claude". This view doesn't have to duplicate the routing.
    @ViewBuilder
    private func aiInsightsContextMenu(for serviceType: BonjourServiceType) -> some View {
        InsightsContextMenuItems(action: { serviceTypeToExplain = serviceType })
    }
}
