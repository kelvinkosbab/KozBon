//
//  BroadcastBonjourServiceViewModel.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourCore
import BonjourLocalization
import BonjourModels
import BonjourScanning

// MARK: - BroadcastBonjourServiceViewModel

/// View model for `BroadcastBonjourServiceView` — owns the
/// service-type / port / domain / TXT-records form state, the
/// inline error strings, the validate-and-publish pipeline, and
/// the upsert helper that decides whether the published service
/// is a fresh entry or a replacement of an existing broadcast.
///
/// The publish manager is captured at init as a long-lived
/// dependency. The View reads it from its own initializer
/// (forwarded by the parent that constructs the sheet) — no
/// `@Environment(\.dependencies)` reach-through required, and
/// the VM's surface stays explicit about what it needs to do
/// its job.
///
/// Three factories collapse the original View's three inits:
/// ``empty(publishManager:)`` for a blank create-mode form,
/// ``editing(_:publishManager:)`` for the edit-existing-broadcast
/// path, and ``prefilled(serviceType:port:domain:dataRecords:publishManager:)``
/// for the chat assistant's `prepareBroadcast` tool. Edit mode
/// pins `isCreatingBonjourService = false`; both create paths
/// stay in create mode so the Done button routes through the
/// publish-new flow rather than an update path.
@MainActor
@Observable
final class BroadcastBonjourServiceViewModel {

    // MARK: - State

    /// Selected service type (e.g. `_http._tcp`). `nil` until
    /// the user picks one from the `SelectServiceTypeView`
    /// navigation link.
    var serviceType: BonjourServiceType?

    /// Inline validation error shown under the service-type row,
    /// or nil when there's no error to surface. Also reused as
    /// the surface for publish-failure errors so a network-side
    /// failure renders next to the form's primary affordance.
    var serviceTypeError: String?

    /// Port number. `nil` means the user hasn't entered anything
    /// yet — the placeholder is shown.
    var port: Int?

    /// Inline validation error shown under the port field.
    var portError: String?

    /// Service domain. Defaults to `Constants.Network.defaultDomain`
    /// (the local DNS-SD search domain) so a stock create form
    /// has a valid value preloaded.
    var domain: String

    /// Inline validation error shown under the domain field.
    var domainError: String?

    /// TXT records to attach to the published service. The
    /// add/edit/remove flow happens via the
    /// `CreateTxtRecordView` sheet which mutates this array
    /// through a binding — the VM is the source of truth for
    /// the staged records, the sheet is the editor surface.
    var dataRecords: [BonjourService.TxtDataRecord]

    // MARK: - Long-Lived Dependencies

    /// `true` for the create-mode path (empty OR pre-filled
    /// from chat); `false` for the edit-an-existing-broadcast
    /// path. Pinned at init.
    let isCreatingBonjourService: Bool

    /// The transport layer the form is fixed to. UDP support
    /// would also need to thread through the publish call and
    /// the type-picker filter, so the form stays single-axis.
    let selectedTransportLayer: TransportLayer = .tcp

    /// The publish manager used by ``publish(inputs:reduceMotion:)``
    /// to advertise the validated service on the network. Held
    /// at init rather than passed to ``publish`` per call so the
    /// VM's surface stays "give me everything I need to do the
    /// whole job" instead of "give me everything except this one
    /// long-lived dep that I'll borrow from you each time."
    let publishManager: any BonjourPublishManagerProtocol

    // MARK: - Init

    private init(
        serviceType: BonjourServiceType?,
        port: Int?,
        domain: String,
        dataRecords: [BonjourService.TxtDataRecord],
        isCreatingBonjourService: Bool,
        publishManager: any BonjourPublishManagerProtocol
    ) {
        self.serviceType = serviceType
        self.port = port
        self.domain = domain
        self.dataRecords = dataRecords
        self.isCreatingBonjourService = isCreatingBonjourService
        self.publishManager = publishManager
    }

    // MARK: - Factories

