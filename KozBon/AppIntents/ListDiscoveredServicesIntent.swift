//
//  ListDiscoveredServicesIntent.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import AppIntents
import Foundation
import BonjourAI
import BonjourModels
import BonjourScanning

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
/// a one-shot ``BonjourOneShotScanner``. The two intents share
/// the same scanning primitive but differ in what they expose:
/// `ScanForServicesIntent` is voice-only ("how many?"),
/// `ListDiscoveredServicesIntent` is data-first ("give me the
/// list").
@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
struct ListDiscoveredServicesIntent: AppIntent {

    static let title: LocalizedStringResource = "List Discovered Services"

    static let description = IntentDescription(
        "Lists Bonjour services discovered on your local network. Use this in Shortcuts to feed the list of services into the next step.",
        searchKeywords: Self.spotlightSearchKeywords
    )

    private static let spotlightSearchKeywords: [LocalizedStringResource] = [
        "list",
        "services",
        "bonjour",
        "discover",
        "network",
        "kozbon"
    ]

    static let openAppWhenRun: Bool = false

    /// Maximum number of service names read aloud in the voice
    /// summary. Beyond this, the dialog says "and N others" so
    /// Siri doesn't read a 50-item list. The structured return
    /// value contains the full list regardless.
    private static let voiceNameCap = 3

    @MainActor
    func perform() async throws
        -> some IntentResult & ReturnsValue<[BonjourServiceEntity]> & ProvidesDialog {
        let runner = BonjourOneShotScanner(scanner: BonjourServiceScanner())
        let services = await runner.run()
        let entities = services.map(BonjourServiceEntity.init(from:))

        let voiceSummary = Self.voiceSummary(services: services, entities: entities)
        return .result(
            value: entities,
            dialog: IntentDialog(LocalizedStringResource(stringLiteral: voiceSummary))
        )
    }

    /// Builds the spoken summary read aloud by Siri. Combines a
    /// categorical breakdown (so the user knows the SHAPE of
    /// their network) with a few specific service names (so
    /// they have concrete signal). The full list is always
    /// available via the returned `[BonjourServiceEntity]` for
    /// Shortcuts automations to iterate over.
    @MainActor
    private static func voiceSummary(
        services: [BonjourService],
        entities: [BonjourServiceEntity]
    ) -> String {
        switch entities.count {
        case 0:
            return "I didn't find any Bonjour services on your network. " +
                "If you haven't given KozBon permission to scan the local network, " +
                "open the app once to grant it."
        case 1:
            // Single service — read the name and the categorical
            // bucket together so the user knows what kind of
            // thing it is. `voiceFriendlyName` substitutes
            // friendly forms for hostname-style auto-named
            // services so Siri reads "iPhone" instead of
            // "i Phone dash one F two A".
            return "Found 1 Bonjour service: \(entities[0].voiceFriendlyName), " +
                "a \(services.voiceCategoricalSummary().dropFirst(2))."
        case 2:
            return "Found 2 Bonjour services: " +
                "\(entities[0].voiceFriendlyName) and \(entities[1].voiceFriendlyName) " +
                "(\(services.voiceCategoricalSummary()))."
        default:
            // Multi-service: lead with the categorical summary
            // for "shape of the network" signal, then name the
            // first few services for concrete content. The
            // structured value carries the full list for any
            // Shortcut step that wants to iterate — those
            // entities still expose the original `name` for
            // copy/paste / pipeline use.
            let named = entities.prefix(voiceNameCap)
                .map(\.voiceFriendlyName)
                .joined(separator: ", ")
            let categorical = services.voiceCategoricalSummary()
            let remainder = entities.count - voiceNameCap
            if remainder <= 0 {
                return "Found \(entities.count) Bonjour services — \(categorical). " +
                    "They include \(named)."
            }
            return "Found \(entities.count) Bonjour services — \(categorical). " +
                "The first few are \(named), and \(remainder) others."
        }
    }
}
