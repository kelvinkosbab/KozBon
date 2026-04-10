//
//  BonjourServicePromptBuilder.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourCore
import BonjourModels

#if canImport(UIKit)
import UIKit
#endif

// MARK: - BonjourServicePromptBuilder

/// Builds contextual prompts for the AI explainer from Bonjour service metadata.
///
/// Extracted from `BonjourServiceExplainer` so the prompt construction logic
/// is testable without requiring FoundationModels availability.
public enum BonjourServicePromptBuilder {

    // MARK: - System Instructions

    /// The system prompt instructing the model how to explain Bonjour services.
    ///
    /// Dynamically includes the user's preferred language so the AI responds
    /// in the correct locale.
    public static var systemInstructions: String {
        let languageName = preferredLanguageName
        return """
            You are a friendly networking expert helping everyday users understand \
            Bonjour (mDNS/DNS-SD) services discovered on their local network. \
            Explain what this service does, why it is likely running on the device, \
            and how the user might interact with it. Keep your explanation clear, \
            concise, and approachable — avoid deep technical jargon. \
            Use 2-4 short paragraphs. If the service has TXT records, mention what \
            they reveal about the service's configuration. \
            IMPORTANT: Always respond in \(languageName).
            """
    }

    // MARK: - Language Detection

    /// The user's preferred language name for AI response localization.
    ///
    /// Uses the device's preferred language setting to determine the display name,
    /// falling back to "English" if detection fails.
    public static var preferredLanguageName: String {
        guard let languageCode = Locale.preferredLanguages.first else {
            return "English"
        }
        let locale = Locale(identifier: languageCode)
        return locale.localizedString(forLanguageCode: languageCode) ?? "English"
    }

    // MARK: - Device Context

    /// A description of the current device for contextualizing AI responses.
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

    // MARK: - Prompt Builder

    /// Builds a prompt string from the given service's metadata.
    ///
    /// - Parameter service: The Bonjour service to build a prompt for.
    /// - Returns: A formatted prompt string including device context, service details,
    ///   addresses, protocol description, and TXT records.
    @MainActor
    public static func buildPrompt(service: BonjourService) -> String {
        let serviceType = service.serviceType
        var parts: [String] = []

        parts.append(deviceContext)
        parts.append("")
        parts.append("I discovered this Bonjour service on my local network and would like to understand it:")
        parts.append("")
        parts.append("Service name: \(serviceType.name)")
        parts.append("Full type: \(serviceType.fullType)")
        parts.append("Transport layer: \(serviceType.transportLayer.string.uppercased())")
        parts.append("Host name: \(service.hostName)")
        parts.append("Device advertising the service: \(service.service.name)")
        parts.append("Domain: \(service.service.domain)")

        if !service.addresses.isEmpty {
            let addressStrings = service.addresses.map(\.ipPortString)
            parts.append("IP addresses: \(addressStrings.joined(separator: ", "))")
        }

        if let detail = serviceType.detail {
            parts.append("Protocol description: \(detail)")
        }

        if !service.dataRecords.isEmpty {
            let records = service.dataRecords.map { "\($0.key)=\($0.value)" }
            parts.append("TXT records: \(records.joined(separator: ", "))")
        }

        parts.append("")
        parts.append(
            "What does this service do, why is it running on that device, " +
            "and how can I interact with it from my \(currentDeviceShortName)? " +
            "Please respond in \(preferredLanguageName)."
        )

        return parts.joined(separator: "\n")
    }
}
