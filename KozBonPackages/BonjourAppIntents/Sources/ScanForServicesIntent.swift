//
//  ScanForServicesIntent.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import AppIntents
import Foundation

// MARK: - ScanForServicesIntent

/// Voice-first Siri intent that runs a brief Bonjour scan and
/// reports the count back to the user.
///
/// Runs ``IntentScan`` for ~3 seconds and speaks how many devices
/// and services it found, by category (``SiriNetworkSummary``).
/// Returns no structured values; for "give me the list", see
/// ``ListDiscoveredServicesIntent``.
///
/// The intent runs **in-process** with a fresh scanner instance
/// rather than reaching into the running app's scanner. That
/// keeps the contract simple (no IPC, no stale-snapshot logic)
/// at the cost of running a separate ~3-second scan per
/// invocation — well within Siri's intent budget.
public struct ScanForServicesIntent: AppIntent {

    public static let title: LocalizedStringResource = .init("intent_scan_title")

    public static let description = IntentDescription(
        .init("intent_scan_description"),
        searchKeywords: Self.spotlightSearchKeywords
    )

    private static let spotlightSearchKeywords: [LocalizedStringResource] = [
        .init("intent_keyword_scan"),
        .init("intent_keyword_bonjour"),
        .init("intent_keyword_discover"),
        .init("intent_keyword_network"),
        .init("intent_keyword_kozbon")
    ]

    /// Voice-first by design — opening the app would interrupt the
    /// spoken summary the user is waiting to hear. Users who want
    /// the visual list can ask Siri to open KozBon separately, or
    /// use ``ListDiscoveredServicesIntent`` to get structured
    /// results into a Shortcut.
    public static let openAppWhenRun: Bool = false

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let result = await IntentScan.run()
        let reply = SiriNetworkSummary.scanReply(
            services: result.services,
            isOnLocalNetwork: result.isOnLocalNetwork
        )
        return .result(dialog: IntentDialog(LocalizedStringResource(stringLiteral: reply)))
    }
}
