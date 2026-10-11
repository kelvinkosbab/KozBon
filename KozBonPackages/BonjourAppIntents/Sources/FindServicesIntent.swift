//
//  FindServicesIntent.swift
//  BonjourAppIntents
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import AppIntents
import Foundation
import BonjourLocalization
import BonjourModels

// MARK: - FindServicesIntent

/// Scans and returns only the services in a category ("Find printers
/// with KozBon") or of one type (AirPlay, SSH).
///
/// Like ``ListDiscoveredServicesIntent``, it records what it returns
/// so a later Shortcuts step can look the services up.
public struct FindServicesIntent: AppIntent {

    public static let title: LocalizedStringResource = .init("intent_find_title")

    public static let description = IntentDescription(.init("intent_find_description"))

    public static let openAppWhenRun: Bool = false

    @Parameter(title: .init("intent_parameter_category"))
    public var category: ServiceCategoryAppEnum?

    /// Narrows to one type. Takes precedence over ``category``.
    @Parameter(title: .init("intent_parameter_service_type"))
    public var serviceType: BonjourServiceTypeEntity?

    public init() {}

    @MainActor
    public func perform() async throws
        -> some IntentResult & ReturnsValue<[BonjourServiceEntity]> & ProvidesDialog {
        guard category != nil || serviceType != nil else {
            throw $category.needsValueError()
        }
        let result = await IntentScan.run()
        let matches = Self.filter(result.services, category: category?.category, fullType: serviceType?.id)
        let entities = matches.map(BonjourServiceEntity.init(from:))
        await RecentServiceEntities.shared.replace(with: entities)

        let reply = Self.reply(matches: matches, scanned: result)
        return .result(
            value: entities,
            dialog: IntentDialog(LocalizedStringResource(stringLiteral: reply))
        )
    }

    // MARK: - Helpers

    static func filter(
        _ services: [BonjourService],
        category: BonjourServiceCategory?,
        fullType: String?
    ) -> [BonjourService] {
        if let fullType {
            return services.filter { $0.serviceType.fullType == fullType }
        }
        if let category {
            return services.filter { category.matches($0.serviceType) }
        }
        return services
    }

    /// The List reply for the matches, or a "nothing matched" reply
    /// when the scan found services but none fit.
    static func reply(matches: [BonjourService], scanned: IntentScanResult) -> String {
        if matches.isEmpty, !scanned.services.isEmpty {
            return Strings.Siri.noMatchingServices
        }
        return SiriNetworkSummary.listReply(services: matches, isOnLocalNetwork: scanned.isOnLocalNetwork)
    }
}
