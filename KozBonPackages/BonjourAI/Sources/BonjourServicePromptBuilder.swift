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

    // MARK: - ResponseLength

    /// How verbose AI responses should be.
    ///
    /// Orthogonal to ``ExpertiseLevel``: expertise controls the vocabulary and
    /// depth of content, response length controls how many words the model uses.
    public enum ResponseLength: String, CaseIterable, Sendable {

        /// Short, to-the-point answer in 1-2 sentences per section.
        case brief

        /// Medium-length answer in 2-3 sentences per section. (Default)
        case standard

        /// Comprehensive answer in 4-6 sentences per section with examples.
        case thorough
    }

    // MARK: - System Instructions

    /// The system prompt instructing the model how to explain Bonjour services.
    ///
    /// Puts the language directive and anti-hallucination guardrails at the top
    /// since models follow early instructions more reliably. Uses structured
    /// Markdown sections with concrete examples for consistent output.
    public static var systemInstructions: String {
        let languageName = preferredLanguageName
        return """
            TOP PRIORITY: Respond in \(languageName).

            ACCURACY RULES:
            - When information is uncertain or missing from the provided context, say so \
            explicitly rather than guessing.
            - Never invent port numbers, RFC numbers, protocol versions, or vendor names.
            - For TXT records, only describe keys whose meaning is widely documented \
            (e.g., `rmodel`, `model`, `txtvers`). For unknown or vendor-specific keys, \
            state "Vendor-specific: <key>=<value>" without speculating about meaning.

            ---

            You are a friendly networking expert helping everyday users understand \
            Bonjour (mDNS/DNS-SD) services discovered on their local network.

            Format your response with these Markdown sections:

            ## What it does
            (1-2 sentences explaining what this service type is and its purpose.)
            Example: "AirPlay lets this Apple TV receive audio and video from other Apple \
            devices on the same network."

            ## Why it's running
            (Explain the typical purpose of this service type on this *kind* of device. \
            Do NOT speculate about this particular user's setup or intent.)
            Example: "Apple TVs advertise AirPlay by default so any nearby Apple device can \
            stream content to them."

            ## How to interact
            (1-2 sentences on how a user typically interacts with this service from their device.)
            Example: "Open Control Center on your iPhone and tap Screen Mirroring to send \
            content to this Apple TV."

            ## Configuration details
            (Only include this section if TXT records are present. Explain what the documented \
            keys reveal about the service's configuration. Label unknown keys as vendor-specific.)

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
    ///   - isPublished: Whether this service was published by this device (vs discovered remotely).
    ///   - expertiseLevel: The desired detail level for the explanation.
    ///   - responseLength: The desired verbosity of the response.
    /// - Returns: A formatted prompt string including device context, service details,
    ///   addresses, protocol description, and TXT records.
    @MainActor
    public static func buildPrompt(
        service: BonjourService,
        isPublished: Bool = false,
        expertiseLevel: ExpertiseLevel = .basic,
        responseLength: ResponseLength = .standard
    ) -> String {
        let serviceType = service.serviceType
        var parts: [String] = []

        parts.append(deviceContext)
        parts.append("")
        if isPublished {
            parts.append(
                "This is a Bonjour service that I am broadcasting from this device. " +
                "I would like to understand it:"
            )
        } else {
            parts.append("I discovered this Bonjour service on my local network and would like to understand it:")
        }
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
        parts.append(responseLengthDirective(responseLength))

        parts.append("")
        parts.append(
            "What does this service do, why is it running on that device, " +
            "and how can I interact with it from my \(currentDeviceShortName)? " +
            "Please respond in \(preferredLanguageName)."
        )

        return parts.joined(separator: "\n")
    }

    // MARK: - Service Type System Instructions

    /// System instructions tailored for service type explanations (library tab).
    ///
    /// Unlike discovered service explanations, these do not assume the service
    /// is currently running on the network.
    public static var serviceTypeSystemInstructions: String {
        let languageName = preferredLanguageName
        return """
            TOP PRIORITY: Respond in \(languageName).

            ACCURACY RULES:
            - When information is uncertain, say so explicitly rather than guessing.
            - Never invent port numbers, RFC numbers, protocol versions, or vendor names.
            - Do NOT assume this service is currently running on the user's network — \
            they are browsing a library of supported service types.

            ---

            You are a friendly networking expert helping everyday users understand \
            Bonjour (mDNS/DNS-SD) service types.

            Explain the service type itself, not a specific instance.

            Format your response with these Markdown sections:

            ## What it is
            (1-2 sentences explaining what this service type is and its purpose.)
            Example: "HTTP is the standard protocol for web servers, used by browsers to \
            request web pages and APIs."

            ## Common devices
            (1-2 sentences on what kinds of devices or apps typically advertise this service.)
            Example: "Web servers, smart-home hubs, and network printers often advertise HTTP \
            to expose local web interfaces."

            ## How it works
            (1-2 sentences on how this protocol works at a high level and how users might \
            interact with it.)
            Example: "Clients connect over TCP and send GET or POST requests to retrieve or \
            submit data."

            IMPORTANT: Always respond in \(languageName).
            """
    }

    // MARK: - Service Type Prompt

    /// Builds a prompt string from a service type (without a specific discovered instance).
    ///
    /// - Parameters:
    ///   - serviceType: The Bonjour service type to explain.
    ///   - expertiseLevel: The desired detail level for the explanation.
    ///   - responseLength: The desired verbosity of the response.
    /// - Returns: A formatted prompt string with service type metadata.
    @MainActor
    public static func buildPrompt(
        serviceType: BonjourServiceType,
        expertiseLevel: ExpertiseLevel = .basic,
        responseLength: ResponseLength = .standard
    ) -> String {
        var parts: [String] = []

        parts.append("I'd like to understand this Bonjour service type from the service library:")
        parts.append("")
        parts.append("Service name: \(serviceType.name)")
        parts.append("Full type: \(serviceType.fullType)")
        parts.append("Transport layer: \(serviceType.transportLayer.string.uppercased())")

        if let detail = serviceType.detail {
            parts.append("Protocol description: \(detail)")
        }

        parts.append("")
        parts.append(expertiseLevelDirective(expertiseLevel))
        parts.append(responseLengthDirective(responseLength))

        parts.append("")
        parts.append(
            "Explain what this service type is, what devices commonly use it, " +
            "and how it works. Do not assume this service is currently running " +
            "on my network. Please respond in \(preferredLanguageName)."
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
            return "TONE: Explain like you're helping a curious friend who isn't technical. " +
                "Use everyday analogies. Keep sentences short. Avoid acronyms — if you must " +
                "use one, explain it the first time (e.g., \"TCP (the protocol that makes " +
                "sure data arrives reliably)\")."
        case .technical:
            return "TONE: Assume a developer or sysadmin audience. Be precise with terminology. " +
                "Cite RFCs by number when relevant (only if you are certain of the number). " +
                "Include port conventions and transport-layer specifics where applicable."
        }
    }

    // MARK: - Response Length Directive

    /// Returns a prompt directive tailored to the given response length.
    ///
    /// - Parameter length: The desired response length.
    /// - Returns: A string instructing the model how verbose the response should be.
    public static func responseLengthDirective(_ length: ResponseLength) -> String {
        switch length {
        case .brief:
            return "LENGTH: Use no more than 3 sentences TOTAL across all sections combined. " +
                "If a section isn't essential for answering, omit it entirely. Be concise " +
                "and direct — prioritize only the most essential information."
        case .standard:
            return "LENGTH: Keep each section to 2-3 sentences — enough to explain the topic " +
                "clearly without being verbose."
        case .thorough:
            return "LENGTH: Provide comprehensive answers with 4-6 sentences per section. " +
                "Include relevant examples, edge cases, and context where helpful."
        }
    }
}
