//
//  InMemoryAICloudCredentialsStore.swift
//  BonjourAICloud
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - InMemoryAICloudCredentialsStore

/// Non-persistent ``AICloudCredentialsStore`` for tests, previews,
/// and simulator builds where touching the real Keychain would
/// pollute developer machines or fail under sandbox limitations.
///
/// All state lives in a private dictionary and disappears with the
/// instance. Behavior matches the Keychain-backed store for the
/// observable surface: writing an empty string removes the entry,
/// missing-key removals succeed, presence checks reflect non-empty
/// values only.
public final class InMemoryAICloudCredentialsStore: AICloudCredentialsStore {

    // MARK: - Storage

    private var storage: [AICloudProvider: String] = [:]

    // MARK: - Init

    /// Creates an empty credentials store.
    ///
    /// - Parameter seed: Optional initial values. Useful for previews
    ///   that need a "signed-in" state without forcing the
    ///   surrounding test to call ``setAPIKey(_:for:)`` first.
    public init(seed: [AICloudProvider: String] = [:]) {
        for (provider, value) in seed where !value.isEmpty {
            storage[provider] = value
        }
    }

    // MARK: - AICloudCredentialsStore

    public func setAPIKey(_ apiKey: String, for provider: AICloudProvider) throws {
        if apiKey.isEmpty {
            storage.removeValue(forKey: provider)
        } else {
            storage[provider] = apiKey
        }
    }

    public func apiKey(for provider: AICloudProvider) throws -> String? {
        storage[provider]
    }

    public func removeAPIKey(for provider: AICloudProvider) throws {
        storage.removeValue(forKey: provider)
    }

    public func hasAPIKey(for provider: AICloudProvider) -> Bool {
        guard let value = storage[provider] else { return false }
        return !value.isEmpty
    }
}
