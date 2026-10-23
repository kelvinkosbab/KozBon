//
//  ChatScrollToBottomButton.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourAI
import BonjourCore
import BonjourLocalization

// MARK: - ChatScrollToBottomButton

/// Round glass button that jumps the Chat transcript to its newest
/// content. Shown only while the transcript is scrolled up.
struct ChatScrollToBottomButton: View {

    /// How far the button's center sits from the trailing edge of
    /// the container it's aligned to, so it can line up over another
    /// control whatever its own scaled size.
    var centerTrailingInset: CGFloat = 0

    /// Lifts the button this far clear of the top edge of the
    /// container it's top-aligned to, so it floats above it.
    var gapAboveTopEdge: CGFloat = 0

    let action: () -> Void

    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    /// Grows with Dynamic Type from the 44 pt minimum hit target.
    @ScaledMetric(relativeTo: .body) private var diameter: CGFloat = .size44

    var body: some View {
        Button(action: action) {
            Image.arrowDown
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
                .accessibilityHidden(true)
                .frame(width: diameter, height: diameter)
                .platformGlassBackground(in: Circle())
                // Glass alone is too faint an edge under Increase
                // Contrast, so the circle gets an outline there.
                .overlay {
                    if colorSchemeContrast == .increased {
                        Circle().strokeBorder(.primary, lineWidth: 1)
                    }
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Strings.Accessibility.chatScrollToBottom)
        .accessibilityHint(Strings.Accessibility.chatScrollToBottomHint)
        .accessibilityIdentifier("chat_scroll_to_bottom_button")
        // Past this size the circle would crowd the compose bar;
        // the Large Content Viewer covers anything larger.
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .accessibilityShowsLargeContentViewer()
        #if !os(macOS)
        .hoverEffect(.highlight)
        #endif
        // Padding and an offset rather than alignment guides, which
        // the compose bar's overlay didn't honor on device.
        .padding(.trailing, max(0, centerTrailingInset - diameter / 2))
        .offset(y: -(diameter + gapAboveTopEdge))
    }
}

#Preview {
    ChatScrollToBottomButton {}
        .padding()
}
