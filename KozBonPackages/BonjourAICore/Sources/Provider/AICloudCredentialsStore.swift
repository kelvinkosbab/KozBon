//
//  AICloudCredentialsStore.swift
//  BonjourAICore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - Notifications

public extension Notification.Name {

    /// Posted after any successful write to an
    /// ``AICloudCredentialsStore`` — key added, updated, or
    /// removed. The notification carries no user info; observers
    /// re-query whichever provider's state they care about
    /// rather than relying on payload data.
    ///
    /// `AppCoreScene` listens for this and re-invokes the
    /// cloud-aware factories so a sign-in (or sign-out) takes
    /// effect mid-session without an app restart. Without this
    /// notification, the factory's captured-at-init view of
    /// "is the user signed in?" would stay stale until the next
    /// `aiBackend` / `aiCloudModel` preference change happened
    /// to fire `.onChange`, which after a fresh sign-in isn't
    /// the next thing the user does.
    static let aiCloudCredentialsChanged = Notification.Name(
        "com.kozinga.KozBon.aiCloudCredentialsChanged"
    )

    /// Posted when a surface elsewhere in the app (the Insights
    /// long-press menu when no cloud key is configured) wants
    /// the scene-level sign-in sheet to mount. `userInfo`
    /// carries the provider under
    /// ``aiCloudSignInRequestedProviderKey`` as the raw value
    /// string so observers don't need to import the cloud
    /// modules. ``AppCoreScene`` listens and presents the
    /// matching `AICloudSignInSheet`.
    static let aiCloudSignInRequested = Notification.Name(
        "com.kozinga.KozBon.aiCloudSignInRequested"
    )
}

/// Key into `Notification.userInfo` for the
/// ``Notification.Name/aiCloudSignInRequested`` payload — the
/// provider's `rawValue` (`"anthropic"` or `"github"`).
public let aiCloudSignInRequestedProviderKey = "provider"

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
