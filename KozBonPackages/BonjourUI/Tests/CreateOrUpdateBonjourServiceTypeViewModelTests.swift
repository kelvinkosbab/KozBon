//
//  CreateOrUpdateBonjourServiceTypeViewModelTests.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourCore
import BonjourLocalization
import BonjourModels
@testable import BonjourUI

// File-level disable matches the paired source file. The
// `<VMName>Tests` test type follows the same naming convention
// the rest of the module uses — see the source file for the
// full rationale.
// swiftlint:disable type_name

// MARK: - CreateOrUpdateBonjourServiceTypeViewModelTests

/// Pin the validate-and-construct pipeline that drives the
/// create-or-edit Bonjour service-type sheet. Persistence side
/// effects (`deletePersistentCopy` / `savePersistentCopy`) live
/// on the View, not the VM, so this whole suite runs under
/// `swift test` without a Core Data stack — duplicate-detection
/// tests inject a controlled `existingServiceTypes` array
/// rather than letting `BonjourServiceType.exists(...)` fall
/// through to `fetchAll()`.
@Suite("CreateOrUpdateBonjourServiceTypeViewModel")
@MainActor
struct CreateOrUpdateBonjourServiceTypeViewModelTests {

    // MARK: - Helpers

    private func type(_ type: String, name: String = "Whatever") -> BonjourServiceType {
        BonjourServiceType(
            name: name,
            type: type,
            transportLayer: .tcp,
            detail: "details"
        )
    }

    // MARK: - Factories

    @Test("`empty()` produces a create-mode VM with blank fields")
    func emptyFactoryStartsBlank() {
        let vm = CreateOrUpdateBonjourServiceTypeViewModel.empty()
        #expect(vm.name.isEmpty)
        #expect(vm.type.isEmpty)
        #expect(vm.details.isEmpty)
        #expect(vm.nameError == nil)
        #expect(vm.typeError == nil)
        #expect(vm.detailsError == nil)
        #expect(vm.isCreatingBonjourService)
        #expect(vm.selectedTransportLayer == .tcp)
    }

    @Test("`editing(_:)` pre-fills the fields from the existing type and pins update mode")
    func editingFactoryPrefillsAndPinsUpdateMode() {
        let existing = BonjourServiceType(
            name: "Living Room TV",
            type: "airplay",
            transportLayer: .tcp,
            detail: "AirPlay receiver"
        )
        let vm = CreateOrUpdateBonjourServiceTypeViewModel.editing(existing)
        #expect(vm.name == "Living Room TV")
        #expect(vm.type == "airplay")
        #expect(vm.details == "AirPlay receiver")
        #expect(!vm.isCreatingBonjourService)
    }

    @Test("`editing(_:)` falls back to an empty details string when the existing type's detail is nil")
    func editingFactoryHandlesNilDetail() {
        let existing = BonjourServiceType(
            name: "X",
            type: "x",
            transportLayer: .tcp,
            detail: nil
        )
        let vm = CreateOrUpdateBonjourServiceTypeViewModel.editing(existing)
        #expect(vm.details.isEmpty)
    }

    @Test("`prefilled(name:type:details:)` keeps create mode while loading values")
    func prefilledFactoryStaysInCreateMode() {
        let vm = CreateOrUpdateBonjourServiceTypeViewModel.prefilled(
            name: "MyService",
            type: "myservice",
            details: "Custom HTTP variant"
        )
        #expect(vm.name == "MyService")
        #expect(vm.type == "myservice")
        #expect(vm.details == "Custom HTTP variant")
        // Crucially still `true` so the Done button routes through
        // the create-new persistence path, not the update path.
        #expect(vm.isCreatingBonjourService)
    }

    // MARK: - isFormValid

    @Test("`isFormValid` is false when any field is empty")
    func formValidFalseWhenAnyEmpty() {
        let vm = CreateOrUpdateBonjourServiceTypeViewModel.empty()
        #expect(!vm.isFormValid)
        vm.name = "X"
        #expect(!vm.isFormValid)
        vm.type = "x"
        #expect(!vm.isFormValid)
        vm.details = "y"
        #expect(vm.isFormValid)
    }

    @Test("`isFormValid` trims whitespace before checking emptiness")
    func formValidTrimsWhitespace() {
        let vm = CreateOrUpdateBonjourServiceTypeViewModel.empty()
        vm.name = "   "
        vm.type = "   "
        vm.details = "   "
        // All-whitespace shouldn't enable the Done button.
        #expect(!vm.isFormValid)
    }

