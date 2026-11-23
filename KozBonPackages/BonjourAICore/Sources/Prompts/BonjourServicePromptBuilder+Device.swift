//
//  BonjourServicePromptBuilder+Device.swift
//  BonjourAICore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourModels

// MARK: - Device and TXT Lines

extension BonjourServicePromptBuilder {

    /// The lines describing the device behind the service: what this
    /// app identified it as, its advertised name, host name, domain,
    /// and addresses.
    ///
    /// Device-supplied strings go through ``PromptInjectionSanitizer``
    /// because any device on the network picks its own name.
    @MainActor
    static func deviceLines(for service: BonjourService) -> [String] {
        var lines: [String] = []
        if let identification = BonjourDeviceIdentifier.identify(service: service) {
            lines.append(
                "Identified device: \(identification.friendlyName) " +
                "(\(identificationBasis(identification.confidence)))"
            )
        }
        lines.append("Device advertising the service: \(PromptInjectionSanitizer.sanitize(service.service.name))")
        // `hostName` reads "NA" until the service resolves; an
        // unresolved placeholder would read to the model as a real name.
        if service.service.hostName != nil {
            lines.append("Host name: \(PromptInjectionSanitizer.sanitize(service.hostName))")
        }
        lines.append("Domain: \(service.service.domain)")

        if !service.addresses.isEmpty {
            let addressStrings = service.addresses.map(\.ipPortString)
            lines.append("IP addresses: \(addressStrings.joined(separator: ", "))")
        }
        return lines
    }

    /// How the device identification was reached, in words the
    /// system instructions key their hedging on.
    static func identificationBasis(_ confidence: DeviceIdentification.Confidence) -> String {
        switch confidence {
        case .high:
            "exact model, from the device's TXT records"
        case .medium:
            "device family, matched from its name; the exact model is unknown"
        case .low:
            "device class, inferred from the service type alone"
        }
    }

    /// One line per TXT record, so a value that itself contains a
    /// comma (AirPlay's `features=0x5A7FFFF7,0x1E`) stays intact.
    /// Keys and values are device-supplied, so they're sanitized and
    /// each value is capped.
    static func txtRecordLines(for records: [BonjourService.TxtDataRecord]) -> [String] {
        var lines = ["TXT records (\(records.count)):"]
        for record in records {
            let key = PromptInjectionSanitizer.sanitize(record.key)
            let value = PromptInjectionSanitizer.sanitize(
                record.value,
                maxLength: PromptInjectionSanitizer.txtValueMaxLength
            )
            lines.append("- \(key)=\(value)")
        }
        return lines
    }
}
