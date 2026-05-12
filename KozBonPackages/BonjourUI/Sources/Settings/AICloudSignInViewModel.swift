//
//  AICloudSignInViewModel.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import OSLog
import BonjourAICloud

// MARK: - AICloudSignInViewModel

/// View model for the "Sign in to Claude" sheet.
///
/// Owns the API-key input string, the inline validation message,
/// and the save / cancel dispatch. Talks to the injected
/// ``AICloudCredentialsStore`` to persist; never reaches into the
/// Keychain directly.
///
/// Per the MVVM rule: long-lived dependencies (the credentials
/// store, the provider, the logger) are captured at init;
/// short-lived state lives as `@Observable`-tracked properties.
@MainActor
@Observable
final class AICloudSignInViewModel {

    // MARK: - State

    /// The text the user has typed into the API-key field. Bound
    /// to the `SecureField` in the sheet.
    var apiKey: String = ""

    /// Localized validation error to show under the field, or
    /// `nil` when the input is currently valid (or empty).
    /// Cleared when the user edits the field again.
    var validationMessage: String?

    // MARK: - Long-Lived Dependencies

    /// Whichever credentials store the parent view passed in.
    /// Production uses the Keychain-backed implementation;
    /// previews and tests pass an `InMemoryAICloudCredentialsStore`.
    private let credentialsStore: any AICloudCredentialsStore

    /// The provider we're signing into. Single value today
    /// (`.anthropic`) but parameterized so adding OpenAI / Gemini
    /// later doesn't restructure the view-model surface.
    private let provider: AICloudProvider

    /// Localized "save" error to surface in the sheet's footer when
    /// the Keychain write itself fails (rare — usually the user
    /// accepted but the access group rejected the write).
    var keychainError: String?

    private let logger = Logger(subsystem: "com.kozinga.KozBon", category: "AICloudSignIn")

    // MARK: - Init

    init(
        credentialsStore: any AICloudCredentialsStore,
        provider: AICloudProvider = .anthropic
    ) {
        self.credentialsStore = credentialsStore
        self.provider = provider
    }

    // MARK: - Computed

    /// Whether the Save button is enabled.
    ///
    /// The button stays disabled until the user has typed
    /// *something* that passes the lightweight format check
    /// (`sk-ant-` prefix for Anthropic). The full validity check
    /// happens server-side on the first request — we surface a
    /// clear inline error here only when the prefix is obviously
    /// wrong so users don't paste arbitrary text.
    var isSaveEnabled: Bool {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return looksLikeValidKey(trimmed)
    }

    // MARK: - Actions

    /// Validates the input against the lightweight format check
    /// and refreshes ``validationMessage``.
    ///
    /// Called as the user types so they get immediate feedback
    /// (rather than discovering on save that the paste didn't
    /// include the prefix).
    func validate(localizedInvalidKeyMessage: String) {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            // Empty isn't an error — the Save button is just disabled.
            validationMessage = nil
            return
        }
        validationMessage = looksLikeValidKey(trimmed) ? nil : localizedInvalidKeyMessage
    }

    /// Persists the trimmed API key. Surfaces a Keychain error in
    /// ``keychainError`` if the write fails. Returns `true` on
    /// success so the view can dismiss the sheet.
    func save() -> Bool {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        do {
            try credentialsStore.setAPIKey(trimmed, for: provider)
            keychainError = nil
            // Clear the field after a successful save so the
            // captured value doesn't linger in memory longer than
            // necessary.
            apiKey = ""
            return true
        } catch {
            logger.error("Failed to persist API key: \(error.localizedDescription)")
            keychainError = error.localizedDescription
            return false
        }
    }

    // MARK: - Private

    /// Lightweight prefix check. The real validation happens on the
    /// first API call — we only catch the "user pasted the wrong
    /// string" case here.
    private func looksLikeValidKey(_ value: String) -> Bool {
        switch provider {
        case .anthropic:
            return value.hasPrefix("sk-ant-") && value.count > "sk-ant-".count
        }
    }
}
