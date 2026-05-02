//
//  BonjourChatView+Sheets.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourAI
import BonjourCore
import BonjourLocalization
import BonjourModels

// MARK: - Sheet & Confirmation Presentation

extension BonjourChatView {

    /// Attaches every chat-driven presentation to the supplied base
    /// view: three `.sheet(item:)` modifiers (create custom service
    /// type, broadcast, edit custom service type) and two
    /// destructive `.confirmationDialog` modifiers (delete custom
    /// service type, stop broadcast).
    ///
    /// Bundling them here keeps the chat view's `body` chain compact
    /// — the call site just reads `chatPresentations(applyingTo:
    /// chatContent)` and lets all five attach in one go. Each
    /// presentation captures the chat view's `@State` directly
    /// because this method lives on the `BonjourChatView` struct
    /// (via extension), so there's no binding-drilling to thread
    /// through a separate ViewModifier type.
    ///
    /// The sheets and dialogs propagate up through SwiftUI's
    /// presentation graph regardless of where in the modifier chain
    /// they're declared, so attaching them here (before
    /// `.navigationTitle` / `.toolbar` / `.onChange` in `body`)
    /// has no behavioral effect on layout or focus order.
    ///
    /// `function_body_length` is disabled locally because the body
    /// is a single chained expression — five `.sheet` /
    /// `.confirmationDialog` modifiers each with an inline content
    /// closure. Splitting just for line count would shatter the
    /// chain into per-sheet helpers that thread the view through
    /// generics for no structural benefit. The function is dense
    /// but each closure is small and well-documented inline.
    @ViewBuilder
    // swiftlint:disable:next function_body_length
    func chatPresentations<V: View>(applyingTo base: V) -> some View {
        base
            // Pre-filled "create custom service type" sheet.
            // Reused from the Library tab — same view, same
            // validation, same Core Data persistence path.
            .sheet(item: $pendingCreateTypeIntent) { intent in
                CreateOrUpdateBonjourServiceTypeView(
                    isPresented: Binding(
                        get: { pendingCreateTypeIntent != nil },
                        set: { if !$0 { pendingCreateTypeIntent = nil } }
                    ),
                    prefilledName: intent.name,
                    prefilledType: intent.type,
                    prefilledDetails: intent.details
                )
            }
            // Pre-filled "broadcast a service" sheet. Reused from
            // the Discover tab. Sharing
            // `viewModel.customPublishedServices` with Discover means
            // a broadcast started from chat shows up in the Discover
            // list immediately on dismissal — the same shared state
            // both surfaces already use.
            .sheet(item: $pendingBroadcastIntent) { intent in
                // `@Bindable` on a local var inside the sheet
                // closure produces a binding source from the
                // `@Observable` view model without changing the
                // chat view's stored property to `@Bindable`
                // (which would force the init signature to take a
                // `Bindable<BonjourServicesViewModel>` and ripple
                // through the call sites in `AppCore`).
                @Bindable var bindableViewModel = viewModel
                NavigationStack {
                    BroadcastBonjourServiceView(
                        isPresented: Binding(
                            get: { pendingBroadcastIntent != nil },
                            set: { if !$0 { pendingBroadcastIntent = nil } }
                        ),
                        customPublishedServices: $bindableViewModel.customPublishedServices,
                        prefilledServiceType: intent.serviceType,
                        prefilledPort: intent.port,
                        prefilledDomain: intent.domain,
                        prefilledDataRecords: intent.dataRecords
                    )
                }
            }
            // Pre-filled edit-mode sheet for an existing custom
            // service type. The form's existing edit-init disables
            // the type field but keeps name + description editable;
            // on Done it deletes the (type, transport)-keyed Core
            // Data record and re-saves with the revised values, so
            // a renamed draft cleanly replaces the existing record.
            .sheet(item: $pendingEditServiceType) { _ in
                NavigationStack {
                    CreateOrUpdateBonjourServiceTypeView(
                        isPresented: Binding(
                            get: { pendingEditServiceType != nil },
                            set: { if !$0 { pendingEditServiceType = nil } }
                        ),
                        serviceToUpdate: Binding(
                            get: {
                                // The optional should always be non-nil while
                                // this sheet is presented; the `??` fallback
                                // only fires during the brief dismiss
                                // animation between the user tapping Done
                                // and the sheet collapsing.
                                pendingEditServiceType ?? BonjourServiceType(
                                    name: "",
                                    type: "",
                                    transportLayer: .tcp,
                                    detail: ""
                                )
                            },
                            set: { pendingEditServiceType = $0 }
                        )
                    )
                }
            }
            // Destructive confirmation: delete a custom service type.
            // Phrased as a question matching the established pattern
            // ("Are you sure you want to delete the <name> service
            // type?") so destructive intent reads unambiguously
            // before the user taps red. The dialog's role-based
            // buttons render Delete in red on every platform.
            .confirmationDialog(
                deleteCustomServiceTypeQuestion,
                isPresented: deleteCustomServiceTypeBinding,
                titleVisibility: .visible,
                presenting: pendingDeleteCustomServiceType
            ) { type in
                Button(role: .destructive) {
                    type.deletePersistentCopy()
                    pendingDeleteCustomServiceType = nil
                } label: {
                    Text(Strings.Buttons.delete)
                }
                Button(role: .cancel) {
                    pendingDeleteCustomServiceType = nil
                } label: {
                    Text(Strings.Buttons.cancel)
                }
            }
            // Destructive confirmation: stop an active broadcast.
            // Same phrasing pattern: "Are you sure you want to stop
            // broadcasting <name>?" so the user reads what's about
            // to happen before tapping the red button.
            .confirmationDialog(
                stopBroadcastQuestion,
                isPresented: stopBroadcastBinding,
                titleVisibility: .visible,
                presenting: pendingStopBroadcastService
            ) { service in
                Button(role: .destructive) {
                    let target = service
                    Task {
                        // `unPublish(service:)` is async because the
                        // underlying `NetService.stop()` flushes through
                        // the run loop. Capture the target so we don't
                        // race the @State clearing below.
                        await viewModel.publishManager.unPublish(service: target)
                        // Mirror what the broadcast sheet does on
                        // success — keep the in-memory list aligned
                        // with the publish manager's authoritative state.
                        viewModel.customPublishedServices.removeAll {
                            $0.serviceType.fullType == target.serviceType.fullType
                        }
                    }
                    pendingStopBroadcastService = nil
                } label: {
                    Text(Strings.Buttons.stop)
                }
                Button(role: .cancel) {
                    pendingStopBroadcastService = nil
                } label: {
                    Text(Strings.Buttons.cancel)
                }
            }
    }
}

