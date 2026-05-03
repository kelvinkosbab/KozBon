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
    /// All five `pending*` items live on `BonjourChatViewModel`,
    /// not on this View struct. We use `@Bindable` to project
    /// bindings into the view model's state for `.sheet(item:)`
    /// and the dialog `isPresented:` flags. The handler logic
    /// (delete, unpublish, etc.) goes through view-model methods
    /// where state mutations are testable.
    ///
    /// `function_body_length` is disabled locally because the
    /// body is a single chained expression — five `.sheet` /
    /// `.confirmationDialog` modifiers each with an inline content
    /// closure. Splitting just for line count would shatter the
    /// chain into per-sheet helpers that thread the view through
    /// generics for no structural benefit.
    @ViewBuilder
    // swiftlint:disable:next function_body_length
    func chatPresentations<V: View>(applyingTo base: V) -> some View {
        @Bindable var bindable = viewModel
        @Bindable var bindableServices = viewModel.services
        base
            // Pre-filled "create custom service type" sheet.
            // Reused from the Library tab — same view, same
            // validation, same Core Data persistence path.
            .sheet(item: $bindable.pendingCreateTypeIntent) { intent in
                CreateOrUpdateBonjourServiceTypeView(
                    isPresented: Binding(
                        get: { viewModel.pendingCreateTypeIntent != nil },
                        set: { if !$0 { viewModel.pendingCreateTypeIntent = nil } }
                    ),
                    prefilledName: intent.name,
                    prefilledType: intent.type,
                    prefilledDetails: intent.details
                )
            }
            // Pre-filled "broadcast a service" sheet. Reused from
            // the Discover tab. Sharing
            // `services.customPublishedServices` with Discover means
            // a broadcast started from chat shows up in the Discover
            // list immediately on dismissal — the same shared state
            // both surfaces already use.
            .sheet(item: $bindable.pendingBroadcastIntent) { intent in
                NavigationStack {
                    BroadcastBonjourServiceView(
                        isPresented: Binding(
                            get: { viewModel.pendingBroadcastIntent != nil },
                            set: { if !$0 { viewModel.pendingBroadcastIntent = nil } }
                        ),
                        customPublishedServices: $bindableServices.customPublishedServices,
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
            // Data record and re-saves with the revised values.
            .sheet(item: $bindable.pendingEditServiceType) { _ in
                NavigationStack {
                    CreateOrUpdateBonjourServiceTypeView(
                        isPresented: Binding(
                            get: { viewModel.pendingEditServiceType != nil },
                            set: { if !$0 { viewModel.pendingEditServiceType = nil } }
                        ),
                        serviceToUpdate: Binding(
                            get: {
                                // The optional should always be non-nil while
                                // this sheet is presented; the `??` fallback
                                // only fires during the brief dismiss
                                // animation between the user tapping Done
                                // and the sheet collapsing.
                                viewModel.pendingEditServiceType ?? BonjourServiceType(
                                    name: "",
                                    type: "",
                                    transportLayer: .tcp,
                                    detail: ""
                                )
                            },
                            set: { viewModel.pendingEditServiceType = $0 }
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
                viewModel.deleteCustomServiceTypeQuestion,
                isPresented: deleteCustomServiceTypeBinding,
                titleVisibility: .visible,
                presenting: viewModel.pendingDeleteCustomServiceType
            ) { type in
                Button(role: .destructive) {
                    type.deletePersistentCopy()
                    viewModel.pendingDeleteCustomServiceType = nil
                } label: {
                    Text(Strings.Buttons.delete)
                }
                Button(role: .cancel) {
                    viewModel.pendingDeleteCustomServiceType = nil
                } label: {
                    Text(Strings.Buttons.cancel)
                }
            }
            // Destructive confirmation: stop an active broadcast.
            // Same phrasing pattern: "Are you sure you want to stop
            // broadcasting <name>?" so the user reads what's about
            // to happen before tapping the red button.
            .confirmationDialog(
                viewModel.stopBroadcastQuestion,
                isPresented: stopBroadcastBinding,
                titleVisibility: .visible,
                presenting: viewModel.pendingStopBroadcastService
            ) { service in
                Button(role: .destructive) {
                    let target = service
                    Task {
                        // `unPublish(service:)` is async because the
                        // underlying `NetService.stop()` flushes through
                        // the run loop. Capture the target so we don't
                        // race the @State clearing below.
                        await viewModel.services.publishManager.unPublish(service: target)
                        // Mirror what the broadcast sheet does on
                        // success — keep the in-memory list aligned
                        // with the publish manager's authoritative state.
                        viewModel.services.customPublishedServices.removeAll {
                            $0.serviceType.fullType == target.serviceType.fullType
                        }
                    }
                    viewModel.pendingStopBroadcastService = nil
                } label: {
                    Text(Strings.Buttons.stop)
                }
                Button(role: .cancel) {
                    viewModel.pendingStopBroadcastService = nil
                } label: {
                    Text(Strings.Buttons.cancel)
                }
            }
    }

    // MARK: - Destructive Confirmation Bindings

    /// Boolean binding the delete `.confirmationDialog` modifier
    /// needs. Mirrors the VM's optional `pendingDeleteCustomServiceType`
    /// state — the dialog opens whenever that's non-nil; tapping
    /// outside or the Cancel button nils it. Lives on the View
    /// (not the VM) because `Binding` is a SwiftUI type the VM
    /// shouldn't depend on; the VM exposes `pendingDeleteCustomServiceType`
    /// directly and the View synthesizes the Bool binding here.
    var deleteCustomServiceTypeBinding: Binding<Bool> {
        Binding(
            get: { viewModel.pendingDeleteCustomServiceType != nil },
            set: { if !$0 { viewModel.pendingDeleteCustomServiceType = nil } }
        )
    }

    /// Boolean binding the stop-broadcast `.confirmationDialog`
    /// modifier needs. See `deleteCustomServiceTypeBinding` for
    /// the rationale on living on the View vs. the VM.
    var stopBroadcastBinding: Binding<Bool> {
        Binding(
            get: { viewModel.pendingStopBroadcastService != nil },
            set: { if !$0 { viewModel.pendingStopBroadcastService = nil } }
        )
    }
}
