//
//  ContentMarginsBasedOnSizeClass.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - ContentMarginsBasedOnSize

private struct ContentMarginsBasedOnSizeClass: ViewModifier {

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    func body(content: Content) -> some View {
        // One view tree for both size classes: an if/else here would
        // rebuild the list (losing scroll position and row state)
        // whenever an iPad window resizes or a Duo folds. A nil
        // length keeps the system's default margins in compact.
        GeometryReader { geometry in
            content
                .contentMargins(
                    .horizontal,
                    horizontalSizeClass == .regular ? margin(for: geometry.size.width) : nil,
                    for: .scrollContent
                )
        }
    }

    /// Picks the horizontal content margin for the current
    /// container width.
    ///
    /// Measures the *container*, not the display — a list inside a
    /// split-view sidebar reports the sidebar's width.
    ///
    /// - Sidebar widths (≤ 600pt) get a small 8pt inset so the
    ///   selection capsule and row chevrons have breathing room
    ///   against the leading / trailing column edges. The
    ///   previous 0pt let the capsule paint edge-to-edge on
    ///   macOS / iPadOS / visionOS sidebars, which read as
    ///   cramped.
    /// - Narrow regular widths (600–800pt) get 48pt. The 150pt
    ///   tier is tuned for full-size iPad and leaves only 369pt of
    ///   content on the Duo's 669pt inner display.
    /// - Wider containers (single-column detail views without an
    ///   explicit max-width frame) keep the larger 150 / 200pt
    ///   margins that lend a form-like feel.
    private func margin(for width: CGFloat) -> CGFloat {
        if width > 1000 {
            return 200
        }
        if width > 800 {
            return 150
        }
        if width > 600 {
            return 48
        }
        return 8
    }
}

// MARK: - View Extensions

public extension View {
    func contentMarginsBasedOnSizeClass() -> some View {
        modifier(ContentMarginsBasedOnSizeClass())
    }
}
