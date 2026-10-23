//
//  BonjourChatPromptBuilder+QueryBlocks.swift
//  BonjourAICore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourCore
import BonjourModels

// MARK: - Query-Triggered Blocks
//
// Blocks that attach only when the user's message asks for them:
// release notes (`<whats_new>`), Siri phrases (`<siri>`), and
// KozBon's own UI (`<app_help>`). Split from the context file so
// each stays under SwiftLint's `file_length` threshold.

extension BonjourChatPromptBuilder {

    /// Query-triggered block listing every release in KozBon's two
    /// newest major versions (4.x and 3.x today; read from the table,
    /// so 5.0 shifts it to 5.x and 4.x) plus how to shape the answer
    /// for the user's detail level. Empty unless the message asks
    /// what's new, so ordinary network questions pay nothing. Not
    /// tracked by `lastContextSignature`.
    ///
    /// `.basic` sends only summaries and asks for two short paragraphs,
    /// each covering every release in its major. `.technical` asks for
    /// a detailed answer and adds the full `highlights` of the newest
    /// ``technicalHighlightCount`` releases; all of them together run
    /// past 2,500 tokens, too much for the on-device ~4K window.
    ///
    /// Reads the static ``ReleaseNotes/all`` table directly rather
    /// than threading it through ``ChatContext`` — release notes
    /// are compile-time constant, unlike the per-session network
    /// state the context carries. `offeringCloudProviders` drops releases
    /// whose notes name a cloud AI provider, matching the What's New
    /// page.
    public static func whatsNewBlock(
        query: String,
        offeringCloudProviders: Bool = true,
        expertiseLevel: BonjourServicePromptBuilder.ExpertiseLevel = .basic
    ) -> String {
        guard ChatWhatsNewIntentDetector.wantsWhatsNew(message: query) else {
            return ""
        }
        let releases = recentMajorReleases(offeringCloudProviders: offeringCloudProviders)
        let majors = distinctMajors(of: releases)
        guard let latest = releases.first, !majors.isEmpty else {
            return ""
        }
        let majorList = majors.map { "\($0).x" }.joined(separator: " and ")
        var parts: [String] = [
            "KOZBON \(majorList) RELEASES (newest first; answer ONLY from this " +
            "list; never invent versions or changes).",
            whatsNewAnswerDirective(releases: releases, expertiseLevel: expertiseLevel)
        ]
        let detailed = expertiseLevel == .technical
            ? Set(releases.prefix(technicalHighlightCount).map(\.version))
            : []
        for release in releases {
            let label = release.version == latest.version
                ? "Version \(release.version) (latest)"
                : "Version \(release.version)"
            if detailed.contains(release.version) {
                parts.append("\(label):")
                parts.append(contentsOf: release.highlights.map { "- \($0)" })
            } else {
                parts.append("\(label): \(paragraphs(of: release.summary))")
            }
        }
        return parts.joined(separator: "\n")
    }

    /// Releases whose full highlights the `.technical` block includes,
    /// newest first. Three keeps the block near 1,600 tokens.
    static let technicalHighlightCount = 3

    /// How to shape a general "what's new" answer at the user's detail
    /// level; overrides the usual response-length guidance.
    static func whatsNewAnswerDirective(
        releases: [ReleaseNote],
        expertiseLevel: BonjourServicePromptBuilder.ExpertiseLevel
    ) -> String {
        let majors = distinctMajors(of: releases)
        let ordered = majors.map { "\($0).x" }.joined(separator: ", then ")
        let specific = "If the user asks about one specific version or feature, " +
            "answer just that from the list instead."
        switch expertiseLevel {
        case .basic:
            // The model otherwise leans on the newest release or two, so
            // name each paragraph's full version span.
            let spans = majors.map { major in
                let versions = releases
                    .filter { majorVersion(of: $0.version) == major }
                    .map(\.version)
                return "\(versions.last ?? "") through \(versions.first ?? "")"
            }.joined(separator: ", then ")
            return "ANSWER SHAPE: For a general \"what's new\" question, write exactly " +
                "\(majors.count == 1 ? "one short paragraph" : "two short paragraphs"): one per " +
                "major version (\(ordered)). Each paragraph sums up EVERY release listed " +
                "for that major version (\(spans)), not just the newest one or two: group " +
                "the changes from all of them into a few plain sentences. No headings, no " +
                "bullet lists, no version-by-version rundown. This overrides the usual " +
                "length guidance. " + specific
        case .technical:
            return "ANSWER SHAPE: For a general \"what's new\" question, give a detailed, " +
                "technical answer with one section per major version (\(ordered)). Name " +
                "the versions and the concrete changes in each: new features, AI " +
                "backends and models, platform and SDK requirements, and architecture " +
                "or behavior changes where the notes give them. Use the bulleted " +
                "highlights for the newest releases and the summaries for the rest. " +
                specific
        }
    }

