//
//  MarkdownContentView.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - MarkdownContentView

/// Renders a block of text with lightweight Markdown support.
///
/// Supports:
/// - `# `, `## `, `### ` headings
/// - `- ` and `* ` bullet lists
/// - Inline `**bold**`, `*italic*`, and `` `code` `` via `AttributedString`
///
/// Used for AI-generated responses in both `ServiceExplanationSheet` and `BonjourChatView`.
public struct MarkdownContentView: View {

    private let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        let lines = text
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }

        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                lineView(for: line)
            }
        }
        .textSelection(.enabled)
    }

    @ViewBuilder
    private func lineView(for line: String) -> some View {
        if line.isEmpty {
            Spacer().frame(height: 4)
        } else if line.hasPrefix("# ") {
            inlineText(String(line.dropFirst(2)))
                .font(.title2).bold()
                .accessibilityAddTraits(.isHeader)
                .padding(.top, 4)
        } else if line.hasPrefix("## ") {
            inlineText(String(line.dropFirst(3)))
                .font(.title3).bold()
                .foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, 4)
        } else if line.hasPrefix("### ") {
            inlineText(String(line.dropFirst(4)))
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, 2)
        } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
            HStack(alignment: .top, spacing: 6) {
                Text("•")
                    .foregroundStyle(.secondary)
                inlineText(String(line.dropFirst(2)))
                    .font(.body)
            }
        } else {
            inlineText(line)
                .font(.body)
        }
    }

    /// Renders a single line of text with inline Markdown (bold, italic, code).
    private func inlineText(_ text: String) -> Text {
        if let attributed = try? AttributedString(markdown: text) {
            return Text(attributed)
        }
        return Text(text)
    }
}
