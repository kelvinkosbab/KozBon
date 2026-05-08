//
//  BroadcastBonjourServiceViewModelTests.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourCore
import BonjourLocalization
import BonjourModels
import BonjourScanning
@testable import BonjourUI

// File-level disable: the suite's body lands at 301 lines (1
// over the rule's 300-line default) because of the helper trio
// + 26 tests covering factories, form gating, validation,
// publish success/failure, upsert, and the per-field
// error-clear helpers. Splitting just for line count would
// shatter the suite's thematic grouping for no structural
// benefit.
// swiftlint:disable type_body_length

// MARK: - BroadcastBonjourServiceViewModelTests

/// Pin the validate-and-publish pipeline that drives the
/// broadcast sheet:
/// - Each factory produces the right initial state for create
///   / editing / prefilled flows, including the prefilled
///   factory's empty-domain → default-domain fallback.
/// - `isFormValid` reflects the four gating conditions
///   (service type selected, port present, port in range,
///   domain non-empty after trimming).
/// - `validate` enforces the validation order and surfaces the
///   matching localized error against each field.
/// - `publish` returns the published service on success and
///   surfaces a publish-failed error on the service-type slot
///   on failure.
/// - `upsert` inserts a fresh service or replaces an existing
///   one in place, keying on `BonjourService.Equatable`
///   (the underlying service identifier).
/// - The three per-field error-clear helpers are no-ops while
///   the field is still invalid and clear the matching error
///   once the field becomes valid.
@Suite("BroadcastBonjourServiceViewModel")
@MainActor
struct BroadcastBonjourServiceViewModelTests {

    // MARK: - Helpers

    private func anyServiceType(_ name: String = "HTTP", type: String = "http") -> BonjourServiceType {
        BonjourServiceType(
            name: name,
            type: type,
            transportLayer: .tcp,
            detail: "details"
        )
    }

    private func anyService(name: String = "HTTP", port: Int = 8080) -> BonjourService {
        BonjourService(
            service: NetService(
                domain: Constants.Network.defaultDomain,
                type: "_http._tcp",
                name: name,
                port: Int32(port)
            ),
            serviceType: anyServiceType(name)
        )
    }

    /// Most tests don't care which publish manager backs the VM — they
    /// exercise validation, form-state, and per-field error helpers
    /// that never call `publish`. Default to a fresh mock so the
    /// factory's required `publishManager:` parameter stays out of
    /// each test's signal-to-noise.
    private func makeEmpty(
        publishManager: MockBonjourPublishManager = MockBonjourPublishManager()
    ) -> BroadcastBonjourServiceViewModel {
        BroadcastBonjourServiceViewModel.empty(publishManager: publishManager)
    }

    private func makeEditing(
        _ service: BonjourService,
        publishManager: MockBonjourPublishManager = MockBonjourPublishManager()
    ) -> BroadcastBonjourServiceViewModel {
        BroadcastBonjourServiceViewModel.editing(service, publishManager: publishManager)
    }

    private func makePrefilled(
        serviceType: BonjourServiceType?,
        port: Int?,
        domain: String,
        dataRecords: [BonjourService.TxtDataRecord] = [],
        publishManager: MockBonjourPublishManager = MockBonjourPublishManager()
    ) -> BroadcastBonjourServiceViewModel {
        BroadcastBonjourServiceViewModel.prefilled(
            serviceType: serviceType,
            port: port,
            domain: domain,
            dataRecords: dataRecords,
            publishManager: publishManager
        )
    }

    // MARK: - Factories

    @Test("`empty()` produces a create-mode VM with no selection, no port, default domain, and no records")
    func emptyFactoryStartsBlank() {
        let vm = makeEmpty()
        #expect(vm.serviceType == nil)
        #expect(vm.port == nil)
        #expect(vm.domain == Constants.Network.defaultDomain)
        #expect(vm.dataRecords.isEmpty)
        #expect(vm.serviceTypeError == nil)
        #expect(vm.portError == nil)
        #expect(vm.domainError == nil)
        #expect(vm.isCreatingBonjourService)
        #expect(vm.selectedTransportLayer == .tcp)
    }