// MARK: - Assistant Intent Handling

extension BonjourChatView {

    /// Hydrate a freshly-published broker intent into the matching
    /// local `@State` so a `.sheet(item:)` modifier picks it up and
    /// presents the pre-filled form. The broker is consumed
    /// immediately so a re-render with the same `pendingIntent`
    /// doesn't re-fire the sheet — once the local state has the
    /// payload, the broker has done its job.
    ///
    /// Each intent case dispatches to a per-case handler so this
    /// method stays a thin switch (see SwiftLint
    /// `cyclomatic_complexity`). The handlers may bail without
    /// publishing local state when a lookup fails (e.g. the user
    /// deleted the referenced type between the tool call and this
    /// handler running) — in that case the broker is still consumed
    /// at the end so the failed intent doesn't keep re-firing.
    func handlePendingIntent(_ newIntent: BonjourChatIntent?) {
        guard let newIntent else { return }
        guard let session else {
            // No session means no broker either — nothing to consume.
            return
        }

        switch newIntent {
        case let .createCustomServiceType(name, type, _, details):
            handleCreateIntent(name: name, type: type, details: details)
        case let .broadcastService(fullType, port, domain, txtRecords):
            handleBroadcastIntent(
                fullType: fullType,
                port: port,
                domain: domain,
                txtRecords: txtRecords,
                session: session
            )
        case let .editCustomServiceType(currentFullType, suggestedName, suggestedDetails):
            handleEditIntent(
                currentFullType: currentFullType,
                suggestedName: suggestedName,
                suggestedDetails: suggestedDetails,
                session: session
            )
        case let .deleteCustomServiceType(fullType):
            handleDeleteIntent(fullType: fullType, session: session)
        case let .stopBroadcast(fullType):
            handleStopBroadcastIntent(fullType: fullType, session: session)
        }

        session.intentBroker.consume()
    }

    fileprivate func handleCreateIntent(name: String, type: String, details: String) {
        // The intent's `transport` field is captured for future
        // form expansion (UDP support); the create-service-type
        // form is currently TCP-only, so it isn't surfaced here.
        pendingCreateTypeIntent = PendingCreateTypeIntent(
            name: name,
            type: type,
            details: details
        )
    }

    fileprivate func handleBroadcastIntent(
        fullType: String,
        port: Int?,
        domain: String,
        txtRecords: [TxtRecordDraft],
        session: any BonjourChatSessionProtocol
    ) {
        // Resolve the service type from the user's library
        // (built-ins + custom types). The tool gated on the same
        // lookup, so a missing match here only happens in
        // pathological cases; bail rather than present a useless
        // form so the user isn't left wondering why the type
        // they expected isn't filled in.
        let library = BonjourServiceType.fetchAll()
        guard let resolvedType = library.first(where: { $0.fullType == fullType }) else {
            session.intentBroker.consume()
            return
        }
        let dataRecords = txtRecords.map {
            BonjourService.TxtDataRecord(key: $0.key, value: $0.value)
        }
        pendingBroadcastIntent = PendingBroadcastIntent(
            serviceType: resolvedType,
            port: port,
            domain: domain,
            dataRecords: dataRecords
        )
    }

