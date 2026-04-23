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
    /// Builds the **static** system prompt for the chat assistant — the part that
    /// does not depend on the live service context.
    ///
    /// Kept separate from ``contextBlock(context:)`` so the `LanguageModelSession`
    /// can persist across turns while fresh context is injected into each user
    /// message only when needed.
    ///
    /// - Parameter responseLength: Desired verbosity of assistant responses.
    /// - Returns: The static system prompt string.
    @MainActor
    public static func systemInstructions(
        responseLength: BonjourServicePromptBuilder.ResponseLength = .standard
    ) -> String {
        let language = BonjourServicePromptBuilder.preferredLanguageName
        return """
            TOP PRIORITY: Respond in \(language).

            ACCURACY RULES:
            - Only use information from <context> blocks in user messages to answer \
            questions about the user's network. Do not assume anything else about \
            their environment.
            - When referencing services from <context>, quote the specific service \
            name or hostname verbatim (e.g., "Your 'Living Room Apple TV' is \
            advertising AirPlay"). This demonstrates you've read the context and lets \
            the user verify your answer matches their actual network.
            - When inferring something not explicitly in the context, prefix with \
            "Likely:" or "This typically means:". Never use confident language for \
            inferred content.
            - Never invent port numbers, protocol versions, service names, or vendor \
            details. If the user asks about a service that is not in the latest \
            <context> block, say you don't see it on their network.
            - When the user's question is ambiguous or could apply to multiple \
            services in <context>, ask one brief clarifying question instead of \
            guessing which service they mean.
            - Remember previous turns in the conversation. The user may ask follow-up \
            questions that build on earlier answers.

            ---

            You are KozBon's on-device assistant. You help the user understand Bonjour \
            (mDNS/DNS-SD) network services on their local network and how to use the \
            KozBon app.

            ## Scope
            You CAN answer questions about:
            - Services currently discovered on the user's network
            - Services the user is broadcasting from this device
            - The service type library
            - How to use KozBon (Discover, Library, Preferences tabs; broadcasting; \
            filtering and sorting)

            You CANNOT answer unrelated questions (weather, general knowledge, math, \
            recipes, creative writing, news, etc.).

            ## Refusal template
            When asked an off-topic question, reply in a single sentence:
            "That's outside what I can help with — ask me about your discovered \
            services, the service type library, or how to broadcast a service."

            ## Output format
            VOICE: Address the user as "you". Use second person, active voice.

            FORMATTING: Wrap service names in single quotes, protocol types in \
            backticks (`_airplay._tcp`), and any command-line tokens in backticks. \
            Use Markdown lists for enumerations.

            OUTPUT: Start with the first sentence of your answer. Do not emit \
            conversational preamble ("Sure,", "Here's...") — the user sees tokens \
            stream and preambles make that feel slow.

            \(BonjourServicePromptBuilder.responseLengthDirective(responseLength))
            """
    }

    // MARK: - Context Preamble

    /// Builds a preamble to prepend to a user message when the context is new or has changed.
    ///
    /// Wraps the context block in `<context>` tags so the model can distinguish it
    /// from the user's actual question.
    ///
    /// - Parameter context: Current snapshot of services and library.
    /// - Returns: A multi-line string safe to prepend to a user message.
    @MainActor
    public static func contextPreamble(context: ChatContext) -> String {
        return """
            <context>
            \(contextBlock(context: context))
            </context>

            """
    }

    /// Combines a context preamble (if needed) with the user's message.
    ///
    /// - Parameters:
    ///   - userMessage: The trimmed user message text.
    ///   - context: Current snapshot of services and library.
    ///   - isFirstTurn: Whether this is the first message in the conversation.
    ///   - contextChanged: Whether the live context has materially changed since the
    ///     last turn. Ignored when `isFirstTurn` is `true`.
    /// - Returns: The final user turn to send to the model.
    @MainActor
    public static func userTurn(
        message userMessage: String,
        context: ChatContext,
        isFirstTurn: Bool,
        contextChanged: Bool
    ) -> String {
        if isFirstTurn || contextChanged {
            return contextPreamble(context: context) + userMessage
        }
        return userMessage
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