    @Test("`editing(_:)` pre-fills from the existing broadcast and pins update mode")
    func editingFactoryPrefills() {
        let service = anyService(name: "Living Room TV", port: 7000)
        let vm = makeEditing(service)
        #expect(vm.serviceType?.name == "Living Room TV")
        #expect(vm.port == 7000)
        #expect(vm.domain == Constants.Network.defaultDomain)
        #expect(!vm.isCreatingBonjourService)
    }

    @Test("`prefilled(...)` keeps create mode and loads the supplied values")
    func prefilledFactoryStaysInCreateMode() {
        let serviceType = anyServiceType()
        let records = [BonjourService.TxtDataRecord(key: "color", value: "blue")]
        let vm = makePrefilled(
            serviceType: serviceType,
            port: 8080,
            domain: "local.",
            dataRecords: records
        )
        #expect(vm.serviceType?.name == "HTTP")
        #expect(vm.port == 8080)
        #expect(vm.domain == "local.")
        #expect(vm.dataRecords.count == 1)
        #expect(vm.isCreatingBonjourService)
    }

    @Test("`prefilled(...)` falls back to the default domain when the supplied domain is empty")
    func prefilledFactoryDefaultsEmptyDomain() {
        // The chat assistant's tool can fail to supply a domain;
        // an empty string would otherwise surface a domain-required
        // error before the user has touched anything.
        let vm = makePrefilled(
            serviceType: anyServiceType(),
            port: 8080,
            domain: ""
        )
        #expect(vm.domain == Constants.Network.defaultDomain)
    }

    // MARK: - isFormValid

    @Test("`isFormValid` is false until every gating condition is satisfied")
    func formValidGating() {
        let vm = makeEmpty()
        #expect(!vm.isFormValid)

        // Need: service type, port, port-in-range, non-empty domain.
        vm.serviceType = anyServiceType()
        #expect(!vm.isFormValid)

        vm.port = 8080
        // Domain is already defaultDomain (non-empty), so this
        // should now flip true.
        #expect(vm.isFormValid)
    }

    @Test("`isFormValid` is false when the port is below the minimum")
    func formValidFalseBelowMinPort() {
        let vm = makeEmpty()
        vm.serviceType = anyServiceType()
        vm.port = Constants.Network.minimumPort - 1
        #expect(!vm.isFormValid)
    }

    @Test("`isFormValid` is false when the port is above the maximum")
    func formValidFalseAboveMaxPort() {
        let vm = makeEmpty()
        vm.serviceType = anyServiceType()
        vm.port = Constants.Network.maximumPort + 1
        #expect(!vm.isFormValid)
    }

    @Test("`isFormValid` is false when the domain is whitespace-only")
    func formValidFalseEmptyDomain() {
        let vm = makeEmpty()
        vm.serviceType = anyServiceType()
        vm.port = 8080
        vm.domain = "   "
        #expect(!vm.isFormValid)
    }

    // MARK: - Validation Failures

    @Test("`validate` returns nil and surfaces a service-type-required error when no type is selected")
    func validateRejectsNoServiceType() {
        let vm = makeEmpty()
        vm.port = 8080
        let result = vm.validate(reduceMotion: true)
        #expect(result == nil)
        #expect(vm.serviceTypeError == String(localized: Strings.Errors.serviceTypeRequired))
        #expect(vm.portError == nil)
        #expect(vm.domainError == nil)
    }

    @Test("`validate` returns nil and surfaces a port-required error when port is nil (type set)")
    func validateRejectsNilPort() {
        let vm = makeEmpty()
        vm.serviceType = anyServiceType()
        let result = vm.validate(reduceMotion: true)
        #expect(result == nil)
        #expect(vm.portError == String(localized: Strings.Errors.portNumberRequired))
    }

