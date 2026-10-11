//
//  IsDeviceOnlineIntent.swift
//  BonjourAppIntents
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import AppIntents
import Foundation
import BonjourLocalization
import BonjourModels

// MARK: - IsDeviceOnlineIntent

/// Answers "Is Living Room TV on my network?" with yes or no. The
/// `Bool` result lets a Shortcuts automation branch on it.
public struct IsDeviceOnlineIntent: AppIntent {

    public static let title: LocalizedStringResource = .init("intent_online_title")

    public static let description = IntentDescription(.init("intent_online_description"))

    public static let openAppWhenRun: Bool = false

    @Parameter(title: .init("intent_parameter_device_name"))
    public var deviceName: String

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ReturnsValue<Bool> & ProvidesDialog {
        let result = await IntentScan.run()
        let match = Self.device(named: deviceName, in: result.services)
        let reply = Self.reply(query: deviceName, match: match, scanned: result)
        return .result(
            value: match != nil,
            dialog: IntentDialog(LocalizedStringResource(stringLiteral: reply))
        )
    }

    // MARK: - Helpers

    /// The device whose spoken name, advertised service names, or
    /// hostname matches `query`, ignoring case and accents. An exact
    /// match wins over one that only contains the query, so "Office"
    /// prefers "Office" to "Office Printer".
    static func device(named query: String, in services: [BonjourService]) -> SiriDevice? {
        let needle = normalized(query)
        guard !needle.isEmpty else { return nil }
        let devices = SiriNetworkSummary.devices(from: services)

        func candidates(_ device: SiriDevice) -> [String] {
            [device.name] + device.services.flatMap { [$0.service.name, $0.hostIdentifier] }
        }

        return devices.first { device in
            candidates(device).contains { normalized($0) == needle }
        } ?? devices.first { device in
            candidates(device).contains { normalized($0).contains(needle) }
        }
    }

    static func reply(query: String, match: SiriDevice?, scanned: IntentScanResult) -> String {
        if let match {
            return Strings.Siri.deviceOnline(match.name)
        }
        if scanned.services.isEmpty, !scanned.isOnLocalNetwork {
            return Strings.Siri.notOnLocalNetwork
        }
        return Strings.Siri.deviceNotFound(query)
    }

    /// Also drops a trailing `.local.` so "living-room.local" matches.
    private static func normalized(_ text: String) -> String {
        var result = text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        for suffix in [".local.", ".local"] where result.hasSuffix(suffix) {
            result.removeLast(suffix.count)
        }
        return result
    }
}
