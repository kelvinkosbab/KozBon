//
//  AICloudCredentialsStore.swift
//  BonjourAICloud
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - AICloudCredentialsStore

/// Abstraction over per-provider credential storage.
///
/// Production builds back this with the iOS Keychain
/// (``KeychainAICloudCredentialsStore``). Tests substitute
/// ``InMemoryAICloudCredentialsStore`` to avoid touching the real
/// Keychain.
///
/// The protocol is `@MainActor`-isolated because consumers
/// (`PreferencesStore`, the Settings UI) already live on the main
/// actor and the Keychain itself doesn't need a hop. Keeping the
/// isolation uniform avoids `await`-noise in call sites that are
/// already main-actor-bound.
@MainActor
public protocol AICloudCredentialsStore: AnyObject {

    /// Persists the API key for the given provider.
    ///
    /// Overwrites any existing value. Empty strings are treated as
    /// removal — implementations call ``removeAPIKey(for:)``
    /// internally rather than storing an empty entry.
    ///
    /// - Parameters:
    ///   - apiKey: The API key the user pasted in. Whitespace is
    ///     not trimmed here; callers should trim before invoking.
    ///   - provider: The provider the key belongs to.
    /// - Throws: ``AICloudError/keychainFailure(status:)`` if the
    ///   Keychain rejected the write.
    func setAPIKey(_ apiKey: String, for provider: AICloudProvider) throws

    /// Returns the stored API key for the given provider, or `nil`
    /// when no key is stored.
    ///
    /// - Parameter provider: The provider to read.
    /// - Returns: The API key, or `nil` when absent.
    /// - Throws: ``AICloudError/keychainFailure(status:)`` for read
    ///   failures other than `errSecItemNotFound` (which returns
    ///   `nil`).
    func apiKey(for provider: AICloudProvider) throws -> String?

    /// Deletes the stored API key for the given provider, if any.
    ///
    /// Missing-key removals are not errors — calling
    /// `removeAPIKey(for: .anthropic)` when no Anthropic key is
    /// stored is a successful no-op.
    func removeAPIKey(for provider: AICloudProvider) throws

    /// Whether a non-empty key is currently stored for the given
    /// provider.
    ///
    /// Equivalent to `apiKey(for:) != nil`, but lets callers avoid
    /// even reading the secret value when they only need to know
    /// "is this provider configured?".
    func hasAPIKey(for provider: AICloudProvider) -> Bool
}

// MARK: - Default Implementations

@MainActor
public extension AICloudCredentialsStore {

    /// Default implementation derived from ``apiKey(for:)``.
    ///
    /// Reads the value and discards it; concrete stores can
    /// override with a lighter-weight existence check when their
    /// backing store supports one (Keychain doesn't expose a
    /// presence query that's cheaper than a full read, so the
    /// production implementation accepts this default).
    func hasAPIKey(for provider: AICloudProvider) -> Bool {
        let value = (try? apiKey(for: provider)) ?? nil
        guard let value else { return false }
        return !value.isEmpty
    }
}
