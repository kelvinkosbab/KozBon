//
//  SiriResponsePostProcessor.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourModels

// MARK: - SiriResponsePostProcessor

/// Voice-output cleanup for the on-device model's reply before
/// it's handed to Siri.
///
/// The Siri prompt instructs the model to emit plain prose with no
/// Markdown and to spell out service types as readable words. The
/// model **mostly** obeys — but drift is real, and a single
/// "underscore air play dot underscore TCP" reading destroys the
/// impression that the assistant understands what it's saying.
/// This post-processor catches the drift cases.
///
/// Three concerns are addressed in order:
///
/// 1. **Wire-type rendering** — `_airplay._tcp` is replaced with
///    the library's friendly name ("AirPlay") when the type is
///    known, or a TTS-friendly fallback ("airplay over TCP") when
///    it isn't. Done first so the underscore-stripping that
///    follows can't corrupt them.
///
/// 2. **Markdown stripping** — `**bold**`, `*italic*`, `` `code` ``,
///    code fences, and Markdown link/heading/list markers are
///    removed. Underscore-italic is intentionally NOT stripped
///    because it would chew through any remaining underscored
///    identifiers; the model rarely emits it anyway.
///
/// 3. **Length cap** — the prompt asks for 2-3 sentences. As a
///    last-resort guard against runaway output, the post-
///    processor truncates at the last sentence boundary before a
///    600-character ceiling. No truncation marker is appended
///    (Siri would read "ellipsis" or "truncated" literally).
public enum SiriResponsePostProcessor {

    // MARK: - Public

    /// Defensive ceiling on the length of voice output. Sized to
    /// fit roughly 4-5 short sentences (~30-45 seconds of TTS),
    /// which is well past the prompt's "2-3 sentences" target —
    /// truncation here is a last-resort guard, not the primary
    /// length control.
    public static let maxVoiceLength = 600

    /// Cleans `input` for voice output. Idempotent: running the
    /// processor on already-clean text is a no-op.
    ///
    /// - Parameters:
    ///   - input: Raw model output.
    ///   - library: Service-type library used to look up friendly
    ///     names for any wire-type tokens encountered. Pass an
    ///     empty array to skip the lookup (the fallback rendering
    ///     still applies).
    /// - Returns: Voice-friendly text suitable for `IntentDialog`.
    public static func process(
        _ input: String,
        library: [BonjourServiceType]
    ) -> String {
        var output = input
        output = replaceServiceTypeWireForms(output, library: library)
        output = stripMarkdown(output)
        output = truncateToSentenceBoundary(output, maxLength: maxVoiceLength)
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Wire-Type Replacement

    /// Replaces `_<type>._tcp` and `_<type>._udp` tokens with
    /// voice-readable forms. When the wire type matches a library
    /// entry, uses the library's display name (e.g.,
    /// `_airplay._tcp` → "AirPlay"). Otherwise falls back to
    /// "type over TCP" / "type over UDP" so Siri at least
    /// pronounces the words rather than the punctuation.
    ///
    /// Exposed `internal` for direct testing without going through
    /// the full `process(_:library:)` pipeline.
    static func replaceServiceTypeWireForms(
        _ input: String,
        library: [BonjourServiceType]
    ) -> String {
        let pattern = #"_([a-z0-9-]+)\._(tcp|udp)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return input
        }

        let nsInput = input as NSString
        let range = NSRange(location: 0, length: nsInput.length)
        var output = ""
        var cursor = 0

        regex.enumerateMatches(in: input, options: [], range: range) { match, _, _ in
            guard let match else { return }
            let matchRange = match.range
            output += nsInput.substring(with: NSRange(location: cursor, length: matchRange.location - cursor))

            let wireType = nsInput.substring(with: matchRange)
            output += friendlyName(forWireType: wireType, library: library)

            cursor = matchRange.location + matchRange.length
        }
        output += nsInput.substring(with: NSRange(location: cursor, length: nsInput.length - cursor))
        return output
    }

