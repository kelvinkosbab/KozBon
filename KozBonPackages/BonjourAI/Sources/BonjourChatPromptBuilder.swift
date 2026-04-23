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

    // MARK: - Context Block

    /// Number of discovered services rendered with full detail (addresses,
    /// TXT records, transport). The rest of the list falls back to a
    /// compact one-liner. Picked to balance context richness against the
    /// on-device model's token budget — 10 richly-detailed services
    /// handles the typical home network where the user is most likely to
    /// ask about a specific device, while the brief tail still lets the
    /// model enumerate the full list when asked.
    private static let richDetailServiceCap = 10

    /// Hard cap on the total number of discovered services rendered.
    /// Services beyond this are summarized as "...and N more" so the
    /// context block has a predictable upper bound.
    private static let briefDetailServiceCap = 50

    /// Per-service caps to keep individual rich entries from blowing up.
    private static let addressesPerService = 3
    private static let txtRecordsPerService = 6

    /// Builds the data context block listing the user's current services
    /// and library.
    ///
    /// Structure:
    ///
    /// 1. **Scan status** — "Last scan N seconds ago" or "no scan yet" so
    ///    the model can caveat stale answers appropriately.
    /// 2. **Discovered services** — first N rendered with full detail
    ///    (addresses, TXT records, transport), rest compact.
    /// 3. **Published services** — what this device is broadcasting.
    /// 4. **Service type library** — grouped by category (smart home,
    ///    Apple devices, media, printers, remote access, other) with
    ///    names only; query-specific full descriptions are injected
    ///    separately via ``queriedDescriptionsBlock(context:query:)``
    ///    to keep the stable block compact.
    @MainActor
    public static func contextBlock(context: ChatContext) -> String {
        var parts: [String] = ["CURRENT CONTEXT:", ""]

        parts.append(scanStatusLine(context: context))
        parts.append("")
        parts.append(contentsOf: discoveredServicesLines(context: context))
        parts.append("")
        parts.append(contentsOf: publishedServicesLines(context: context))
        parts.append("")
        parts.append(contentsOf: libraryLines(context: context))

        return parts.joined(separator: "\n")
    }

    /// Query-triggered block that appends detailed descriptions for any
    /// service types mentioned in the user's message. Returns an empty
    /// string when no matches exist so multi-turn history stays compact
    /// for general questions. Called from ``userTurn`` on every user
    /// message (NOT tracked by `lastContextBlock`, so it doesn't force
    /// re-injection of the stable context on every turn).
    public static func queriedDescriptionsBlock(
        context: ChatContext,
        query: String
    ) -> String {
        let lowered = query.lowercased()
        // Case-insensitive substring match on the type's display name.
        // False positives on very short names (`SSH`, `IPP`) are rare in
        // natural chat questions and cost at most a few extra lines of
        // context — a fair trade for not requiring proper word-boundary
        // tokenization on every send.
        let matches = context.serviceTypeLibrary.filter { serviceType in
            !serviceType.name.isEmpty
                && lowered.contains(serviceType.name.lowercased())
                && serviceType.localizedDetail != nil
        }
        guard !matches.isEmpty else { return "" }

        var parts: [String] = ["REFERENCED SERVICE TYPES (from the user's question):"]
        // Cap at 5 to bound the block size even when the user's message
        // happens to match many types.
        for serviceType in matches.prefix(5) {
            let detail = serviceType.localizedDetail ?? ""
            parts.append("- \(serviceType.name) (\(serviceType.fullType)): \(detail)")
        }
        return parts.joined(separator: "\n")
    }

    // MARK: - Context Section Builders

    /// Renders a single-line scan-freshness summary so the model can
    /// distinguish "data is fresh" from "data is stale" from "no scan
    /// has run". The model is instructed (via ACCURACY RULES) to caveat
    /// its answers when data is stale or missing.
    private static func scanStatusLine(context: ChatContext) -> String {
        if context.isScanning {
            return "Scan status: in progress — results may still be populating."
        }
        guard let lastScan = context.lastScanTime else {
            return "Scan status: no scan has run yet in this session."
        }
        let elapsed = Int(Date().timeIntervalSince(lastScan))
        return "Scan status: last scan started \(elapsed)s ago."
    }

    @MainActor
    private static func discoveredServicesLines(context: ChatContext) -> [String] {
        guard !context.discoveredServices.isEmpty else {
            return [
                "Discovered services: none yet " +
                "(scan has not populated any results; if the user asks about " +
                "specific services, tell them the scan is still running or " +
                "suggest they wait a moment)."
            ]
        }
        var lines: [String] = ["Discovered services (\(context.discoveredServices.count)):"]
        for (index, service) in context.discoveredServices.enumerated() {
            if index >= briefDetailServiceCap { break }
            let transport = service.serviceType.transportLayer.string.lowercased()
            lines.append(
                "- \(service.service.name) · \(service.serviceType.fullType) · " +
                "\(transport) · host: \(service.hostName)"
            )
            if index < richDetailServiceCap {
                if !service.addresses.isEmpty {
                    let addrs = service.addresses.prefix(addressesPerService)
                        .map(\.ipPortString)
                        .joined(separator: ", ")
                    lines.append("    addresses: \(addrs)")
                }
                if !service.dataRecords.isEmpty {
                    let records = service.dataRecords.prefix(txtRecordsPerService)
                        .map { "\($0.key)=\($0.value)" }
                        .joined(separator: ", ")
                    lines.append("    txt: \(records)")
                }
            }
        }
        if context.discoveredServices.count > briefDetailServiceCap {
            let remainder = context.discoveredServices.count - briefDetailServiceCap
            lines.append("- ...and \(remainder) more")
        }
        return lines
    }

    @MainActor
    private static func publishedServicesLines(context: ChatContext) -> [String] {
        guard !context.publishedServices.isEmpty else {
            return ["Published services from this device: none"]
        }
        var lines: [String] = ["Published services from this device (\(context.publishedServices.count)):"]
        for service in context.publishedServices {
            lines.append("- \(service.service.name) · \(service.serviceType.fullType)")
        }
        return lines
    }

    @MainActor
    private static func libraryLines(context: ChatContext) -> [String] {
        let library = context.serviceTypeLibrary
        guard !library.isEmpty else {
            return ["Service type library: empty"]
        }
        var lines: [String] = [
            "Service type library (\(library.count) types, grouped by category):"
        ]
        // Types that fell into a category. Used to compute an "Other"
        // bucket for types we don't explicitly categorize.
        var categorizedNames = Set<String>()
        for (categoryTitle, typeIDs) in libraryCategoriesInOrder {
            let matched = library
                .filter { typeIDs.contains($0.type) }
                .map(\.name)
                .sorted()
            guard !matched.isEmpty else { continue }
            matched.forEach { categorizedNames.insert($0) }
            lines.append("- \(categoryTitle): \(matched.joined(separator: ", "))")
        }
        // Everything else, alphabetized — keeps small/obscure types
        // discoverable without having to hand-categorize every one.
        let remaining = library
            .map(\.name)
            .filter { !categorizedNames.contains($0) }
            .sorted()
        if !remaining.isEmpty {
            lines.append("- Other: \(remaining.joined(separator: ", "))")
        }
        return lines
    }

    // MARK: - Library Categories
    //
    // Mirrors the filter buckets in `BonjourServicesViewModel.flatActiveServices`
    // so the model's view of the library matches the grouping the user
    // sees in the Discover tab's sort menu. If categories change there,
    // update the arrays here too. A type may appear in more than one
    // category (e.g. AirPlay is both Apple and media) — the first
    // matching category wins in the `Other` computation, but both
    // appear in their respective lines.
    private static let libraryCategoriesInOrder: [(String, Set<String>)] = [
        ("Smart Home", [
            "matter", "meshcop", "matterc", "matterd",
            "hap", "homekit", "home-assistant",
            "powerview", "sonos", "spotify-connect"
        ]),
        ("Apple Devices", [
            "airplay", "airdrop", "appletv", "appletv-v2", "appletv-v3", "appletv-v4",
            "appletv-itunes", "appletv-pair", "apple-mobdev", "apple-mobdev2",
            "apple-midi", "applerdbg", "apple-sasl",
            "hap", "homekit", "companion-link", "continuity",
            "keynoteaccess", "keynotepair", "keynotepairing",
            "KeynoteControl", "mediaremotetv", "raop",
            "device-info", "airport", "eppc", "workstation",
            "carplay_ctrl", "sleep-proxy"
        ]),
        ("Media & Streaming", [
            "airplay", "raop", "spotify-connect", "sonos",
            "googlecast", "daap", "dpap", "home-sharing",
            "rtsp", "roku-rcp", "amzn-wplay", "nvstream",
            "touch-able", "ptp"
        ]),
        ("Printers & Scanners", [
            "printer", "ipp", "ipps", "pdl-datastream",
            "riousbprint", "scanner", "uscan", "uscans"
        ]),
        ("Remote Access", [
            "ssh", "sftp-ssh", "udisks-ssh", "vnc", "rfb",
            "rdp", "telnet", "eppc", "servermgr"
        ])
    ]
}
