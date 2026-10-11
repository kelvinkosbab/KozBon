//
//  ListDiscoveredServicesIntent.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import AppIntents
import Foundation

// MARK: - ListDiscoveredServicesIntent

/// Data-first Siri/Shortcuts intent that runs a brief Bonjour
/// scan and returns the discovered services as a list of
/// ``BonjourServiceEntity`` values.
///
/// Designed for Shortcuts automations like "for each discovered
/// service, do X" — the entity return value plumbs into
/// downstream actions, while the dialog provides a voice summary
/// for users invoking it via Siri directly.
///
/// Like ``ScanForServicesIntent``, this runs **in-process** with
/// ``IntentScan``. The two intents share the same scan but differ in
/// what they expose:
/// `ScanForServicesIntent` is voice-only ("how many?"),
/// `ListDiscoveredServicesIntent` is data-first ("give me the
/// list").
public struct ListDiscoveredServicesIntent: AppIntent {

    public static let title: LocalizedStringResource = .init("intent_list_title")

    public static let description = IntentDescription(
        .init("intent_list_description"),
        searchKeywords: Self.spotlightSearchKeywords
    )

    private static let spotlightSearchKeywords: [LocalizedStringResource] = [
        .init("intent_keyword_list"),
        .init("intent_keyword_services"),
        .init("intent_keyword_bonjour"),
        .init("intent_keyword_discover"),
        .init("intent_keyword_network"),
        .init("intent_keyword_kozbon")
    ]

    public static let openAppWhenRun: Bool = false

    public init() {}

    @MainActor
    public func perform() async throws
        -> some IntentResult & ReturnsValue<[BonjourServiceEntity]> & ProvidesDialog {
        let result = await IntentScan.run()
        let entities = result.services.map(BonjourServiceEntity.init(from:))
        await RecentServiceEntities.shared.replace(with: entities)

        let reply = SiriNetworkSummary.listReply(
            services: result.services,
            isOnLocalNetwork: result.isOnLocalNetwork
        )
        return .result(
            value: entities,
            dialog: IntentDialog(LocalizedStringResource(stringLiteral: reply))
        )
    }
}
