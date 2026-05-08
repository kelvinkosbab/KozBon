//
//  CreateTxtRecordViewModelTests.swift
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

// MARK: - CreateTxtRecordViewModelTests

/// Pin the validate-and-commit pipeline that drives the
/// create-or-edit TXT-record sheet:
/// - The two factory methods produce the right initial state for
///   create vs. update mode.
/// - Empty key / empty value / duplicate-key validation rejects in
///   the right order, surfacing the matching localized error.
/// - Update-mode duplicate-key is allowed when the duplicate is
///   the slot we're replacing.
/// - On success, the returned array reflects an append (create
///   mode) or an in-place replacement at the original key's
///   index (update mode).
/// - `clearErrorsOnEdit` is a no-op when no error is set, but
///   clears both errors otherwise.
@Suite("CreateTxtRecordViewModel")
@MainActor
struct CreateTxtRecordViewModelTests {

    // MARK: - Helpers

    private func record(_ key: String, _ value: String) -> BonjourService.TxtDataRecord {
        BonjourService.TxtDataRecord(key: key, value: value)
    }

    // MARK: - Factories

    @Test("`empty()` produces a VM with blank fields and no record-to-update")
    func emptyFactoryStartsBlank() {
        let vm = CreateTxtRecordViewModel.empty()
        #expect(vm.key.isEmpty)
        #expect(vm.value.isEmpty)
        #expect(vm.keyError == nil)
        #expect(vm.valueError == nil)
        #expect(vm.txtRecordToUpdate == nil)
    }

    @Test("`editing(_:)` pre-fills the fields with the existing record's key/value and pins the original")
    func editingFactoryPrefills() {
        let existing = record("color", "blue")
        let vm = CreateTxtRecordViewModel.editing(existing)
        #expect(vm.key == "color")
        #expect(vm.value == "blue")
        #expect(vm.keyError == nil)
        #expect(vm.valueError == nil)
        #expect(vm.txtRecordToUpdate?.key == "color")
        #expect(vm.txtRecordToUpdate?.value == "blue")
    }

    // MARK: - Validation Failures

    @Test("`submit` returns nil and surfaces a key-required error when the key is empty")
    func submitRejectsEmptyKey() {
        let vm = CreateTxtRecordViewModel.empty()
        vm.value = "blue"
        let result = vm.submit(currentRecords: [], reduceMotion: true)
        #expect(result == nil)
        #expect(vm.keyError == String(localized: Strings.Errors.txtKeyRequired))
        #expect(vm.valueError == nil)
    }

    @Test("`submit` returns nil and surfaces a key-required error when the key is whitespace-only")
    func submitRejectsWhitespaceKey() {
        // `String.trimmed` uses `.whitespaces` (not `.whitespacesAndNewlines`)
        // so the rejection path only fires for spaces/tabs, not
        // newlines. Match that contract: a key of just `   \t`
        // trims to empty and is rejected.
        let vm = CreateTxtRecordViewModel.empty()
        vm.key = "   \t"
        vm.value = "blue"
        let result = vm.submit(currentRecords: [], reduceMotion: true)
        #expect(result == nil)
        #expect(vm.keyError == String(localized: Strings.Errors.txtKeyRequired))
    }

    @Test("`submit` returns nil and surfaces a value-required error when only the value is empty")
    func submitRejectsEmptyValue() {
        let vm = CreateTxtRecordViewModel.empty()
        vm.key = "color"
        let result = vm.submit(currentRecords: [], reduceMotion: true)
        #expect(result == nil)
        #expect(vm.keyError == nil)
        #expect(vm.valueError == String(localized: Strings.Errors.txtValueRequired))
    }

    @Test("`submit` rejects key first when both fields are empty")
    func submitRejectsKeyBeforeValueWhenBothEmpty() {
        let vm = CreateTxtRecordViewModel.empty()
        let result = vm.submit(currentRecords: [], reduceMotion: true)
        #expect(result == nil)
        #expect(vm.keyError == String(localized: Strings.Errors.txtKeyRequired))
        // Value error stays nil — the validator returns after
        // surfacing the first failure so the user sees one
        // message at a time.
        #expect(vm.valueError == nil)
    }

    @Test("`submit` rejects a duplicate key in create mode")
    func submitRejectsDuplicateKeyInCreateMode() {
        let vm = CreateTxtRecordViewModel.empty()
        vm.key = "color"
        vm.value = "blue"
        let existing = [record("color", "red")]
        let result = vm.submit(currentRecords: existing, reduceMotion: true)
        #expect(result == nil)
        #expect(vm.keyError == String(localized: Strings.Errors.txtKeyDuplicate))
    }

