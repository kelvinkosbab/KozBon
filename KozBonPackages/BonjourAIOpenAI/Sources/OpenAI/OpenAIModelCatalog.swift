//
//  OpenAIModelCatalog.swift
//  BonjourAIOpenAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourCore

// MARK: - OpenAIModelCatalog

/// Fetches the list of OpenAI models the user's own API key can
/// call, so the Settings picker tracks OpenAI's lineup without
/// waiting for an App Store update.
///
/// Same three-tier resolution as ``GeminiModelCatalog``: a fresh
/// `GET /v1/models` fetch, then this session's cached copy (TTL
/// bounded, in-memory only), then
/// ``OpenAIModelOption/builtInOptions`` when there's no key, no
/// network, or the request fails.
@MainActor
@Observable
public final class OpenAIModelCatalog {

    // MARK: - State

    /// The options to show in the picker. Starts as the built-in
    /// fallback so the UI always has something to render.
    public private(set) var options: [OpenAIModelOption] = OpenAIModelOption.builtInOptions

    /// Whether a refresh is in flight.
    public private(set) var isRefreshing = false

    /// Whether ``options`` reflects a successful live fetch.
    public private(set) var isLive = false

    /// When the last successful fetch completed.
    public private(set) var lastRefreshDate: Date?

    // MARK: - Dependencies

    private let client: any OpenAIModelCatalogClientProtocol
    private let timeToLive: TimeInterval
    private let now: () -> Date

    private let logger: Loggable = Logger(category: "OpenAIModelCatalog")

    // MARK: - Init

    /// - Parameters:
    ///   - client: Performs the `/v1/models` request.
    ///   - timeToLive: How long a successful fetch stays fresh.
    ///   - now: Clock injection point.
    public init(
        client: any OpenAIModelCatalogClientProtocol = OpenAIModelCatalogClient(),
        timeToLive: TimeInterval = 3600,
        now: @escaping () -> Date = Date.init
    ) {
        self.client = client
        self.timeToLive = timeToLive
        self.now = now
    }

    // MARK: - Refresh

    /// Refreshes the catalog when the cached copy is stale. Safe to
    /// call on every Settings appearance.
    public func refreshIfNeeded(apiKey: String?) async {
        guard !isRefreshing, isStale else { return }
        await refresh(apiKey: apiKey)
    }

    /// Forces a refresh regardless of cache age. A failure leaves
    /// ``options`` untouched — the previous list beats an empty
    /// picker.
    public func refresh(apiKey: String?) async {
        guard let apiKey, !apiKey.isEmpty else {
            logger.debug("Skipping model-catalog refresh — no OpenAI key configured.")
            return
        }

        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let fetched = try await client.listModels(apiKey: apiKey)
            guard !fetched.isEmpty else {
                logger.debug("Model catalog returned no chat models; keeping the previous list.")
                return
            }
            options = fetched
            isLive = true
            lastRefreshDate = now()
            logger.debug("Model catalog refreshed with \(fetched.count) models.")
        } catch {
            logger.error("Model catalog refresh failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Selection

    /// Resolves the identifier the picker should show as selected.
    ///
    /// An identifier missing from ``options`` is only replaced when
    /// the list is ``isLive`` — authoritative evidence the model is
    /// gone. Otherwise a model newer than this binary would be
    /// discarded just because the app predates it.
    public func resolvedSelection(for identifier: String) -> String {
        if options.contains(where: { $0.id == identifier }) {
            return identifier
        }
        guard isLive else { return identifier }
        return options.first { $0.id == OpenAIModel.default.rawValue }?.id
            ?? options.first?.id
            ?? OpenAIModel.default.rawValue
    }

    /// Display name for an identifier, derived from the identifier
    /// itself when it isn't in ``options``.
    public func displayName(for identifier: String) -> String {
        options.first { $0.id == identifier }?.displayName
            ?? OpenAIModelOption.displayName(forIdentifier: identifier)
    }

    // MARK: - Private

    private var isStale: Bool {
        guard let lastRefreshDate else { return true }
        return now().timeIntervalSince(lastRefreshDate) >= timeToLive
    }
}
