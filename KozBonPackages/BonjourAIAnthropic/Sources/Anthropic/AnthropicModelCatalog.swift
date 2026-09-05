//
//  AnthropicModelCatalog.swift
//  BonjourAIAnthropic
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourCore

// MARK: - AnthropicModelCatalog

/// Fetches the list of Claude models the user's own API key can
/// call, so the Settings picker tracks Anthropic's lineup without
/// waiting for an App Store update.
///
/// Resolution is three-tiered, in priority order:
///
/// 1. **Freshly fetched catalog** — `GET /v1/models`, which
///    returns newest-first, so one page is plenty.
/// 2. **This session's cached fetch** — refetching on every
///    Settings appearance would be wasteful; the TTL bounds it.
/// 3. **``AnthropicModelOption/builtInOptions``** — the hardcoded
///    floor, used when there's no key, no network, or the request
///    fails. KozBon is a local-network app that is frequently run
///    with no internet, so this tier is load-bearing rather than
///    theoretical.
///
/// The cache is intentionally in-memory only. Persisting it would
/// mean either `UserDefaults` — which would force a
/// `PrivacyInfo.xcprivacy` required-reason declaration the app
/// currently doesn't need — or a SwiftData schema change, and
/// neither is worth it when the offline path already degrades to
/// the built-in list.
@MainActor
@Observable
public final class AnthropicModelCatalog {

    // MARK: - State

    /// The options to show in the picker. Starts as the built-in
    /// fallback so the UI always has something to render, and is
    /// replaced wholesale by a successful fetch.
    public private(set) var options: [AnthropicModelOption] = AnthropicModelOption.builtInOptions

    /// Whether a refresh is in flight (drives the picker's
    /// progress affordance).
    public private(set) var isRefreshing = false

    /// Whether ``options`` reflects a successful live fetch. When
    /// `false`, the picker is showing the compiled-in fallback.
    public private(set) var isLive = false

    /// When the last successful fetch completed.
    public private(set) var lastRefreshDate: Date?

    // MARK: - Dependencies

    private let client: any AnthropicModelCatalogClientProtocol
    private let timeToLive: TimeInterval
    private let now: () -> Date

    private let logger: Loggable = Logger(category: "AnthropicModelCatalog")

    // MARK: - Init

    /// - Parameters:
    ///   - client: Performs the `/v1/models` request. Injectable
    ///     so tests can exercise every tier without a network.
    ///   - timeToLive: How long a successful fetch stays fresh.
    ///     Defaults to one hour — long enough that opening
    ///     Settings repeatedly costs nothing, short enough that a
    ///     newly-released model shows up the same day.
    ///   - now: Clock injection point, per the project's
    ///     determinism rules.
    public init(
        client: any AnthropicModelCatalogClientProtocol = AnthropicModelCatalogClient(),
        timeToLive: TimeInterval = 3600,
        now: @escaping () -> Date = Date.init
    ) {
        self.client = client
        self.timeToLive = timeToLive
        self.now = now
    }

    // MARK: - Refresh

    /// Refreshes the catalog when the cached copy is stale.
    ///
    /// Safe to call on every Settings appearance: a fresh cache,
    /// an in-flight refresh, or a missing API key all return
    /// immediately without touching the network.
    ///
    /// - Parameter apiKey: The user's Anthropic key, or `nil`
    ///   when none is configured (in which case the built-in
    ///   fallback list stands).
    public func refreshIfNeeded(apiKey: String?) async {
        guard !isRefreshing, isStale else { return }
        await refresh(apiKey: apiKey)
    }

    /// Forces a refresh regardless of cache age.
    ///
    /// A failure deliberately leaves ``options`` untouched: the
    /// previous list — live or built-in — is strictly more useful
    /// to the user than an empty picker.
    public func refresh(apiKey: String?) async {
        guard let apiKey, !apiKey.isEmpty else {
            logger.debug("Skipping model-catalog refresh — no Anthropic key configured.")
            return
        }

        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let fetched = try await client.listModels(apiKey: apiKey)
            guard !fetched.isEmpty else {
                logger.debug("Model catalog returned no entries; keeping the previous list.")
                return
            }
            options = fetched
            isLive = true
            lastRefreshDate = now()
            logger.debug("Model catalog refreshed with \(fetched.count) models.")
        } catch {
            // Non-fatal by design — the picker keeps working from
            // whatever tier it was already showing.
            logger.error("Model catalog refresh failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Selection

    /// Resolves the identifier the picker should show as selected.
    ///
    /// The important rule: an identifier that isn't in ``options``
    /// is only replaced when the list is ``isLive`` — i.e. when we
    /// have authoritative evidence the model is gone. Falling back
    /// on the built-in list instead would throw away a perfectly
    /// valid new model just because this binary predates it, which
    /// is exactly the bug that made the picker stale.
    public func resolvedSelection(for identifier: String) -> String {
        if options.contains(where: { $0.id == identifier }) {
            return identifier
        }
        guard isLive else { return identifier }
        return options.first?.id ?? AnthropicModel.default.rawValue
    }

    /// Display name for an identifier, falling back to the raw
    /// identifier so an unknown-but-valid model still renders.
    public func displayName(for identifier: String) -> String {
        options.first { $0.id == identifier }?.displayName ?? identifier
    }

    // MARK: - Private

    private var isStale: Bool {
        guard let lastRefreshDate else { return true }
        return now().timeIntervalSince(lastRefreshDate) >= timeToLive
    }
}