    @Test("`submit` rejects a duplicate key in update mode when the user renames to a different existing key")
    func submitRejectsDuplicateKeyInUpdateModeWhenRenamingToCollision() {
        // Editing "color"/red but renaming to "size" — and "size"
        // is already in the array. Should reject (we'd lose the
        // existing "size" record otherwise).
        let original = record("color", "red")
        let vm = CreateTxtRecordViewModel.editing(original)
        vm.key = "size"
        vm.value = "large"
        let existing = [original, record("size", "small")]
        let result = vm.submit(currentRecords: existing, reduceMotion: true)
        #expect(result == nil)
        #expect(vm.keyError == String(localized: Strings.Errors.txtKeyDuplicate))
    }

    // MARK: - Update Mode: Duplicate Allowed When Replacing Same Key

    @Test("`submit` in update mode allows the duplicate when the user is replacing the same record")
    func submitAllowsDuplicateInUpdateModeWhenReplacingSameKey() {
        // The user opens "color"/red to edit, changes the value
        // to "blue", and submits. The array still has a record
        // with key "color" — but it's the slot we're replacing,
        // so the duplicate check skips it.
        let original = record("color", "red")
        let vm = CreateTxtRecordViewModel.editing(original)
        vm.value = "blue"
        let existing = [original]
        let result = vm.submit(currentRecords: existing, reduceMotion: true)
        #expect(vm.keyError == nil)
        #expect(result?.count == 1)
        #expect(result?[0].key == "color")
        #expect(result?[0].value == "blue")
    }

    // MARK: - Success Paths

    @Test("`submit` in create mode appends the new record to the array")
    func submitCreateModeAppends() {
        let vm = CreateTxtRecordViewModel.empty()
        vm.key = "color"
        vm.value = "blue"
        let existing = [record("size", "small")]
        let result = vm.submit(currentRecords: existing, reduceMotion: true)
        #expect(result?.count == 2)
        #expect(result?[0].key == "size") // existing preserved
        #expect(result?[1].key == "color")
        #expect(result?[1].value == "blue")
    }

    @Test("`submit` in update mode replaces the record in place at its original index")
    func submitUpdateModeReplacesInPlace() {
        let original = record("color", "red")
        let vm = CreateTxtRecordViewModel.editing(original)
        vm.value = "blue"
        // Original is at index 1 — replacement should land back
        // at index 1, preserving the surrounding entries' order.
        let existing = [
            record("size", "small"),
            original,
            record("shape", "round")
        ]
        let result = vm.submit(currentRecords: existing, reduceMotion: true)
        #expect(result?.count == 3)
        #expect(result?[0].key == "size")
        #expect(result?[1].key == "color")
        #expect(result?[1].value == "blue")
        #expect(result?[2].key == "shape")
    }

    @Test("`submit` in update mode renames the key in place when the new key isn't a duplicate")
    func submitUpdateModeRenamesKeyInPlace() {
        // The user opens "color"/red, renames it to "hue", and
        // submits. The replacement is keyed on the *original*
        // key for index lookup, so it lands in the same slot.
        let original = record("color", "red")
        let vm = CreateTxtRecordViewModel.editing(original)
        vm.key = "hue"
        vm.value = "blue"
        let existing = [original, record("size", "small")]
        let result = vm.submit(currentRecords: existing, reduceMotion: true)
        #expect(result?.count == 2)
        #expect(result?[0].key == "hue")
        #expect(result?[0].value == "blue")
        #expect(result?[1].key == "size")
    }

    @Test("`submit` trims leading/trailing whitespace from key and value before storing")
    func submitTrimsWhitespace() {
        let vm = CreateTxtRecordViewModel.empty()
        vm.key = "  color  "
        vm.value = "  blue  "
        let result = vm.submit(currentRecords: [], reduceMotion: true)
        #expect(result?[0].key == "color")
        #expect(result?[0].value == "blue")
    }

    @Test("`submit` clears stale errors at the start of every call")
    func submitClearsStaleErrors() {
        let vm = CreateTxtRecordViewModel.empty()
        // Seed a stale error.
        vm.keyError = "stale key error"
        vm.valueError = "stale value error"
        // Valid inputs.
        vm.key = "color"
        vm.value = "blue"
        let result = vm.submit(currentRecords: [], reduceMotion: true)
        #expect(result != nil)
        #expect(vm.keyError == nil)
        #expect(vm.valueError == nil)
    }

    // MARK: - Clear Errors On Edit

    @Test("`clearErrorsOnEdit` is a no-op when no error is set")
    func clearErrorsOnEditNoOpWhenClean() {
        let vm = CreateTxtRecordViewModel.empty()
        // Both errors start nil — nothing to clear.
        vm.clearErrorsOnEdit(reduceMotion: true)
        #expect(vm.keyError == nil)
        #expect(vm.valueError == nil)
    }

    @Test("`clearErrorsOnEdit` clears both errors when either is set")
    func clearErrorsOnEditClearsBoth() {
        let vm = CreateTxtRecordViewModel.empty()
        vm.keyError = "some key error"
        vm.valueError = nil
        vm.clearErrorsOnEdit(reduceMotion: true)
        #expect(vm.keyError == nil)
        #expect(vm.valueError == nil)
    }
}