    /// Create-mode VM with no service type selected, no port,
    /// the default domain, and an empty TXT-record list.
    static func empty(
        publishManager: any BonjourPublishManagerProtocol
    ) -> BroadcastBonjourServiceViewModel {
        BroadcastBonjourServiceViewModel(
            serviceType: nil,
            port: nil,
            domain: Constants.Network.defaultDomain,
            dataRecords: [],
            isCreatingBonjourService: true,
            publishManager: publishManager
        )
    }

    /// Edit-mode VM pre-filled from an existing broadcast. The
    /// service type, domain, port, and TXT records all come from
    /// the running service. `isCreatingBonjourService` is `false`
    /// so the type row reads as a static label rather than a
    /// navigation link.
    static func editing(
        _ service: BonjourService,
        publishManager: any BonjourPublishManagerProtocol
    ) -> BroadcastBonjourServiceViewModel {
        BroadcastBonjourServiceViewModel(
            serviceType: service.serviceType,
            port: service.service.port,
            domain: service.service.domain,
            dataRecords: service.dataRecords,
            isCreatingBonjourService: false,
            publishManager: publishManager
        )
    }

    /// Create-mode VM pre-filled with values from the chat
    /// assistant's `prepareBroadcast` tool call. Identical to
    /// ``empty(publishManager:)`` except for the staged values;
    /// mode stays "create" so the user can change the service
    /// type via the regular `NavigationLink`, and the Done
    /// button still routes through the publish-new path. An
    /// empty domain from the model falls back to the default so
    /// the form doesn't surface a domain-required error before
    /// the user has touched anything.
    static func prefilled(
        serviceType: BonjourServiceType?,
        port: Int?,
        domain: String,
        dataRecords: [BonjourService.TxtDataRecord],
        publishManager: any BonjourPublishManagerProtocol
    ) -> BroadcastBonjourServiceViewModel {
        let resolvedDomain = domain.isEmpty
            ? Constants.Network.defaultDomain
            : domain
        return BroadcastBonjourServiceViewModel(
            serviceType: serviceType,
            port: port,
            domain: resolvedDomain,
            dataRecords: dataRecords,
            isCreatingBonjourService: true,
            publishManager: publishManager
        )
    }

    // MARK: - Computed

    /// Whether the form has the minimum valid inputs needed
    /// for the Done button to enable. Mirrors the original
    /// View's gate: a service type is selected, the port is
    /// in the valid range, and the domain isn't empty after
    /// trimming.
    var isFormValid: Bool {
        serviceType != nil
            && port != nil
            && (port ?? 0) >= Constants.Network.minimumPort
            && (port ?? 0) <= Constants.Network.maximumPort
            && !domain.trimmed.isEmpty
    }

    // MARK: - Validate

    /// Validated, ready-to-publish form output.
    struct ValidatedInputs {
        let serviceType: BonjourServiceType
        let port: Int
        let domain: String
    }

