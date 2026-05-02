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
//
// The prompt-building surface is split across two files:
//
// - `BonjourChatPromptBuilder.swift` (this file) — the public API:
//   `ChatContext`, the static system-instructions string, and the
//   `userTurn` entry point that composes context + referenced
//   descriptions + the user's message.
// - `BonjourChatPromptBuilder+Context.swift` — the data-context
//   rendering internals: `contextBlock`, `queriedDescriptionsBlock`,
//   and the per-section formatters (scan status, discovered
//   services, published services, library summary).
//
// The two halves only communicate through `ChatContext` and the
// two `public static` rendering entry points, so the split keeps
// each file under 300 lines without breaking up the logical
// pipeline that produces a turn.

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

        /// When the scan that populated `discoveredServices` was last
        /// started. `nil` means no scan has run yet (e.g., the user
        /// opened the app and went straight to the Chat tab without
        /// visiting Discover first). Used to render a scan-freshness
        /// line in the context block so the model can hedge its
        /// answers about the user's network appropriately.
        public let lastScanTime: Date?

        /// Whether a scan is currently in flight. Lets the context block
        /// tell the model "a scan is running — results may grow over
        /// the next few seconds" instead of treating a partial result
        /// as definitive.
        public let isScanning: Bool

        public init(
            discoveredServices: [BonjourService] = [],
            publishedServices: [BonjourService] = [],
            serviceTypeLibrary: [BonjourServiceType] = [],
            lastScanTime: Date? = nil,
            isScanning: Bool = false
        ) {
            self.discoveredServices = discoveredServices
            self.publishedServices = publishedServices
            self.serviceTypeLibrary = serviceTypeLibrary
            self.lastScanTime = lastScanTime
            self.isScanning = isScanning
        }
    }

    // MARK: - System Instructions

    // The chat system prompt is a single cohesive string literal that
    // covers scope, accuracy rules, context-block conventions,
    // reference-block conventions, voice/formatting, and the response-
    // length directive. Splitting it into smaller pieces would fragment
    // a prompt that reads best as one continuous block, so we disable
    // `function_body_length` locally below.
    //
    /// Builds the **static** system prompt for the chat assistant — the
    /// part that does not depend on the live service context.
    ///
    /// Kept separate from ``contextBlock(context:)`` so the
    /// `LanguageModelSession` can persist across turns while fresh
    /// context is injected into each user message only when needed.
    ///
    /// - Parameter responseLength: Desired verbosity of assistant responses.
    /// - Returns: The static system prompt string.
    @MainActor
    // swiftlint:disable:next function_body_length
    public static func systemInstructions(
        responseLength: BonjourServicePromptBuilder.ResponseLength = .standard
    ) -> String {
        let language = BonjourServicePromptBuilder.preferredLanguageName
        return """
            TOP PRIORITY: Respond in \(language).

            ACCURACY RULES:
            - Only use information from <context> and <referenced> blocks in user \
            messages to answer questions about the user's network. Do not assume \
            anything else about their environment.
            - The <context> block contains: a scan-status line (whether data is \
            fresh/stale/missing), the full list of discovered services with \
            hostnames, IP addresses, transport layer (tcp/udp) and TXT records \
            for the top-detailed entries, the user's published services, and the \
            service type library grouped by category. Consult these fields when \
            answering — e.g., cite the IP:port when the user asks how to connect, \
            cite TXT records when they ask about device capabilities or model.
            - The <referenced> block (when present) contains authoritative \
            descriptions for service types the user's message mentioned by name. \
            Prefer these descriptions over your training memory when describing \
            those types.
            - When the scan status reports "no scan has run yet" or "in progress", \
            caveat answers accordingly — e.g. "I don't see any services yet, the \
            scan may still be populating." Never say "there are no services on \
            your network" when the scan has not run.
            - When referencing services from <context>, quote the specific service \
            name or hostname verbatim (e.g., "Your 'Living Room Apple TV' is \
            advertising AirPlay"). This demonstrates you've read the context and \
            lets the user verify your answer matches their actual network.
            - When inferring something not explicitly in <context>/<referenced>, \
            prefix with "Likely:" or "This typically means:". Never use confident \
            language for inferred content.
            - Never invent port numbers, protocol versions, service names, or vendor \
            details. If the user asks about a service that is not in the latest \
            <context> block AND the scan status is not "in progress", say you \
            don't see it on their network.
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
            - Bonjour, mDNS, and DNS-SD — what they are, how local-network \
            service discovery works, what the underlying protocols do
            - ANY Bonjour service type KozBon recognizes — HTTP, AirPlay, \
            AirDrop, HomeKit (HAP), Matter, Thread, IPP/AirPrint, SSH, SMB, \
            Sonos, Spotify Connect, Chromecast, Plex, Jellyfin, mDNS-SD, \
            and dozens more. Explaining what a protocol does, what kinds of \
            devices use it, what its TCP/UDP characteristics are, and what \
            its TXT-record conventions mean is squarely in scope
            - Smart-home and networking standards more broadly when they're \
            relevant to service discovery (Matter over Wi-Fi vs. Thread, \
            HomeKit accessory protocol, AirPlay 2 vs. AirPlay 1, etc.)
            - Services currently discovered on the user's network
            - Services the user is broadcasting from this device
            - The KozBon service type library and its categories
            - How to use KozBon (Discover, Library, Preferences tabs; \
            broadcasting; filtering and sorting)

            **When in doubt, answer.** If the user's question touches ANY \
            service-discovery protocol, networking concept, smart-home \
            standard, or anything in the KozBon library, you should answer \
            it — even if you're not 100% sure of every detail. Use the \
            "Likely:" hedge prefix when inferring; only refuse when the \
            question is clearly unrelated.

            You CANNOT answer questions that are genuinely off-topic — \
            weather, recipes, creative writing, math problems, current news, \
            celebrity facts, code generation in arbitrary languages, \
            translation. CANNOT take direct actions either — for creating, \
            editing, broadcasting, or stopping services, tell the user to \
            use the in-app UI (Library tab for service types, Discover tab's \
            Broadcast button for new broadcasts).

            ## Refusal template
            ONLY use this template when the question is clearly off-topic. \
            A question about a protocol like Matter, Thread, HomeKit, \
            AirPlay, or any other service the app supports is NEVER \
            off-topic — answer those questions even if the user isn't \
            currently seeing that service on their network.

            For genuinely off-topic questions, reply in a single sentence:
            "That's outside what I can help with — ask me about Bonjour \
            services, the service type library, or how to use KozBon."

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

    /// Combines the stable context preamble (if needed) and the query-
    /// triggered service-type descriptions (if any matches) with the
    /// user's message.
    ///
    /// The two blocks have different re-injection policies:
    ///
    /// - **Stable context** (scan status, discovered/published/library)
    ///   is injected only on the first turn or when the underlying
    ///   content has materially changed. That keeps multi-turn history
    ///   from bloating with duplicate data every turn.
    /// - **Queried descriptions** (library types the user's message
    ///   mentions by name) are computed fresh and re-injected every turn
    ///   they're relevant. They're NOT tracked by `lastContextBlock`, so
    ///   varying them per-turn doesn't force the stable block to
    ///   re-send.
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
        var sections: [String] = []

        if isFirstTurn || contextChanged {
            sections.append(contextPreamble(context: context))
        }

        let queried = queriedDescriptionsBlock(context: context, query: userMessage)
        if !queried.isEmpty {
            sections.append("<referenced>\n\(queried)\n</referenced>\n")
        }

        sections.append(userMessage)
        return sections.joined()
    }

}
