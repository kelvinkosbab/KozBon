//
//  CreateTxtRecordViewModel.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourCore
import BonjourLocalization
import BonjourModels

// MARK: - CreateTxtRecordViewModel

/// View model for `CreateTxtRecordView` — owns the key / value
/// input strings, the inline error states, and the validation
/// pipeline that runs on Done.
///
/// The parent's `txtDataRecords` array (the existing TXT records
/// on the broadcast) is short-lived from the VM's perspective:
/// it can change while the form is presented (in theory) and the
/// VM doesn't need a reference to it for any other purpose. So
/// it's passed into ``submit(currentRecords:reduceMotion:)`` at
/// commit time rather than captured at init — same pattern as
/// the `@Environment` plumbing rule in
/// `.claude/rules/mvvm.md`.
///
/// `txtRecordToUpdate` is the long-lived dependency: it pins the
/// VM's mode (create vs. update) for its entire lifetime, and the
/// duplicate-key validation needs to know about it on every
/// submit.
@MainActor
@Observable
final class CreateTxtRecordViewModel {

    // MARK: - State

    /// Key field — the TXT record's name.
    var key: String

    /// Inline validation error shown under the key field, or nil
    /// when there's no error to surface.
    var keyError: String?

    /// Value field — the TXT record's value.
    var value: String

    /// Inline validation error shown under the value field, or
    /// nil when there's no error to surface.
    var valueError: String?

    // MARK: - Long-Lived Dependencies

    /// The existing record being updated, or nil for create
    /// mode. Pinned at init — the VM can't transition between
    /// create and update mode mid-lifecycle.
    let txtRecordToUpdate: BonjourService.TxtDataRecord?

    // MARK: - Init

    private init(
        key: String,
        value: String,
        txtRecordToUpdate: BonjourService.TxtDataRecord?
    ) {
        self.key = key
        self.value = value
        self.txtRecordToUpdate = txtRecordToUpdate
    }

    // MARK: - Factories

    /// Create-mode VM: blank key / value, no record to update.
    static func empty() -> CreateTxtRecordViewModel {
        CreateTxtRecordViewModel(
            key: "",
            value: "",
            txtRecordToUpdate: nil
        )
    }

    /// Update-mode VM: pre-fills the fields with `existing`'s
    /// key / value and pins the original record so the duplicate-
    /// key check during submit ignores the slot we're replacing.
    static func editing(
        _ existing: BonjourService.TxtDataRecord
    ) -> CreateTxtRecordViewModel {
        CreateTxtRecordViewModel(
            key: existing.key,
            value: existing.value,
            txtRecordToUpdate: existing
        )
    }

    // MARK: - Validate + Commit

    /// Validates the inputs against `currentRecords` and, on
    /// success, returns the updated array. On any validation
    /// failure, surfaces an inline error and returns nil so the
    /// caller knows not to dismiss the sheet.
    ///
    /// The animation wraps every error mutation so SwiftUI
    /// animates the inline messages in respecting the user's
    /// Reduce Motion preference. The View just forwards
    /// `reduceMotion` from `@Environment` — VMs intentionally
    /// don't read `@Environment` directly (see `mvvm.md`).
    ///
    /// - Parameters:
    ///   - currentRecords: The existing TXT-record list on the
    ///     broadcast; used for the duplicate-key check.
    ///   - reduceMotion: Whether to skip animation on error
    ///     mutations.
    /// - Returns: The updated array (with the new record
    ///   inserted or the existing one replaced) on success;
    ///   `nil` after surfacing the first validation error.
    func submit(
        currentRecords: [BonjourService.TxtDataRecord],
        reduceMotion: Bool
    ) -> [BonjourService.TxtDataRecord]? {
        let trimmedKey = key.trimmed
        let trimmedValue = value.trimmed
        let animation: Animation? = reduceMotion ? nil : .default

        // Reset both errors at the start of every submit so a
        // re-tap after a fix clears the stale message even if
        // we're about to set a new one below.
        withAnimation(animation) {
            keyError = nil
            valueError = nil
        }

        guard !trimmedKey.isEmpty else {
            withAnimation(animation) {
                keyError = String(localized: Strings.Errors.txtKeyRequired)
            }
            return nil
        }

        guard !trimmedValue.isEmpty else {
            withAnimation(animation) {
                valueError = String(localized: Strings.Errors.txtValueRequired)
            }
            return nil
        }

        // Duplicate-key check — skipped when we're updating an
        // existing record AND the existing record's key matches
        // the one already in the array (since we'll replace it,
        // not insert alongside).
        let isDuplicate = currentRecords.contains { $0.key == trimmedKey }
        let isReplacingSameKey = txtRecordToUpdate?.key == trimmedKey
        if isDuplicate && !isReplacingSameKey {
            withAnimation(animation) {
                keyError = String(localized: Strings.Errors.txtKeyDuplicate)
            }
            return nil
        }

        let newRecord = BonjourService.TxtDataRecord(
            key: trimmedKey,
            value: trimmedValue
        )

        // Replace if we're in update-mode AND the original key
        // is still in the array; otherwise append. The
        // `firstIndex` lookup keys on the *original* record's
        // key, not the new one — the user might have renamed
        // the key, so the array slot is still keyed on what
        // was there before they edited.
        var updated = currentRecords
        if let originalKey = txtRecordToUpdate?.key,
           let oldIndex = updated.firstIndex(where: { $0.key == originalKey }) {
            updated[oldIndex] = newRecord
        } else {
            updated.append(newRecord)
        }
        return updated
    }

    /// Clears any inline validation errors when the user starts
    /// editing a field — fired by the View's `.onChange` on the
    /// `[key, value]` array. The animation respects Reduce
    /// Motion. No-ops when neither error is set so we don't
    /// trigger spurious animations on every keystroke.
    func clearErrorsOnEdit(reduceMotion: Bool) {
        guard keyError != nil || valueError != nil else { return }
        let animation: Animation? = reduceMotion ? nil : .default
        withAnimation(animation) {
            keyError = nil
            valueError = nil
        }
    }
}