    // MARK: - fullType

    @Test("`fullType` formats the DNS-SD type with the leading underscore and `_tcp` suffix")
    func fullTypeFormat() {
        let vm = CreateOrUpdateBonjourServiceTypeViewModel.empty()
        vm.type = "http"
        #expect(vm.fullType == "_http._tcp")
    }

    @Test("`fullType` returns `_._tcp` for an empty type field — preview placeholder for an empty input")
    func fullTypeEmptyType() {
        let vm = CreateOrUpdateBonjourServiceTypeViewModel.empty()
        #expect(vm.fullType == "_._tcp")
    }

    // MARK: - Validation Failures

    @Test("`validate` returns nil and surfaces a name-required error when only the name is empty")
    func validateRejectsEmptyName() {
        let vm = CreateOrUpdateBonjourServiceTypeViewModel.empty()
        vm.type = "http"
        vm.details = "details"
        let result = vm.validate(existingServiceTypes: [], reduceMotion: true)
        #expect(result == nil)
        #expect(vm.nameError == String(localized: Strings.Errors.nameRequired))
        #expect(vm.typeError == nil)
        #expect(vm.detailsError == nil)
    }

    @Test("`validate` returns nil and surfaces a type-required error when the type is empty (name set)")
    func validateRejectsEmptyType() {
        let vm = CreateOrUpdateBonjourServiceTypeViewModel.empty()
        vm.name = "MyService"
        vm.details = "details"
        let result = vm.validate(existingServiceTypes: [], reduceMotion: true)
        #expect(result == nil)
        #expect(vm.nameError == nil)
        #expect(vm.typeError == String(localized: Strings.Errors.typeRequired))
    }

    @Test("`validate` returns nil and surfaces a details-required error when only details is empty")
    func validateRejectsEmptyDetails() {
        let vm = CreateOrUpdateBonjourServiceTypeViewModel.empty()
        vm.name = "MyService"
        vm.type = "http"
        let result = vm.validate(existingServiceTypes: [], reduceMotion: true)
        #expect(result == nil)
        #expect(vm.detailsError == String(localized: Strings.Errors.detailsRequired))
    }

    @Test("`validate` rejects whitespace-only inputs as if they were empty")
    func validateRejectsWhitespaceOnly() {
        let vm = CreateOrUpdateBonjourServiceTypeViewModel.empty()
        vm.name = "   "
        vm.type = "http"
        vm.details = "details"
        let result = vm.validate(existingServiceTypes: [], reduceMotion: true)
        #expect(result == nil)
        #expect(vm.nameError == String(localized: Strings.Errors.nameRequired))
    }

    @Test("`validate` enforces the validation order: name, then type, then details")
    func validateEnforcesOrder() {
        let vm = CreateOrUpdateBonjourServiceTypeViewModel.empty()
        // All empty — name rejects first.
        let result = vm.validate(existingServiceTypes: [], reduceMotion: true)
        #expect(result == nil)
        #expect(vm.nameError == String(localized: Strings.Errors.nameRequired))
        #expect(vm.typeError == nil)
        #expect(vm.detailsError == nil)
    }

    // MARK: - Duplicate-Type Rule (Create Mode Only)

    @Test("`validate` in create mode rejects when the type already exists in the injected library")
    func validateCreateModeRejectsDuplicate() {
        let vm = CreateOrUpdateBonjourServiceTypeViewModel.empty()
        vm.name = "MyHTTP"
        vm.type = "http"
        vm.details = "Custom variant"
        let library = [type("http")]
        let result = vm.validate(existingServiceTypes: library, reduceMotion: true)
        #expect(result == nil)
        #expect(vm.typeError == String(localized: Strings.Errors.alreadyExists))
    }

    @Test("`validate` in create mode allows a non-duplicate type")
    func validateCreateModeAllowsUniqueType() {
        let vm = CreateOrUpdateBonjourServiceTypeViewModel.empty()
        vm.name = "MyService"
        vm.type = "myservice"
        vm.details = "Custom"
        let library = [type("http"), type("airplay")]
        let result = vm.validate(existingServiceTypes: library, reduceMotion: true)
        #expect(result != nil)
        #expect(result?.serviceType.name == "MyService")
        #expect(result?.serviceType.type == "myservice")
        #expect(result?.serviceType.transportLayer == .tcp)
        #expect(result?.serviceType.detail == "Custom")
    }

