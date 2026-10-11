//
//  SiriPlainText.swift
//  BonjourAppIntents
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - SiriPlainText

/// Turns the Markdown an explainer streams into text Siri can speak,
/// so it doesn't read out "hash hash" or asterisks.
enum SiriPlainText {

    static func from(markdown: String) -> String {
        markdown
            .components(separatedBy: .newlines)
            .map { plainLine(stripBlockPrefix($0.trimmingCharacters(in: .whitespaces))) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    /// Drops heading, list, and quote markers from the start of a line.
    private static func stripBlockPrefix(_ line: String) -> String {
        let patterns = [#"^#{1,6}\s+"#, #"^[-*+]\s+"#, #"^\d+[.)]\s+"#, #"^>\s?"#]
        var result = line
        for pattern in patterns {
            if let range = result.range(of: pattern, options: .regularExpression) {
                result.removeSubrange(range)
            }
        }
        return result
    }

    /// Resolves inline emphasis, code, and links to their text.
    private static func plainLine(_ line: String) -> String {
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace
        )
        guard let attributed = try? AttributedString(markdown: line, options: options) else {
            return line
        }
        return String(attributed.characters).trimmingCharacters(in: .whitespaces)
    }
}
