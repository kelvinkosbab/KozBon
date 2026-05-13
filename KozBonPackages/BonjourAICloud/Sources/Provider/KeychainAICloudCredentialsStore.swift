//
//  KeychainAICloudCredentialsStore.swift
//  BonjourAICloud
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Security

// MARK: - KeychainAICloudCredentialsStore

/// iOS / macOS Keychain-backed implementation of
/// ``AICloudCredentialsStore``.
///
/// Stores each provider's API key as a `kSecClassGenericPassword`
/// item keyed by the provider's raw value plus a fixed service
/// identifier. The service identifier is what the Keychain UI
/// surfaces to the user if they ever inspect their stored
/// credentials (Settings → Passwords → KozBon AI Provider).
///
/// ADR 0005 requires that KozBon never store API keys outside the
/// device's secure storage. This is the only place in the codebase
/// that reads or writes the raw key string; every other layer
/// works with this store as an injected dependency.
public final class KeychainAICloudCredentialsStore: AICloudCredentialsStore {

    // MARK: - Service Identifier

    /// The `kSecAttrService` value used for all Keychain entries
    /// this store writes.
    ///
    /// Stable for the lifetime of the app — changing it would
    /// orphan every user's stored key. Bumping the identifier is
    /// effectively a migration that the app would need to handle.
    public static let serviceIdentifier = "com.kozinga.KozBon.AICloud"

    /// Service identifier used by this instance.
    ///
    /// Defaults to ``serviceIdentifier`` for production use; tests
    /// pass a unique value per test method so parallel test
    /// execution doesn't collide on shared Keychain state.
    private let service: String

    // MARK: - Init

    /// Creates a Keychain-backed credentials store.
    ///
    /// - Parameter service: Optional override for the
    ///   `kSecAttrService` value. Defaults to
    ///   ``serviceIdentifier``. Tests pass a unique string per
    ///   test method.
    public init(service: String = KeychainAICloudCredentialsStore.serviceIdentifier) {
        self.service = service
    }

    // MARK: - AICloudCredentialsStore

    public func setAPIKey(_ apiKey: String, for provider: AICloudProvider) throws {
        guard !apiKey.isEmpty else {
            try removeAPIKey(for: provider)
            return
        }

        guard let data = apiKey.data(using: .utf8) else {
            throw AICloudError.keychainFailure(status: errSecParam)
        }

        let query: [String: Any] = baseQuery(for: provider)
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        switch updateStatus {
        case errSecSuccess:
            postCredentialsChanged()
            return
        case errSecItemNotFound:
            var addQuery = query
            addQuery[kSecValueData as String] = data
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            if addStatus != errSecSuccess {
                throw AICloudError.keychainFailure(status: addStatus)
            }
            postCredentialsChanged()
        default:
            throw AICloudError.keychainFailure(status: updateStatus)
        }
    }

    public func apiKey(for provider: AICloudProvider) throws -> String? {
        var query = baseQuery(for: provider)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        switch status {
        case errSecSuccess:
            guard let data = item as? Data, let value = String(data: data, encoding: .utf8) else {
                return nil
            }
            return value.isEmpty ? nil : value
        case errSecItemNotFound:
            return nil
        default:
            throw AICloudError.keychainFailure(status: status)
        }
    }

    public func removeAPIKey(for provider: AICloudProvider) throws {
        let status = SecItemDelete(baseQuery(for: provider) as CFDictionary)
        switch status {
        case errSecSuccess:
            postCredentialsChanged()
        case errSecItemNotFound:
            // Nothing actually changed — skip the notification
            // so observers don't get woken up for a no-op.
            return
        default:
            throw AICloudError.keychainFailure(status: status)
        }
    }

    // MARK: - Private

    /// Posts `Notification.Name.aiCloudCredentialsChanged` on
    /// the default center. Observers (notably `AppCoreScene`)
    /// re-run the cloud-aware factories so a mid-session
    /// sign-in / sign-out takes effect without an app restart.
    private func postCredentialsChanged() {
        NotificationCenter.default.post(name: .aiCloudCredentialsChanged, object: self)
    }

    /// The shared query dictionary identifying a single provider's
    /// item. Callers append `kSecReturnData`, `kSecMatchLimit`, or
    /// `kSecValueData` as needed.
    private func baseQuery(for provider: AICloudProvider) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider.rawValue,
            // `whenUnlockedThisDeviceOnly` keeps the key off iCloud
            // Keychain — the user's API key is bound to this device.
            // They paste it again on a new device (which they expect:
            // it's their API key, not the app's).
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
    }
}