    /// Returns the voice-readable form for a single wire type.
    /// Library lookup is case-sensitive on the canonical
    /// `_<type>._<transport>` form; the fallback handles novel
    /// types not in the library yet.
    private static func friendlyName(
        forWireType wireType: String,
        library: [BonjourServiceType]
    ) -> String {
        // Library entries store the wire form in `fullType`. A
        // direct match returns the entry's display `name`,
        // which is already voice-friendly ("AirPlay", "Web
        // Server", "Secure Shell", etc.).
        if let match = library.first(where: { $0.fullType.lowercased() == wireType.lowercased() }) {
            return match.name
        }

        // Fallback: render the bare type as "name over TCP/UDP".
        // Strips the leading underscore, splits on `._`, and
        // formats the components readably.
        let trimmed = wireType.hasPrefix("_") ? String(wireType.dropFirst()) : wireType
        let parts = trimmed.components(separatedBy: "._")
        guard parts.count == 2 else { return wireType }
        let typePart = parts[0].replacingOccurrences(of: "-", with: " ")
        let transportPart = parts[1].uppercased()
        return "\(typePart) over \(transportPart)"
    }

    // MARK: - Markdown Stripping

    /// Strips a conservative subset of Markdown that Siri's TTS
    /// would otherwise mispronounce:
    ///
    /// - Bold (`**...**`) and emphasis-asterisk (`*...*`)
    /// - Inline code (`` `...` ``) and code fences (```` ```...``` ````)
    /// - Headings (`#`, `##`, etc.)
    /// - Hyphen / asterisk list markers at line start
    /// - Markdown links (`[text](url)` → `text`)
    ///
    /// Underscore italics (`_..._`) are intentionally NOT stripped
    /// — too risky around remaining identifiers — so the wire-
    /// type replacement above must run first.
    static func stripMarkdown(_ input: String) -> String {
        var output = input

        // Code fences first — they wrap lines and we want to drop
        // the fence markers without touching their contents.
        output = output.replacingOccurrences(
            of: "```",
            with: ""
        )

        // Markdown link `[text](url)` → `text`.
        output = output.replacingOccurrences(
            of: #"\[([^\]]+)\]\([^)]+\)"#,
            with: "$1",
            options: .regularExpression
        )

        // Bold `**text**` → `text`. Done before single-asterisk
        // emphasis so the four-character form is handled cleanly.
        output = output.replacingOccurrences(
            of: #"\*\*([^*]+)\*\*"#,
            with: "$1",
            options: .regularExpression
        )

        // Single-asterisk emphasis `*text*` → `text`.
        output = output.replacingOccurrences(
            of: #"\*([^*]+)\*"#,
            with: "$1",
            options: .regularExpression
        )

        // Inline code `` `text` `` → `text`.
        output = output.replacingOccurrences(
            of: "`([^`]+)`",
            with: "$1",
            options: .regularExpression
        )

        // Strip line-starting heading markers (`# `, `## `, etc.).
        // The trailing space is required so we don't strip `#`
        // characters appearing mid-sentence.
        output = output.replacingOccurrences(
            of: #"(?m)^#+\s+"#,
            with: "",
            options: .regularExpression
        )

        // Strip line-starting list markers (`- `, `* `, `1. ` etc.).
        // Replace with a single space so adjacent words don't
        // run together when Siri reads the line.
        output = output.replacingOccurrences(
            of: #"(?m)^\s*([-*]|\d+\.)\s+"#,
            with: "",
            options: .regularExpression
        )

        return output
    }

    // MARK: - Length Cap

    /// Truncates `input` at the last sentence boundary that fits
    /// within `maxLength`. If no sentence boundary exists in the
    /// last 100 characters of the prefix, hard-truncates at
    /// `maxLength` (better than reading 2 KB of model drift).
    /// No truncation marker is appended — Siri would read it.
    ///
    /// Inputs at or below `maxLength` pass through unchanged.
    static func truncateToSentenceBoundary(
        _ input: String,
        maxLength: Int
    ) -> String {
        guard maxLength > 0 else { return "" }
        guard input.count > maxLength else { return input }

        let prefix = String(input.prefix(maxLength))
        // Look for the last `. ` / `! ` / `? ` (or end-of-string
        // forms) and cut the string just after it. Searching in
        // reverse so the result is the longest valid prefix.
        let boundaries = [". ", "! ", "? ", ".\n", "!\n", "?\n"]
        let cutIndices = boundaries.compactMap { boundary -> String.Index? in
            prefix.range(of: boundary, options: .backwards)?.upperBound
        }
        if let cut = cutIndices.max() {
            return String(prefix[..<cut]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return prefix
    }
}