    fileprivate func handleEditIntent(
        currentFullType: String,
        suggestedName: String?,
        suggestedDetails: String?,
        session: any BonjourChatSessionProtocol
    ) {
        // Look up the existing custom type, then construct a
        // "draft" with the model's suggestions applied. The form
        // reads the draft's name/detail into its `@State`
        // properties on init; on Done it deletes the (type,
        // transport)-keyed Core Data record and re-saves with
        // the revised name/detail. Because the lookup is by
        // (type, transport) — not by name — a renamed draft
        // correctly replaces the existing record rather than
        // creating a duplicate.
        let library = BonjourServiceType.fetchAll()
        guard let existing = library.first(where: { $0.fullType == currentFullType }) else {
            session.intentBroker.consume()
            return
        }
        pendingEditServiceType = BonjourServiceType(
            name: suggestedName ?? existing.name,
            type: existing.type,
            transportLayer: existing.transportLayer,
            detail: suggestedDetails ?? existing.detail
        )
    }

    fileprivate func handleDeleteIntent(fullType: String, session: any BonjourChatSessionProtocol) {
        // Resolve the existing type so the confirmation dialog
        // can name it ("Delete <name>?"). If lookup fails we
        // bail — the dialog without a name would just be
        // confusing.
        let library = BonjourServiceType.fetchAll()
        guard let existing = library.first(where: { $0.fullType == fullType }) else {
            session.intentBroker.consume()
            return
        }
        pendingDeleteCustomServiceType = existing
    }

    fileprivate func handleStopBroadcastIntent(fullType: String, session: any BonjourChatSessionProtocol) {
        // Resolve to the live `BonjourService` instance so we
        // can call `unPublish(service:)` on confirm. Reading
        // from the view model keeps the lookup consistent with
        // what the Discover tab is actually showing — the
        // session's stop-broadcast tool used the same source.
        guard let active = viewModel.publishManager.publishedServices
            .first(where: { $0.serviceType.fullType == fullType }) else {
            session.intentBroker.consume()
            return
        }
        pendingStopBroadcastService = active
    }

    // MARK: - Destructive Confirmation Helpers

    /// Localized "Are you sure you want to delete the <name> service
    /// type?" string. Uses the format-string accessor in
    /// `Strings.Chat.confirmDeleteServiceTypeFormat`. Empty when the
    /// pending state is nil — the binding gating the dialog ensures
    /// it isn't read in that case.
    var deleteCustomServiceTypeQuestion: String {
        guard let target = pendingDeleteCustomServiceType else { return "" }
        return Strings.Chat.confirmDeleteServiceType(target.name)
    }

    /// Localized "Are you sure you want to stop broadcasting
    /// <service_name>?" string. The "service_name" is the user-given
    /// name of the broadcast (e.g. "Living Room Speaker"), not the
    /// raw DNS-SD type — the dialog reads as a sentence about the
    /// thing the user knows by name.
    var stopBroadcastQuestion: String {
        guard let active = pendingStopBroadcastService else { return "" }
        return Strings.Chat.confirmStopBroadcast(active.service.name)
    }

    /// Boolean binding the destructive-confirmation modifier needs.
    /// Mirrors the optional state — opening the dialog is implied by
    /// the optional being non-nil. Tapping outside the dialog or the
    /// Cancel button nils the state.
    var deleteCustomServiceTypeBinding: Binding<Bool> {
        Binding(
            get: { pendingDeleteCustomServiceType != nil },
            set: { if !$0 { pendingDeleteCustomServiceType = nil } }
        )
    }

    var stopBroadcastBinding: Binding<Bool> {
        Binding(
            get: { pendingStopBroadcastService != nil },
            set: { if !$0 { pendingStopBroadcastService = nil } }
        )
    }

    // MARK: - Pending Intent Payloads

    /// Local payload for the create-custom-service-type sheet.
    /// Conforms to `Identifiable` so `.sheet(item:)` can pick it up;
    /// the `id` is a fresh UUID per intent so two consecutive
    /// "create the same type" requests still re-present the sheet
    /// (rather than the second being deduped because the payload
    /// equals the first).
    struct PendingCreateTypeIntent: Identifiable {
        let id = UUID()
        let name: String
        let type: String
        let details: String
    }

    /// Local payload for the broadcast sheet. Holds the resolved
    /// `BonjourServiceType` (already looked up against the library)
    /// and the rest of the form pre-fills.
    struct PendingBroadcastIntent: Identifiable {
        let id = UUID()
        let serviceType: BonjourServiceType
        let port: Int?
        let domain: String
        let dataRecords: [BonjourService.TxtDataRecord]
    }
}
