//
//  BonjourServicePromptBuilder+ReleaseHighlights.swift
//  BonjourAICore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - BonjourServicePromptBuilder + Release Highlights

/// The "What's New" half of the prompt builder.
///
/// Split out of `BonjourServicePromptBuilder.swift` to keep that
/// file and its enum body under the length limits. The subject here
/// is a product change rather than a Bonjour protocol, so these
/// prompts share nothing with the service ones beyond the expertise
/// and response-length directives.
extension BonjourServicePromptBuilder {

    /// System instructions for explaining a single "What's New"
    /// release highlight in terms of its impact on the user.
    ///
    /// Distinct from the service / service-type instructions: the
    /// subject here isn't a Bonjour protocol but a product change,
    /// so the model is steered toward "what does this mean for me,
    /// and why would I care?" rather than protocol mechanics. Kept
    /// deliberately short — an insight on a release bullet should
    /// be a couple of sentences, not a sectioned essay — and
    /// grounded only in the highlight text we provide so the model
    /// can't invent features the release didn't ship.
    public static var releaseHighlightSystemInstructions: String {
        let languageName = preferredLanguageName
        return """
            TOP PRIORITY: Respond in \(languageName).

            ACCURACY RULES:
            - Explain ONLY the change described in the provided release \
            highlight. Do NOT invent other features, version numbers, dates, \
            or changes the highlight doesn't mention.
            - If the highlight is about an internal / developer-facing change \
            (compatibility, refactors, build tooling), say plainly that it's \
            mostly behind-the-scenes and what little the user would notice — \
            don't oversell it.
            - When inferring user impact not stated outright, hedge inline with \
            "typically", "usually", or "should" rather than confident claims.

            ---

            You are KozBon's friendly assistant explaining what a new app update \
            means for the person using it. KozBon is an app for discovering and \
            broadcasting Bonjour (mDNS/DNS-SD) network services on Apple devices.

            VOICE: Address the user as "you". Second person, active voice, warm \
            and plain-spoken — like a friend telling them why an update is worth \
            caring about.

            FOCUS: Answer two things in order — (1) what changed, in plain terms, \
            and (2) how it affects them or what they can now do. Skip product \
            history and marketing language.

            OUTPUT: Reply in ONE short paragraph of 2-3 sentences. Do NOT use \
            Markdown headings or bullet lists — this is a quick insight, not a \
            document. Start directly with the explanation; no preamble like \
            "Sure" or "This update".
            """
    }

    // MARK: - Release Highlight Prompt

    /// Builds a prompt asking the model to explain what a single
    /// release highlight means for the user.
    ///
    /// - Parameters:
    ///   - releaseHighlight: The verbatim highlight bullet from
    ///     ``ReleaseNotes/all`` the user long-pressed.
    ///   - version: The marketing version the highlight belongs to
    ///     (e.g. "4.6"), so the model can ground its answer.
    ///   - expertiseLevel: Tone directive — basic vs. technical.
    ///   - responseLength: Verbosity directive. The system prompt
    ///     already pins a short single-paragraph shape; this nudges
    ///     within that.
    /// - Returns: A formatted prompt string.
    @MainActor
    public static func buildPrompt(
        releaseHighlight: String,
        version: String,
        expertiseLevel: ExpertiseLevel = .basic,
        responseLength: ResponseLength = .standard
    ) -> String {
        var parts: [String] = []

        parts.append("Here is a single highlight from KozBon version \(version):")
        parts.append("")
        parts.append("\"\(releaseHighlight)\"")
        parts.append("")
        parts.append(expertiseLevelDirective(expertiseLevel))
        parts.append(responseLengthDirective(responseLength))
        parts.append("")
        parts.append(
            "In a couple of sentences, explain what this change is and how it " +
            "affects me as someone using the app. Please respond in \(preferredLanguageName)."
        )

        return parts.joined(separator: "\n")
    }
}
