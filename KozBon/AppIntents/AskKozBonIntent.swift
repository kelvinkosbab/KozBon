//
//  AskKozBonIntent.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import AppIntents
import Foundation
import BonjourAI
import BonjourLocalization
import BonjourModels

#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - AskKozBonIntent

/// Siri / Shortcuts intent that asks the on-device Apple
/// Intelligence assistant a question about Bonjour or the KozBon
/// app, and returns the answer as voice-suitable text.
///
/// Phase 1 of the Siri integration intentionally omits live
/// network state — the intent runs in a transient process that
/// doesn't share the scanner state with a long-running app
/// session, so injecting a stale or empty discovered-services
/// list would mislead the user. The Siri prompt
/// (`BonjourSiriPromptBuilder.systemInstructions`) tells the
/// model to redirect questions about specific devices to the
/// Discover tab.
///
/// Voice output is brief by design — see the prompt builder for
/// the formatting rules. The result is returned as
/// `IntentDialog`, which Siri reads aloud and displays in the
/// Shortcuts UI.
@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
struct AskKozBonIntent: AppIntent {

    static let title: LocalizedStringResource = "Ask KozBon"

    static let description = IntentDescription(
        // Single string literal (no `+` concatenation) so the
        // expression types as `LocalizedStringResource` rather
        // than `String`. The `appintentsmetadataprocessor`
        // extracts this for Shortcuts UI translation.
        "Ask the KozBon assistant about Bonjour services, the service-type library, or how to use the app. The answer is read aloud by Siri.",
        // `searchKeywords` indexes the intent in Spotlight so the
        // user can reach it without invoking Siri. Each keyword is
        // declared as a `LocalizedStringResource` so the system's
        // string-extraction tooling picks it up for translation.
        searchKeywords: Self.spotlightSearchKeywords
    )

    private static let spotlightSearchKeywords: [LocalizedStringResource] = [
        "bonjour",
        "mdns",
        "dns-sd",
        "kozbon",
        "network",
        "siri"
    ]

    /// Run in-process so we have direct access to the bundled
    /// service-type library (Core Data + the static catalog) and
    /// can call `FoundationModels.LanguageModelSession` without
    /// IPC. The intent is fast enough that opening the app first
    /// would be jarring — Siri reads the answer aloud while the
    /// app stays in the background.
    static let openAppWhenRun: Bool = false

    @Parameter(
        title: "Question",
        description: "What would you like to ask?",
        requestValueDialog: "What would you like to ask KozBon?"
    )
    var question: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let dialogText = await dialogText(for: question)
        // `LocalizedStringResource(stringLiteral:)` lets us wrap a
        // runtime `String` in the type `IntentDialog` requires.
        // The runtime value won't be picked up by the metadata
        // extractor (it's the model's output, not a known fixed
        // string), but the wrapping is necessary to satisfy the
        // signature.
        return .result(dialog: IntentDialog(
            LocalizedStringResource(stringLiteral: dialogText)
        ))
    }

    // MARK: - Response

    /// Builds the text to read aloud. Returning a plain `String`
    /// (rather than `some IntentResult & ProvidesDialog`) lets
    /// every branch share a single concrete return type, which
    /// the opaque-return-type machinery can then collapse into
    /// one `IntentDialog` in `perform()`.
    @MainActor
    private func dialogText(for question: String) async -> String {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "I didn't catch a question. Try again."
        }

        // Client-side validator catches obvious off-topic /
        // injection-bait inputs before they hit the model. Same
        // surface as the in-app chat for consistency — a user
        // can't bypass the chat's filtering by routing through
        // Siri.
        switch ChatInputValidator.validate(trimmed) {
        case .allowed:
            break
        case .rejected:
            return "That's outside what I can help with — ask me about Bonjour or KozBon."
        }

        #if canImport(FoundationModels)
        if #available(iOS 26, macOS 26, visionOS 26, *) {
            return await respondViaModel(to: trimmed)
        }
        #endif
        return "KozBon's voice assistant requires Apple Intelligence on iOS 26 or later. " +
            "Open the app to use the chat instead."
    }

    #if canImport(FoundationModels)
    /// On-device model invocation. Built fresh per call because
    /// the App Intent's lifetime is bounded by `perform()` — there's
    /// no persistent session to reuse. The model loads its weights
    /// quickly once and Siri's overall budget (~30s) leaves
    /// plenty of headroom.
    @available(iOS 26, macOS 26, visionOS 26, *)
    @MainActor
    private func respondViaModel(to question: String) async -> String {
        let library = BonjourServiceType.fetchAll()
        let instructions = BonjourSiriPromptBuilder.systemInstructions()
        let userTurn = BonjourSiriPromptBuilder.userTurn(
            question: question,
            library: library
        )
        let session = LanguageModelSession(instructions: instructions)
        do {
            let response = try await session.respond(to: userTurn)
            let raw = response.content
            // Voice-output cleanup: strip Markdown drift, replace
            // wire types with friendly library names, and cap
            // length at a sentence boundary. The Siri prompt
            // requests these properties of the model, but a
            // belt-and-suspenders pass here protects against
            // model drift — a single "underscore air play dot
            // underscore TCP" reading destroys the impression
            // that the assistant understands what it's saying.
            let cleaned = SiriResponsePostProcessor.process(raw, library: library)
            guard !cleaned.isEmpty else {
                return "I couldn't find an answer. Try rephrasing your question."
            }
            return cleaned
        } catch {
            // The on-device model can fail for several reasons
            // (transient resource pressure, unsupported locale,
            // user disabled Apple Intelligence). Return a
            // generic fallback rather than leaking the error
            // string into voice output.
            return "I had trouble answering that. Open KozBon's chat to try again."
        }
    }
    #endif
}