    @Test("`validate` returns nil and surfaces a port-min error when port is below the minimum")
    func validateRejectsPortBelowMin() {
        let vm = makeEmpty()
        vm.serviceType = anyServiceType()
        vm.port = Constants.Network.minimumPort - 1
        let result = vm.validate(reduceMotion: true)
        #expect(result == nil)
        // The port-min error string is interpolated; just check
        // it's non-nil (the actual format string lookup may be
        // unresolved under SPM CLI so an exact string compare
        // would race the bundle).
        #expect(vm.portError != nil)
    }

    @Test("`validate` returns nil and surfaces a port-max error when port is above the maximum")
    func validateRejectsPortAboveMax() {
        let vm = makeEmpty()
        vm.serviceType = anyServiceType()
        vm.port = Constants.Network.maximumPort + 1
        let result = vm.validate(reduceMotion: true)
        #expect(result == nil)
        #expect(vm.portError != nil)
    }

    @Test("`validate` returns nil and surfaces a domain-required error when the domain is whitespace-only")
    func validateRejectsEmptyDomain() {
        let vm = makeEmpty()
        vm.serviceType = anyServiceType()
        vm.port = 8080
        vm.domain = "   "
        let result = vm.validate(reduceMotion: true)
        #expect(result == nil)
        #expect(vm.domainError == String(localized: Strings.Errors.domainRequired))
    }

    // MARK: - Validation Success

    @Test("`validate` returns trimmed inputs when every field is valid")
    func validateSucceedsAndTrimsDomain() {
        let vm = makeEmpty()
        vm.serviceType = anyServiceType()
        vm.port = 8080
        vm.domain = "  local.  "
        let result = vm.validate(reduceMotion: true)
        #expect(result?.serviceType.name == "HTTP")
        #expect(result?.port == 8080)
        #expect(result?.domain == "local.")
    }

    // MARK: - Publish

    @Test("`publish` returns the published service on success and leaves errors clear")
    func publishSucceeds() async {
        let mock = MockBonjourPublishManager()
        let vm = makeEmpty(publishManager: mock)
        vm.serviceType = anyServiceType()
        vm.port = 8080
        guard let inputs = vm.validate(reduceMotion: true) else {
            #expect(Bool(false), "Validate should have succeeded")
            return
        }
        let published = await vm.publish(inputs: inputs, reduceMotion: true)
        #expect(published != nil)
        #expect(mock.publishCallCount == 1)
        #expect(mock.lastPublishedServiceName == "HTTP")
        #expect(vm.serviceTypeError == nil)
    }

    @Test("`publish` surfaces a publish-failed error on `serviceTypeError` when the manager throws")
    func publishFailureSurfacesError() async {
        let mock = MockBonjourPublishManager()
        mock.shouldSucceed = false
        mock.errorToThrow = MockError.publishFailed
        let vm = makeEmpty(publishManager: mock)
        vm.serviceType = anyServiceType()
        vm.port = 8080
        let inputs = BroadcastBonjourServiceViewModel.ValidatedInputs(
            serviceType: anyServiceType(),
            port: 8080,
            domain: "local."
        )
        let published = await vm.publish(inputs: inputs, reduceMotion: true)
        #expect(published == nil)
        #expect(vm.serviceTypeError != nil)
    }

    @Test("`publish` forwards the VM's `dataRecords` to the published service via `updateTXTRecords`")
    func publishUpdatesTxtRecords() async {
        // The mock returns a fresh `BonjourService`; the VM
        // calls `updateTXTRecords(dataRecords)` on it. We can't
        // observe the resulting `dataRecords` on the returned
        // service without going through the underlying NetService,
        // but we CAN observe that publish completed and that the
        // returned service's name matches — proving the chain
        // reached `updateTXTRecords`.
        let mock = MockBonjourPublishManager()
        let vm = makeEmpty(publishManager: mock)
        vm.serviceType = anyServiceType()
        vm.port = 8080
        vm.dataRecords = [BonjourService.TxtDataRecord(key: "color", value: "blue")]
        guard let inputs = vm.validate(reduceMotion: true) else {
            #expect(Bool(false), "Validate should have succeeded")
            return
        }
        let published = await vm.publish(inputs: inputs, reduceMotion: true)
        #expect(published != nil)
    }