    @Test("`validate` in edit mode skips the duplicate check entirely")
    func validateEditModeSkipsDuplicateCheck() {
        // Editing "http" → "http" should not flag as duplicate
        // even though the library has an entry with type "http"
        // (which is the very entry we're editing).
        let existing = BonjourServiceType(
            name: "HTTP",
            type: "http",
            transportLayer: .tcp,
            detail: "old details"
        )
        let vm = CreateOrUpdateBonjourServiceTypeViewModel.editing(existing)
        vm.details = "updated details"
        let result = vm.validate(existingServiceTypes: [existing], reduceMotion: true)
        #expect(result != nil)
        #expect(vm.typeError == nil)
        #expect(result?.serviceType.detail == "updated details")
    }

    // MARK: - Trim + Construct

    @Test("`validate` trims leading/trailing whitespace from all fields before constructing")
    func validateTrimsWhitespace() {
        let vm = CreateOrUpdateBonjourServiceTypeViewModel.empty()
        vm.name = "  MyService  "
        vm.type = "  http  "
        vm.details = "  Custom  "
        let result = vm.validate(existingServiceTypes: [], reduceMotion: true)
        #expect(result?.serviceType.name == "MyService")
        #expect(result?.serviceType.type == "http")
        #expect(result?.serviceType.detail == "Custom")
    }

    @Test("`validate` constructs the service type with the VM's pinned transport layer (.tcp)")
    func validateUsesPinnedTransport() {
        let vm = CreateOrUpdateBonjourServiceTypeViewModel.empty()
        vm.name = "X"
        vm.type = "x"
        vm.details = "y"
        let result = vm.validate(existingServiceTypes: [], reduceMotion: true)
        #expect(result?.serviceType.transportLayer == .tcp)
    }

    @Test("`validate` clears stale errors at the start of every call")
    func validateClearsStaleErrors() {
        let vm = CreateOrUpdateBonjourServiceTypeViewModel.empty()
        vm.nameError = "stale name error"
        vm.typeError = "stale type error"
        vm.detailsError = "stale details error"
        // Valid inputs.
        vm.name = "X"
        vm.type = "x"
        vm.details = "y"
        let result = vm.validate(existingServiceTypes: [], reduceMotion: true)
        #expect(result != nil)
        #expect(vm.nameError == nil)
        #expect(vm.typeError == nil)
        #expect(vm.detailsError == nil)
    }

    // MARK: - Clear Errors On Edit

    @Test("`clearErrorsOnEdit` clears `nameError` only when the name field is non-empty")
    func clearErrorsOnEditClearsByFieldNonEmptiness() {
        let vm = CreateOrUpdateBonjourServiceTypeViewModel.empty()
        vm.nameError = "stale"
        vm.typeError = "stale"
        vm.detailsError = "stale"
        // Only the name is non-empty — only nameError clears.
        // (Original View behavior: each per-field error clears
        // only when that specific field has content.)
        vm.name = "X"
        vm.type = ""
        vm.details = ""
        vm.clearErrorsOnEdit(reduceMotion: true)
        #expect(vm.nameError == nil)
        #expect(vm.typeError == "stale")
        #expect(vm.detailsError == "stale")
    }

    @Test("`clearErrorsOnEdit` clears all three errors when all fields are non-empty")
    func clearErrorsOnEditClearsAllWhenAllNonEmpty() {
        let vm = CreateOrUpdateBonjourServiceTypeViewModel.empty()
        vm.nameError = "stale"
        vm.typeError = "stale"
        vm.detailsError = "stale"
        vm.name = "X"
        vm.type = "x"
        vm.details = "y"
        vm.clearErrorsOnEdit(reduceMotion: true)
        #expect(vm.nameError == nil)
        #expect(vm.typeError == nil)
        #expect(vm.detailsError == nil)
    }

    @Test("`clearErrorsOnEdit` is a no-op when fields are still empty (errors stay surfaced)")
    func clearErrorsOnEditNoOpWhenFieldsEmpty() {
        let vm = CreateOrUpdateBonjourServiceTypeViewModel.empty()
        vm.nameError = "name still required"
        // No fields set yet — error should stay so the user sees
        // why submit failed.
        vm.clearErrorsOnEdit(reduceMotion: true)
        #expect(vm.nameError == "name still required")
    }
}
