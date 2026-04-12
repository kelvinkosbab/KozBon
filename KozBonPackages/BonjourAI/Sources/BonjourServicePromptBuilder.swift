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

    // MARK: - ExpertiseLevel

    /// The user's preferred level of technical detail in AI explanations.
    ///
    /// Controls how the on-device model frames its response — from everyday
    /// language suitable for non-technical users to detailed protocol-level
    /// information for networking professionals.
    public enum ExpertiseLevel: String, CaseIterable, Sendable {

        /// Clear, approachable explanation using plain language.
        ///
        /// The model focuses on *what* the service does and *why* it
        /// matters to the user, using everyday analogies rather than
        /// implementation details. Ideal for a quick, useful overview.
        case basic

        /// In-depth explanation with protocol details and standards references.
        ///
        /// The model includes port conventions, transport-layer specifics,
        /// relevant RFC numbers, and TXT-record semantics. Assumes the
        /// reader is comfortable with networking fundamentals such as
        /// TCP/UDP, DNS-SD, and mDNS.
        case technical
    }

    // MARK: - System Instructions

    /// The system prompt instructing the model how to explain Bonjour services.
    ///
    /// Dynamically includes the user's preferred language so the AI responds
    /// in the correct locale. Requests structured Markdown sections for
    /// consistent, scannable output.
    public static var systemInstructions: String {
        let languageName = preferredLanguageName
        return """
            You are a friendly networking expert helping everyday users understand \
            Bonjour (mDNS/DNS-SD) services discovered on their local network.

            Format your response with these Markdown sections:
            ## What It Does
            (1-2 sentences explaining what this service is and its purpose)
            ## Why It's Running
            (1-2 sentences on why this service is likely active on the advertising device)
            ## How to Interact
            (1-2 sentences on how the user can interact with it from their device)
            ## Configuration Details
            (Only include this section if TXT records are present. Explain what they reveal \
            about the service's configuration.)

            Keep each section concise — no more than 2-3 sentences. \
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

    // MARK: - Prompt Builder

    /// Builds a prompt string from the given service's metadata.
    ///
    /// - Parameters:
    ///   - service: The Bonjour service to build a prompt for.
    ///   - expertiseLevel: The desired detail level for the explanation.
    /// - Returns: A formatted prompt string including device context, service details,
    ///   addresses, protocol description, and TXT records.
    @MainActor
    public static func buildPrompt(
        service: BonjourService,
        expertiseLevel: ExpertiseLevel = .basic
    ) -> String {
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
        parts.append(expertiseLevelDirective(expertiseLevel))

        parts.append("")
        parts.append(
            "What does this service do, why is it running on that device, " +
            "and how can I interact with it from my \(currentDeviceShortName)? " +
            "Please respond in \(preferredLanguageName)."
        )

        return parts.joined(separator: "\n")
    }

    /// Builds a prompt string from a service type (without a specific discovered instance).
    ///
    /// - Parameters:
    ///   - serviceType: The Bonjour service type to explain.
    ///   - expertiseLevel: The desired detail level for the explanation.
    /// - Returns: A formatted prompt string including device context and service type metadata.
    @MainActor
    public static func buildPrompt(
        serviceType: BonjourServiceType,
        expertiseLevel: ExpertiseLevel = .basic
    ) -> String {
        var parts: [String] = []

        parts.append(deviceContext)
        parts.append("")
        parts.append("I'd like to understand this Bonjour service type:")
        parts.append("")
        parts.append("Service name: \(serviceType.name)")
        parts.append("Full type: \(serviceType.fullType)")
        parts.append("Transport layer: \(serviceType.transportLayer.string.uppercased())")

        if let detail = serviceType.detail {
            parts.append("Protocol description: \(detail)")
        }

        parts.append("")
        parts.append(expertiseLevelDirective(expertiseLevel))

        parts.append("")
        parts.append(
            "What does this service type do, what kinds of devices typically use it, " +
            "and how might I interact with it from my \(currentDeviceShortName)? " +
            "Please respond in \(preferredLanguageName)."
        )

        return parts.joined(separator: "\n")
    }

    // MARK: - Expertise Level Directive

    /// Returns a prompt directive tailored to the given expertise level.
    ///
    /// - Parameter level: The desired expertise level.
    /// - Returns: A string instructing the model how to adjust its tone and detail.
    public static func expertiseLevelDirective(_ level: ExpertiseLevel) -> String {
        switch level {
        case .basic:
            return "Explain in simple terms. Use everyday analogies where helpful. " +
                "Avoid acronyms and technical jargon."
        case .technical:
            return "Include protocol details, port conventions, and relevant RFC references. " +
                "Assume the reader understands networking fundamentals."
        }
    }
}
