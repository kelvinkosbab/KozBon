//
//  CreateOrUpdateBonjourServiceTypeViewModel.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourCore
import BonjourLocalization
import BonjourModels

// File-level disable: the type name is 41 chars, one over the
// SwiftLint default. Matches the paired View name
// `CreateOrUpdateBonjourServiceTypeView` (36 chars) plus the
// `Model` suffix used on every other VM in the module —
// renaming just to dodge the rule would force a different
// pattern from `BonjourChatViewModel` /
// `BonjourServicesViewModel` etc.
// swiftlint:disable type_name

// MARK: - CreateOrUpdateBonjourServiceTypeViewModel

/// View model for `CreateOrUpdateBonjourServiceTypeView` — owns
/// the three input strings (`name` / `type` / `details`), the
/// inline error states, the form-validity computed property,
/// and the `_type._transport` preview string used in the type
/// section's footer.
///
/// The mode (create vs. edit) is pinned at init via
/// ``isCreatingBonjourService`` and the three named factories
/// (``empty``, ``editing(_:)``, ``prefilled(name:type:details:)``).
/// `selectedTransportLayer` is a `let` because the form is
/// TCP-only — a UDP toggle would also need to thread through
/// the duplicate-check key, the persistent-copy lookup, and the
/// Insights footnote, so it's a deliberate single-axis form.
///
/// Persistence side effects (`deletePersistentCopy` /
/// `savePersistentCopy`) intentionally stay on the View, not
/// the VM — the VM's job ends at returning a validated
/// ``ValidatedInputs`` struct, and the View routes that to the
/// Core Data helpers and to the parent's
/// `serviceTypeToUpdate` binding. That split keeps the
/// validation logic unit-testable without spinning up a Core
/// Data stack.
@MainActor
@Observable
final class CreateOrUpdateBonjourServiceTypeViewModel {

    // MARK: - State

    /// Display name for the service type ("AirPlay", "Living
    /// Room HTTP", etc.).
    var name: String

    /// Inline validation error shown under the name field, or
    /// nil when there's no error to surface.
    var nameError: String?

    /// DNS-SD type identifier *without* the `_` prefix or the
    /// `._tcp` / `._udp` transport suffix — those are appended
    /// at preview/save time. `"http"`, `"airplay"`, etc.
    var type: String

    /// Inline validation error shown under the type field, or
    /// nil when there's no error to surface.
    var typeError: String?

    /// Free-form description used in service detail rows and as
    /// part of the AI Insights context for this type.
    var details: String

    /// Inline validation error shown under the details field, or
    /// nil when there's no error to surface.
    var detailsError: String?

    // MARK: - Long-Lived Dependencies

    /// `true` for the create-mode path (empty form OR pre-filled
    /// from the chat assistant's `prepareCustomServiceType`
    /// tool); `false` for the edit-mode path. Pinned at init so
    /// the View can't transition between modes mid-lifecycle.
    let isCreatingBonjourService: Bool

    /// The transport layer the form is fixed to. The whole form
    /// is TCP-only; see the type-level docstring for rationale.
    let selectedTransportLayer: TransportLayer = .tcp

    // MARK: - Init

    private init(
        name: String,
        type: String,
        details: String,
        isCreatingBonjourService: Bool
    ) {
        self.name = name
        self.type = type
        self.details = details
        self.isCreatingBonjourService = isCreatingBonjourService
    }

    // MARK: - Factories

    /// Create-mode VM: blank fields.
    static func empty() -> CreateOrUpdateBonjourServiceTypeViewModel {
        CreateOrUpdateBonjourServiceTypeViewModel(
            name: "",
            type: "",
            details: "",
            isCreatingBonjourService: true
        )
    }

    /// Edit-mode VM: pre-fills the fields from `existing`. The
    /// type field is non-editable in edit mode (the View
    /// `.disabled`s it) because changing the `(type, transport)`
    /// pair would orphan the existing Core Data row's identity.
    static func editing(
        _ existing: BonjourServiceType
    ) -> CreateOrUpdateBonjourServiceTypeViewModel {
        CreateOrUpdateBonjourServiceTypeViewModel(
            name: existing.name,
            type: existing.type,
            details: existing.detail ?? "",
            isCreatingBonjourService: false
        )
    }

    /// Create-mode VM pre-filled with values from the chat
    /// assistant's tool call. Mode stays "create" so the user
    /// can still edit any field and the Done button routes
    /// through the create-new persistence path. An empty or
    /// otherwise-invalid prefill simply renders an editable
    /// form with that text loaded — the regular per-field
    /// validation gates submission either way.
    static func prefilled(
        name: String,
        type: String,
        details: String
    ) -> CreateOrUpdateBonjourServiceTypeViewModel {
        CreateOrUpdateBonjourServiceTypeViewModel(
            name: name,
            type: type,
            details: details,
            isCreatingBonjourService: true
        )
    }