    /// The displayed releases in the two newest major versions,
    /// newest first.
    static func recentMajorReleases(offeringCloudProviders: Bool) -> [ReleaseNote] {
        let displayed = ReleaseNotes.displayed(offeringCloudProviders: offeringCloudProviders)
        let majors = Set(distinctMajors(of: displayed).prefix(2))
        return displayed.filter { release in
            majorVersion(of: release.version).map { majors.contains($0) } ?? false
        }
    }

    fileprivate static func majorVersion(of version: String) -> Int? {
        version.split(separator: ".").first.flatMap { Int($0) }
    }

    /// The major versions present in `releases`, in table order.
    fileprivate static func distinctMajors(of releases: [ReleaseNote]) -> [Int] {
        var seen: [Int] = []
        for major in releases.compactMap({ majorVersion(of: $0.version) }) where !seen.contains(major) {
            seen.append(major)
        }
        return seen
    }

    /// Joins a summary's blank-line-separated paragraphs onto one line
    /// so each release stays a single entry in the block.
    fileprivate static func paragraphs(of summary: String) -> String {
        summary
            .components(separatedBy: "\n\n")
            .joined(separator: " ")
    }

    /// Query-triggered block listing KozBon's Siri actions and
    /// their phrases, for questions about Siri or the Shortcuts app.
    /// Empty otherwise, so like ``whatsNewBlock(query:)`` it costs
    /// nothing on ordinary network questions.
    ///
    /// The phrases must match `KozBonAppShortcuts` in the app target;
    /// update both together.
    public static func siriBlock(query: String) -> String {
        guard ChatSiriIntentDetector.wantsSiriHelp(message: query) else {
            return ""
        }
        return """
        KOZBON SIRI & SHORTCUTS (answer Siri and Shortcuts questions ONLY from \
        this list; never invent phrases or actions). Every phrase ends with \
        "with KozBon" and is spoken in the language Siri is set to. Siri learns \
        them after KozBon has been opened once.
        - Scan for Services: "Scan my network with KozBon" or "How many devices \
        are on my network with KozBon". Says how many devices and services it found.
        - List Discovered Services: "What's on my network with KozBon" or "Show \
        Bonjour services with KozBon". Lists every service found.
        - Find Services: "Find printers with KozBon". Also works with Apple \
        devices, smart home, speakers, AirPlay or media, and remote access or SSH.
        - Check If Device Is Online: "Check if a device is online with KozBon". \
        Asks for the device name and answers yes or no.
        - Explain a Service Type: "Explain a service type with KozBon". Asks \
        which type and reads a short explanation.
        - Broadcast a Service: "Broadcast a service with KozBon". Asks for a TCP \
        service type and a port, then advertises it.
        - Stop Broadcasting: "Stop broadcasting with KozBon".
        - Open Service in KozBon: Shortcuts app only, no phrase. Opens a service \
        an earlier step returned.
        In the Shortcuts app, tap KozBon to see every action, or add the actions \
        to a new shortcut and combine them with other steps, for example check \
        whether the printer is online and then show a notification. Personal \
        automations can run them when the device joins a Wi-Fi network, and they \
        can be assigned to the Action Button. On iPhone, iPad, and Vision Pro, \
        KozBon's Settings tab has a "Using Siri with KozBon" section with these phrases and a button \
        that opens KozBon in the Shortcuts app.
        """
    }

    /// Query-triggered block describing KozBon's own screens and
    /// controls, for "how do I broadcast / create a type / sort"
    /// questions. Empty otherwise, so like ``siriBlock(query:)`` it
    /// costs nothing on the common case. Names no AI provider, so it
    /// is safe on every storefront.
    public static func appHelpBlock(query: String) -> String {
        guard ChatAppHelpIntentDetector.wantsAppHelp(message: query) else {
            return ""
        }
        return """
        KOZBON APP HELP (describe KozBon's screens and controls ONLY from this \
        list; never invent buttons, menus, or settings). Tabs: Discover lists \
        services found on the network, Library lists every service type KozBon \
        knows, Chat (called Explore on Mac and Apple Vision Pro) is this \
        assistant, and Settings holds preferences and About.
        - Broadcast a service: in Discover, tap Broadcast (the antenna button) \
        in the toolbar. Pick a service type, enter a port number, optionally \
        change the domain and add TXT records, then tap Done. KozBon broadcasts \
        TCP services only. To stop every broadcast, say "Stop broadcasting with \
        KozBon" to Siri.
        - Create a custom service type: in Library, open the Create (+) menu in \
        the toolbar and choose Create custom service type. To edit or delete a \
        custom type, open it in Library and use Edit or Delete.
        - Sort and filter: Discover's Sort menu sorts by host or service name \
        and filters by category (smart home, Apple devices, media and \
        streaming, printers and scanners, remote access). Library's filter \
        menu filters by the same categories. Both tabs have a search field.
        - Insights: long-press a service or service type (right-click on Mac) \
        and choose Insights for an AI explanation of it.
        - Assistant settings: Settings has an Assistant section for choosing \
        the provider (Apple Intelligence, or a cloud provider using the user's \
        own API key), and a Detail level (Basic or Technical) that sets how \
        detailed answers are.
        """
    }
}
