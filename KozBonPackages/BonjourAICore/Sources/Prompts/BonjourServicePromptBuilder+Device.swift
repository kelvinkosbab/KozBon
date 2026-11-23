//
//  BonjourServicePromptBuilder+Device.swift
//  BonjourAICore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourModels

#if canImport(UIKit)
import UIKit
#endif

// MARK: - BonjourServicePromptBuilder + Device

/// The device half of the prompt builder: the reader's own device,
/// and the device behind the service being explained with its TXT
/// records. Split out to keep the main file and its enum body under
/// the length limits.
extension BonjourServicePromptBuilder {

    // MARK: - Device Context

    /// A description of the current device for contextualizing AI responses.
    @MainActor
    public static var deviceContext: String {
        #if os(iOS)
        let device = UIDevice.current
        return "I am using an \(device.model) running \(device.systemName) \(device.systemVersion) (device name: \(device.name))"
        #elseif os(macOS)
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        return "I am using a Mac running macOS \(osVersion) (hostname: \(ProcessInfo.processInfo.hostName))"
        #elseif os(visionOS)
        return "I am using an Apple Vision Pro running visionOS"
        #else
        return "I am using an Apple device"
        #endif
    }

    /// A short name for the current device (e.g., "iPhone", "Mac", "Apple Vision Pro").
    @MainActor
    public static var currentDeviceShortName: String {
        #if os(iOS)
        UIDevice.current.model
        #elseif os(macOS)
        "Mac"
        #elseif os(visionOS)
        "Apple Vision Pro"
        #else
        "device"
        #endif
    }

    // MARK: - Device and TXT Lines

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
            "device family, matched from its name; specific model unknown"
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
