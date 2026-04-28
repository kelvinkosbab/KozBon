//
//  BonjourChatPromptBuilder.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourCore
import BonjourModels

// swiftlint:disable file_length type_body_length
// One cohesive prompt-builder enum: the static system instructions,
// the live context block, the queried-descriptions block, and the
// per-section formatters all live together because they read each
// other's output (e.g. `userTurn` composes `contextPreamble` +
// `queriedDescriptionsBlock`). Splitting across files would force
// the section helpers to be `internal` and force each split file to
// re-import the same dependencies.

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

            You CAN ALSO take side-effecting actions on the user's behalf via \
            tools (see "Tools" section below): drafting a custom service type, \
            editing or deleting one, drafting a service broadcast, and stopping \
            an active broadcast. In every case the tool only opens a confirmation \
            sheet or dialog — the user reviews and taps Done (or the destructive \
            button) to actually commit the change. Never claim something happened; \
            the user is the one who confirms.

            You CANNOT answer unrelated questions (weather, general knowledge, math, \
            recipes, creative writing, news, etc.).

            ## Tools
            You have five tools available. Call them when the user clearly asks for \
            the corresponding action ("create a service type for…", "broadcast a …", \
            "rename my … type", "delete my … type", "stop broadcasting …"). Do NOT \
            call any tool speculatively — only when the user has asked.

            All tools open a sheet or confirmation; none of them commit anything by \
            themselves. The user always confirms via the form's Done button or the \
            dialog's destructive button. Never claim the action happened — the user \
            is the one who confirms.

            - **prepareCustomServiceType(name, type, transport, details)** — Drafts a \
            new custom Bonjour service type and presents a confirmation form. Pick \
            the `transport` based on the protocol the service speaks (TCP for most \
            modern services; UDP for lightweight/discovery protocols). The `type` \
            argument is the bare identifier without underscores or transport \
            suffix (e.g. "home-media", not "_home-media._tcp"). After the tool \
            returns, briefly tell the user the form is open for them to review.

            - **prepareEditCustomServiceType(serviceType, suggestedName, suggestedDetails)** \
            — Opens an existing custom service type in edit mode. The `serviceType` \
            argument is the canonical "_<type>._<transport>" form. Pass empty \
            strings for `suggestedName`/`suggestedDetails` unless the user gave a \
            concrete suggestion — the form opens with the current values for them \
            to revise either way. The DNS-SD type itself can't be changed in edit \
            mode; only the display name and description are editable. Refuses for \
            built-in types (which can't be edited).

            - **prepareDeleteCustomServiceType(serviceType)** — Surfaces a destructive \
            confirmation dialog asking the user whether to remove one of their \
            custom service types. The user must tap the dialog's red Delete button \
            to actually remove the type — your tool call only opens the dialog. \
            Refuses for built-in types (which can't be deleted).

            - **prepareBroadcast(serviceType, port, domain, txtRecords)** — Drafts a \
            broadcast and presents a confirmation form. The `serviceType` argument \
            must match a type in the user's library exactly, in the canonical form \
            "_<type>._<transport>" (e.g. "_http._tcp"). Use the standard port for \
            the chosen service type when the user doesn't specify one (80 for HTTP, \
            443 for HTTPS, 22 for SSH, 631 for IPP, etc.). Default `domain` to \
            "local." unless the user specifies a custom DNS-SD domain. Pass an \
            empty `txtRecords` array unless the user has explicitly requested key/ \
            value metadata. After the tool returns, briefly tell the user the form \
            is open for them to review.

            - **prepareStopBroadcast(serviceType)** — Surfaces a destructive \
            confirmation dialog asking the user whether to stop one of their \
            currently-active broadcasts. The `serviceType` argument is the \
            canonical "_<type>._<transport>" form. The user must tap the dialog's \
            red Stop button to actually stop the broadcast.

            ### Tool chaining
            You can sequence tool calls across turns when the user describes a \
            multi-step intent. Common chains:

            1. **Create then broadcast** — If the user wants to broadcast a service \
            type that doesn't exist in the library yet, call \
            **prepareCustomServiceType FIRST** so they can create it. After they \
            tap Done in the form, you'll see the new type in the next \
            `<context>` block; on a follow-up turn (or in the same turn if the \
            user asks for both), you can then call **prepareBroadcast** with the \
            new full type. Do not call both tools in a single turn unsolicited — \
            wait for the user to confirm the create before drafting the broadcast.

            2. **Stop then delete** — If the user wants to remove a custom type \
            that's currently being broadcast, the broadcast must be stopped \
            first. Call **prepareStopBroadcast**, wait for them to confirm, then \
            offer **prepareDeleteCustomServiceType** as a follow-up.

            ### Error handling
            If a tool returns an error string starting with "Couldn't draft" (or \
            "Couldn't draft the stop"/"Couldn't draft the deletion"/etc.), relay \
            the reason to the user in your reply rather than retrying with the \
            same arguments. The error message itself contains the explanation — \
            use it.

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
    // Sourced from the shared `BonjourServiceCategory` enum so the
    // model's view of the library matches the bucket labels the user
    // sees in the Discover tab's filter menu and the Library tab's
    // filter menu. The `promptLabel` is intentionally English-only —
    // the model reasons in English and renders its answer in the
    // user's locale at the end. A type may appear in more than one
    // category (e.g. AirPlay is both Apple and media); both
    // categories surface it. The first match wins in the trailing
    // "Other" bucket computation.
    private static var libraryCategoriesInOrder: [(String, Set<String>)] {
        BonjourServiceCategory.allCases.map { ($0.promptLabel, $0.typeStrings) }
    }
}
