//
//  ServiceCategoryAppEnum.swift
//  BonjourAppIntents
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import AppIntents
import Foundation
import BonjourModels

// MARK: - ServiceCategoryAppEnum

/// The Discover tab's categories, offered to Siri so "Find printers
/// with KozBon" can name one. Synonyms cover the shorter words and
/// protocol names people say instead ("printers", "AirPlay", "SSH").
public enum ServiceCategoryAppEnum: String, AppEnum, Sendable {
    case appleDevices
    case printersAndScanners
    case smartHome
    case mediaAndStreaming
    case remoteAccess

    public static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: .init("intent_category_type_name")
    )

    public static let caseDisplayRepresentations: [ServiceCategoryAppEnum: DisplayRepresentation] = [
        .appleDevices: DisplayRepresentation(
            title: .init("intent_category_apple_devices"),
            synonyms: [.init("intent_category_synonym_apple")]
        ),
        .printersAndScanners: DisplayRepresentation(
            title: .init("intent_category_printers"),
            synonyms: [.init("intent_category_synonym_printers"), .init("intent_category_synonym_scanners")]
        ),
        .smartHome: DisplayRepresentation(
            title: .init("intent_category_smart_home"),
            synonyms: [.init("intent_category_synonym_homekit")]
        ),
        .mediaAndStreaming: DisplayRepresentation(
            title: .init("intent_category_media"),
            synonyms: [.init("intent_category_synonym_airplay")]
        ),
        .remoteAccess: DisplayRepresentation(
            title: .init("intent_category_remote_access"),
            synonyms: [.init("intent_category_synonym_ssh")]
        )
    ]

    /// The model category this case filters by.
    var category: BonjourServiceCategory {
        switch self {
        case .appleDevices: .appleDevices
        case .printersAndScanners: .printersAndScanners
        case .smartHome: .smartHome
        case .mediaAndStreaming: .mediaAndStreaming
        case .remoteAccess: .remoteAccess
        }
    }
}
