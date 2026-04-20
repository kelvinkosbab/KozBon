//
//  BonjourChatPromptBuilder.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourCore
import BonjourModels

// MARK: - BonjourChatPromptBuilder

/// Builds system instructions and context for the Bonjour chat assistant.
///
/// The assistant is scoped strictly to Bonjour services and the KozBon app.
/// Off-topic queries are refused via system prompt instructions.
public enum BonjourChatPromptBuilder {

    // MARK: - ChatContext

    /// A snapshot of the user's current network state and preferences.
    ///
    /// Injected into the chat system prompt so the assistant can answer
    /// questions about the user's actual services without requiring tool calls.
    public struct ChatContext: Sendable {

        /// Services currently discovered on the local network.
        public let discoveredServices: [BonjourService]

        /// Services the user is broadcasting from this device.
        public let publishedServices: [BonjourService]

        /// All built-in and custom service types in the library.
        public let serviceTypeLibrary: [BonjourServiceType]

        public init(
            discoveredServices: [BonjourService] = [],
            publishedServices: [BonjourService] = [],
            serviceTypeLibrary: [BonjourServiceType] = []
        ) {
            self.discoveredServices = discoveredServices
            self.publishedServices = publishedServices
            self.serviceTypeLibrary = serviceTypeLibrary
        }
    }

    // MARK: - System Instructions

    /// Builds the system prompt for the chat assistant.
    ///
    /// Includes scope rules, the injected context block, and the language directive.
    ///
    /// - Parameter context: A snapshot of the user's current services and library.
    /// - Returns: A formatted system prompt string.
    @MainActor
    public static func systemInstructions(context: ChatContext) -> String {
        let language = BonjourServicePromptBuilder.preferredLanguageName
        var parts: [String] = []

        parts.append("""
            You are KozBon's on-device assistant. You help the user understand \
            Bonjour (mDNS/DNS-SD) network services on their local network and \
            how to use the KozBon app.

            YOU CAN ANSWER QUESTIONS ABOUT:
            - Services currently discovered on the user's network (listed below)
            - Services the user is broadcasting from this device (listed below)
            - The service type library (supported protocols)
            - How to use the KozBon app:
              * Discover tab: browse and filter nearby Bonjour services
              * Library tab: browse supported service types, create custom ones
              * Preferences tab: AI settings, sort order, reset preferences
              * Broadcast: publish custom Bonjour services from this device
              * Sort/filter options: Host Name A→Z / Z→A, Service Type A→Z / Z→A, \
            Smart Home, Apple Devices, Media & Streaming, Printers & Scanners, \
            Remote Access

            DO NOT answer questions unrelated to networking, Bonjour, or this app. \
            For off-topic requests (weather, general knowledge, math, recipes, etc.), \
            politely redirect: "I can only help with Bonjour services and the KozBon \
            app. What would you like to know about your network?"

            Keep responses concise and helpful. Use Markdown formatting for lists \
            and emphasis where appropriate.

            IMPORTANT: Always respond in \(language).
            """)

        parts.append("")
        parts.append(contextBlock(context: context))

        return parts.joined(separator: "\n")
    }

    // MARK: - Context Block

    /// Builds the data context block listing the user's current services and library.
    @MainActor
    public static func contextBlock(context: ChatContext) -> String {
        var parts: [String] = ["CURRENT CONTEXT:"]

        // Discovered services
        if context.discoveredServices.isEmpty {
            parts.append("")
            parts.append("Discovered services: none (user has not started a scan, " +
                         "or no services are currently on their network)")
        } else {
            parts.append("")
            parts.append("Discovered services (\(context.discoveredServices.count)):")
            for service in context.discoveredServices.prefix(50) {
                parts.append("- \(service.service.name) · \(service.serviceType.fullType) · host: \(service.hostName)")
            }
            if context.discoveredServices.count > 50 {
                parts.append("- ...and \(context.discoveredServices.count - 50) more")
            }
        }

        // Published services
        parts.append("")
        if context.publishedServices.isEmpty {
            parts.append("Published services from this device: none")
        } else {
            parts.append("Published services from this device (\(context.publishedServices.count)):")
            for service in context.publishedServices {
                parts.append("- \(service.service.name) · \(service.serviceType.fullType)")
            }
        }

        // Library (names only, keep short)
        parts.append("")
        parts.append("Service type library (\(context.serviceTypeLibrary.count) types supported):")
        let names = context.serviceTypeLibrary.map(\.name).sorted()
        parts.append(names.joined(separator: ", "))

        return parts.joined(separator: "\n")
    }
}