    // MARK: - Computed

    /// Whether the form has the minimum non-empty inputs needed
    /// for the Done button to enable. Trims internally so a
    /// whitespace-only field doesn't sneak through. Note: this
    /// is the *enable* gate — the same fields go through
    /// stricter `validate(...)` checks on actual submit
    /// (duplicate detection, etc.).
    var isFormValid: Bool {
        !name.trimmed.isEmpty
            && !type.trimmed.isEmpty
            && !details.trimmed.isEmpty
    }

    /// `_type._transport` preview string shown in the type
    /// section's footer (in blue) so the user sees the actual
    /// DNS-SD type they're about to register.
    var fullType: String {
        "_\(type)._\(selectedTransportLayer.string)"
    }

    // MARK: - Validate

    /// Validated, ready-to-persist form output returned by
    /// ``validate(existingServiceTypes:reduceMotion:)``.
    struct ValidatedInputs {
        let serviceType: BonjourServiceType
    }

    /// Validates the inputs and, on success, returns a
    /// ``ValidatedInputs`` containing the constructed
    /// `BonjourServiceType` ready to be persisted. On failure
    /// surfaces an inline error against the offending field and
    /// returns `nil`.
    ///
    /// Validation order:
    /// 1. name not empty
    /// 2. type not empty
    /// 3. details not empty
    /// 4. (create mode only) `(type, transport)` doesn't
    ///    already exist in the library
    ///
    /// Animations on every error mutation respect Reduce
    /// Motion (`reduceMotion == true` → no animation).
    ///
    /// - Parameters:
    ///   - existingServiceTypes: The library to check for the
    ///     duplicate-type rule. When `nil` (the production
    ///     default), `BonjourServiceType.exists(...)` falls
    ///     through to `fetchAll()` which reads the Core Data
    ///     custom-type store. Tests pass a controlled array to
    ///     bypass Core Data.
    ///   - reduceMotion: Whether to skip animation on error
    ///     mutations.
    func validate(
        existingServiceTypes: [BonjourServiceType]? = nil,
        reduceMotion: Bool
    ) -> ValidatedInputs? {
        let trimmedName = name.trimmed
        let trimmedType = type.trimmed
        let trimmedDetails = details.trimmed
        let animation: Animation? = reduceMotion ? nil : .default

        // Reset all three errors at the start of every submit so
        // a re-tap after a fix clears the stale message.
        withAnimation(animation) {
            nameError = nil
            typeError = nil
            detailsError = nil
        }

        guard !trimmedName.isEmpty else {
            withAnimation(animation) {
                nameError = String(localized: Strings.Errors.nameRequired)
            }
            return nil
        }

        guard !trimmedType.isEmpty else {
            withAnimation(animation) {
                typeError = String(localized: Strings.Errors.typeRequired)
            }
            return nil
        }

        guard !trimmedDetails.isEmpty else {
            withAnimation(animation) {
                detailsError = String(localized: Strings.Errors.detailsRequired)
            }
            return nil
        }

        if isCreatingBonjourService {
            let duplicate = BonjourServiceType.exists(
                serviceTypes: existingServiceTypes,
                type: trimmedType,
                transportLayer: selectedTransportLayer
            )
            if duplicate {
                withAnimation(animation) {
                    typeError = String(localized: Strings.Errors.alreadyExists)
                }
                return nil
            }
        }

        let serviceType = BonjourServiceType(
            name: trimmedName,
            type: trimmedType,
            transportLayer: selectedTransportLayer,
            detail: trimmedDetails
        )
        return ValidatedInputs(serviceType: serviceType)
    }

    /// Clears any inline validation errors when the user starts
    /// editing — fired by the View's `.onChange` on
    /// `[name, type, details]`. Only the field-specific error
    /// for fields that became non-empty is cleared, mirroring
    /// the original View's behavior (so an explicit "this type
    /// already exists" error stays visible until the user
    /// changes the type field's content).
    func clearErrorsOnEdit(reduceMotion: Bool) {
        let animation: Animation? = reduceMotion ? nil : .default
        withAnimation(animation) {
            if !name.trimmed.isEmpty {
                nameError = nil
            }
            if !type.trimmed.isEmpty {
                typeError = nil
            }
            if !details.trimmed.isEmpty {
                detailsError = nil
            }
        }
    }
}
