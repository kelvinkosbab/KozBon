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
/// - `1. `, `2. `, `42. ` ordered (numbered) lists. The chat assistant's
///   discovered-services prompt mirrors the context block's numbering,
///   so this is the natural shape its lists arrive in.
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
        // Disable implicit animations on view-tree changes during
        // streaming. Tokens arrive character-by-character; without
        // this, the diff between consecutive renders animates and
        // shows a visible flash whenever a line crosses a Markdown
        // boundary (e.g., a `#` arrives and turns a paragraph into
        // a heading). The safety net is cheap — just instructs
        // SwiftUI to apply changes synchronously without easing.
        .transaction { $0.animation = nil }
    }

    @ViewBuilder
    private func lineView(for line: String) -> some View {
        // Every branch returns a `Text` (or a Text-modifier chain) so
        // SwiftUI can diff line content across token-by-token
        // streaming updates without changing the underlying view
        // shape. The earlier implementation rendered bullets as an
        // `HStack { Text("•"); Text }` and empty lines as a
        // `Spacer`, which caused visible flashes whenever a
        // streaming line transitioned between Markdown forms (e.g.,
        // from "S" → "- S" — Text → HStack — forced a tear-down and
        // rebuild). Keeping every branch Text-shaped lets SwiftUI
        // diff in place.
        if line.isEmpty {
            // Hidden, content-shaped placeholder so empty paragraphs
            // still occupy a small vertical slot (matching the
            // previous `Spacer().frame(height: 4)`) without
            // introducing a non-Text view shape.
            Text(verbatim: " ")
                .font(.system(size: 4))
                .foregroundStyle(.clear)
                .accessibilityHidden(true)
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
            // Bullet rendered as a single `Text` with an attributed
            // run for the glyph (so it can stay
            // `.foregroundStyle(.secondary)`), the original visual
            // intent. Crucially this is still a `Text` — the
            // structural homogeneity with surrounding paragraph
            // lines is what fixes the streaming flash.
            bulletText(String(line.dropFirst(2)))
                .font(.body)
        } else if let (number, rest) = Self.parseOrderedListPrefix(line) {
            // Ordered (`1. `, `2. `, …) list line. The chat
            // assistant's discovered-services responses arrive in this
            // shape because the context block uses numbered lists and
            // the system prompt asks the model to mirror that
            // numbering. Without this branch they rendered as plain
            // paragraphs run together, which was the readability
            // problem this view was extended to fix.
            orderedText(number: number, content: rest)
                .font(.body)
        } else {
            inlineText(line)
                .font(.body)
        }
    }

    /// Detects an ordered-list prefix at the start of a line.
    ///
    /// Matches `<integer>. <space>` or `<integer>) <space>` (e.g.
    /// `"1. "`, `"42. "`, `"3) "`). Caps the integer at 4 digits so a
    /// stray "1234567." in service-detail prose isn't mis-classified
    /// as a list marker. Returns the parsed number and the remaining
    /// content, or `nil` if the line isn't an ordered-list item.
    ///
    /// Internal-but-static so it can be exercised directly by the
    /// renderer's tests without spinning up SwiftUI.
    static func parseOrderedListPrefix(_ line: String) -> (number: Int, rest: String)? {
        var index = line.startIndex
        var digits = ""
        while index < line.endIndex, line[index].isNumber, digits.count < 4 {
            digits.append(line[index])
            index = line.index(after: index)
        }
        guard !digits.isEmpty, let number = Int(digits) else { return nil }
        guard index < line.endIndex,
              line[index] == "." || line[index] == ")"
        else { return nil }
        let afterMarker = line.index(after: index)
        guard afterMarker < line.endIndex, line[afterMarker] == " " else { return nil }
        let restStart = line.index(after: afterMarker)
        return (number, String(line[restStart...]))
    }

    /// Renders a single line of text with inline Markdown (bold, italic, code).
    private func inlineText(_ text: String) -> Text {
        if let attributed = try? AttributedString(markdown: text) {
            return Text(attributed)
        }
        return Text(text)
    }

    /// Renders a bullet-list line as a single `Text` view: a
    /// secondary-colored "•  " glyph followed by the line's inline
    /// Markdown content, joined as one `AttributedString`. Keeps the
    /// view structure homogeneous with paragraph and heading lines
    /// so SwiftUI can diff streaming content without rebuilding.
    private func bulletText(_ text: String) -> Text {
        var bullet = AttributedString("•  ")
        bullet.foregroundColor = .secondary

        let content: AttributedString
        if let attributed = try? AttributedString(markdown: text) {
            content = attributed
        } else {
            content = AttributedString(text)
        }
        return Text(bullet + content)
    }

    /// Renders an ordered-list line ("1. Foo", "2. Bar") as a single
    /// `Text`: a secondary-colored "<number>.  " marker followed by
    /// the line's inline Markdown content, joined as one
    /// `AttributedString`. Same single-`Text` shape as `bulletText`
    /// so SwiftUI's diff stays cheap during token-by-token streaming.
    ///
    /// The marker uses two trailing spaces (matching `bulletText`'s
    /// `"•  "`) so the columns of glyph + content stay roughly
    /// aligned across the two list types in a mixed-format response.
    private func orderedText(number: Int, content text: String) -> Text {
        var marker = AttributedString("\(number).  ")
        marker.foregroundColor = .secondary

        let content: AttributedString
        if let attributed = try? AttributedString(markdown: text) {
            content = attributed
        } else {
            content = AttributedString(text)
        }
        return Text(marker + content)
    }
}