    /// Validates every field on the form. On success returns a
    /// ``ValidatedInputs``; on the first failure surfaces an
    /// inline error against the offending field and returns
    /// `nil`.
    ///
    /// Validation order:
    /// 1. service type selected
    /// 2. port not nil
    /// 3. port ≥ `minimumPort`
    /// 4. port ≤ `maximumPort`
    /// 5. domain not empty after trimming
    ///
    /// Animations on every error mutation respect Reduce
    /// Motion (`reduceMotion == true` → no animation).
    func validate(reduceMotion: Bool) -> ValidatedInputs? {
        let animation: Animation? = reduceMotion ? nil : .default

        guard let serviceType else {
            withAnimation(animation) {
                serviceTypeError = String(localized: Strings.Errors.serviceTypeRequired)
            }
            return nil
        }

        guard let port else {
            withAnimation(animation) {
                portError = String(localized: Strings.Errors.portNumberRequired)
            }
            return nil
        }

        guard port >= Constants.Network.minimumPort else {
            withAnimation(animation) {
                portError = Strings.Errors.portMin(Constants.Network.minimumPort)
            }
            return nil
        }

        guard port <= Constants.Network.maximumPort else {
            withAnimation(animation) {
                portError = Strings.Errors.portMax(Constants.Network.maximumPort)
            }
            return nil
        }

        let trimmedDomain = domain.trimmed
        guard !trimmedDomain.isEmpty else {
            withAnimation(animation) {
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

    // MARK: - Publish

    /// Calls the publish manager with the validated inputs,
    /// updates the resulting service's TXT records from
    /// ``dataRecords``, and returns the published service. On
    /// failure, surfaces a publish-failed error in
    /// ``serviceTypeError`` and returns `nil`. The `serviceTypeError`
    /// slot is reused for publish errors because it sits next
    /// to the form's primary affordance — the type row at the
    /// top of the form — so a network-side failure reads as a
    /// problem with what the user is trying to do.
    ///
    /// - Parameters:
    ///   - inputs: Validated form values from
    ///     ``validate(reduceMotion:)``.
    ///   - reduceMotion: Forwarded into the error-mutation
    ///     animation.
    /// - Returns: The published `BonjourService` on success
    ///   (with TXT records already applied), or `nil` after
    ///   surfacing the error.
    func publish(
        inputs: ValidatedInputs,
        reduceMotion: Bool
    ) async -> BonjourService? {
        do {
            let publishedService = try await publishManager.publish(
                name: inputs.serviceType.name,
                type: inputs.serviceType.type,
                port: inputs.port,
                domain: inputs.domain,
                transportLayer: selectedTransportLayer,
                detail: inputs.serviceType.localizedDetail ?? "N/A"
            )
            publishedService.updateTXTRecords(dataRecords)
            return publishedService
        } catch {
            let animation: Animation? = reduceMotion ? nil : .default
            withAnimation(animation) {
                serviceTypeError = Strings.Errors.publishFailed(error.localizedDescription)
            }
            return nil
        }
    }

    // MARK: - Upsert

    /// Inserts or replaces `service` in the given list. Uses
    /// `BonjourService`'s `Equatable` semantics (the underlying
    /// service identifier) for the firstIndex lookup, matching
    /// the original View's behavior. Returned as a new value
    /// so the View can apply it to its `Binding<[BonjourService]>`
    /// in a single animated assignment.
    func upsert(
        _ service: BonjourService,
        into existing: [BonjourService]
    ) -> [BonjourService] {
        var result = existing
        if let index = result.firstIndex(of: service) {
            result[index] = service
        } else {
            result.append(service)
        }
        return result
    }

    // MARK: - Error Helpers

    /// Clears all three inline errors with a single
    /// Reduce-Motion-aware animation. Called at the top of
    /// every submit so a re-tap after a fix clears the stale
    /// message before the next validation pass.
    func clearAllErrors(reduceMotion: Bool) {
        let animation: Animation? = reduceMotion ? nil : .default
        withAnimation(animation) {
            serviceTypeError = nil
            portError = nil
            domainError = nil
        }
    }

    /// Clears the per-field error for the service-type row
    /// when a type has been selected. Fired by the View's
    /// `.onChange(of: [serviceType])`.
    func clearServiceTypeErrorIfResolved(reduceMotion: Bool) {
        guard serviceType != nil, serviceTypeError != nil else { return }
        let animation: Animation? = reduceMotion ? nil : .default
        withAnimation(animation) {
            serviceTypeError = nil
        }
    }

    /// Clears the per-field error for the port field when the
    /// port has a value. Fired by the View's
    /// `.onChange(of: [port])`.
    func clearPortErrorIfResolved(reduceMotion: Bool) {
        guard port != nil, portError != nil else { return }
        let animation: Animation? = reduceMotion ? nil : .default
        withAnimation(animation) {
            portError = nil
        }
    }

    /// Clears the per-field error for the domain field when
    /// the domain is non-empty. Fired by the View's
    /// `.onChange(of: [domain])`.
    func clearDomainErrorIfResolved(reduceMotion: Bool) {
        guard !domain.isEmpty, domainError != nil else { return }
        let animation: Animation? = reduceMotion ? nil : .default
        withAnimation(animation) {
            domainError = nil
        }
    }
}
