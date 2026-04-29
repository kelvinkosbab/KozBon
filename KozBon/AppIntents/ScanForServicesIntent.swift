//
//  ScanForServicesIntent.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import AppIntents
import Foundation
import BonjourAI
import BonjourScanning

// MARK: - ScanForServicesIntent

/// Voice-first Siri intent that runs a brief Bonjour scan and
/// reports the count back to the user.
///
/// Uses ``BonjourOneShotScanner`` to scan for ~3 seconds, captures
/// every `didAdd` callback during that window, and returns a
/// concise voice summary. Does NOT return structured values —
/// for "give me the list" use cases, see
/// ``ListDiscoveredServicesIntent``.
///
/// The intent runs **in-process** with a fresh scanner instance
/// rather than reaching into the running app's scanner. That
/// keeps the contract simple (no IPC, no stale-snapshot logic)
/// at the cost of running a separate ~3-second scan per
/// invocation — well within Siri's intent budget.
@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
struct ScanForServicesIntent: AppIntent {

    static let title: LocalizedStringResource = "Scan for Bonjour Services"

    static let description = IntentDescription(
        "Scans for Bonjour services on your local network for a few seconds and tells you how many were found.",
        searchKeywords: Self.spotlightSearchKeywords
    )

    private static let spotlightSearchKeywords: [LocalizedStringResource] = [
        "scan",
        "bonjour",
        "discover",
        "network",
        "kozbon"
    ]

    /// Voice-first by design — opening the app would interrupt the
    /// spoken summary the user is waiting to hear. Users who want
    /// the visual list can ask Siri to open KozBon separately, or
    /// use ``ListDiscoveredServicesIntent`` to get structured
    /// results into a Shortcut.
    static let openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let runner = BonjourOneShotScanner(scanner: BonjourServiceScanner())
        let services = await runner.run()

        let summary: String
        switch services.count {
        case 0:
            // Distinguish "nothing found" from a possible
            // permission failure: the user has the same outcome
            // regardless, but the wording matters. We can't
            // detect a missing local-network permission from
            // here — that comes from the system frameworks
            // silently — so the message is honest about the
            // scan completing without results.
            summary = "I didn't find any Bonjour services on your network. " +
                "If you haven't given KozBon permission to scan the local network, " +
                "open the app once to grant it."
        case 1:
            // Single service — name the category so the user
            // knows what kind of device it is even with one
            // result. e.g. "Found 1 service: 1 Apple device."
            summary = "Found 1 Bonjour service: \(services.voiceCategoricalSummary())."
        default:
            // Multi-service count + categorical breakdown.
            // The breakdown tells the user the SHAPE of their
            // network rather than just a raw count — turning
            // "Found 12 services" into the more useful
            // "Found 12 services: 3 Apple devices, 2 printers,
            // and 7 others."
            summary = "Found \(services.count) Bonjour services on your network: " +
                "\(services.voiceCategoricalSummary())."
        }
        return .result(dialog: IntentDialog(
            LocalizedStringResource(stringLiteral: summary)
        ))
    }
}
