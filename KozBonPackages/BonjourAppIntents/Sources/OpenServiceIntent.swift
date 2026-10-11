//
//  OpenServiceIntent.swift
//  BonjourAppIntents
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import AppIntents
import Foundation

// MARK: - OpenServiceIntent

/// Opens KozBon on a service that List or Find returned, so a Shortcut
/// can end on the service's detail page.
///
/// Discovered services don't persist, so the app matches by name and
/// type and selects the service once its own scan finds it.
public struct OpenServiceIntent: AppIntent {

    public static let title: LocalizedStringResource = .init("intent_open_title")

    public static let description = IntentDescription(.init("intent_open_description"))

    public static let openAppWhenRun: Bool = true

    @Parameter(title: .init("intent_parameter_service"))
    public var service: BonjourServiceEntity

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult {
        AppIntentsBridge.shared.requestOpen(
            OpenServiceRequest(name: service.name, serviceType: service.serviceType)
        )
        return .result()
    }
}