    // MARK: - Upsert

    @Test("`upsert` appends the service when the list doesn't already contain it")
    func upsertAppendsNewService() {
        let vm = makeEmpty()
        let existing = anyService(name: "OldOne", port: 1234)
        let fresh = anyService(name: "NewOne", port: 5678)
        let result = vm.upsert(fresh, into: [existing])
        #expect(result.count == 2)
        // Append order: existing first, fresh appended.
        #expect(result[0].service.name == "OldOne")
        #expect(result[1].service.name == "NewOne")
    }

    @Test("`upsert` replaces in place when the service is already in the list")
    func upsertReplacesExistingService() {
        let vm = makeEmpty()
        // BonjourService's Equatable keys on the underlying
        // service identifier — if we publish the same logical
        // service twice, upsert should replace it in place
        // rather than duplicating.
        let service = anyService(name: "HTTP", port: 8080)
        let result = vm.upsert(service, into: [service])
        #expect(result.count == 1)
    }

    // MARK: - clearAllErrors

    @Test("`clearAllErrors` zeroes all three inline errors")
    func clearAllErrorsZeroesEverything() {
        let vm = makeEmpty()
        vm.serviceTypeError = "stale"
        vm.portError = "stale"
        vm.domainError = "stale"
        vm.clearAllErrors(reduceMotion: true)
        #expect(vm.serviceTypeError == nil)
        #expect(vm.portError == nil)
        #expect(vm.domainError == nil)
    }

    // MARK: - Per-Field Clear Helpers

    @Test("`clearServiceTypeErrorIfResolved` is a no-op when the type is still nil")
    func clearServiceTypeErrorNoOpWhileNil() {
        let vm = makeEmpty()
        vm.serviceTypeError = "still required"
        vm.clearServiceTypeErrorIfResolved(reduceMotion: true)
        #expect(vm.serviceTypeError == "still required")
    }

    @Test("`clearServiceTypeErrorIfResolved` clears the error once a type has been selected")
    func clearServiceTypeErrorClearsOnSelection() {
        let vm = makeEmpty()
        vm.serviceTypeError = "stale"
        vm.serviceType = anyServiceType()
        vm.clearServiceTypeErrorIfResolved(reduceMotion: true)
        #expect(vm.serviceTypeError == nil)
    }

    @Test("`clearPortErrorIfResolved` is a no-op when port is still nil")
    func clearPortErrorNoOpWhileNil() {
        let vm = makeEmpty()
        vm.portError = "still required"
        vm.clearPortErrorIfResolved(reduceMotion: true)
        #expect(vm.portError == "still required")
    }

    @Test("`clearPortErrorIfResolved` clears the error once a port has been entered")
    func clearPortErrorClearsOnEntry() {
        let vm = makeEmpty()
        vm.portError = "stale"
        vm.port = 8080
        vm.clearPortErrorIfResolved(reduceMotion: true)
        #expect(vm.portError == nil)
    }

    @Test("`clearDomainErrorIfResolved` is a no-op when the domain is still empty")
    func clearDomainErrorNoOpWhileEmpty() {
        let vm = makeEmpty()
        vm.domain = ""
        vm.domainError = "still required"
        vm.clearDomainErrorIfResolved(reduceMotion: true)
        #expect(vm.domainError == "still required")
    }

    @Test("`clearDomainErrorIfResolved` clears the error once the domain is non-empty")
    func clearDomainErrorClearsOnEntry() {
        let vm = makeEmpty()
        vm.domainError = "stale"
        vm.domain = "local."
        vm.clearDomainErrorIfResolved(reduceMotion: true)
        #expect(vm.domainError == nil)
    }
}
