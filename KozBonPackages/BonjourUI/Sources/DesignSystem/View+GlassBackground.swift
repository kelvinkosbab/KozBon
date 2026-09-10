//
//  View+GlassBackground.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - Platform-Native Glass Background
//
// iOS and macOS expose Liquid Glass via the `.glassEffect` modifier.
// visionOS does NOT expose that modifier, but has its own native
// equivalent: `.glassBackgroundEffect()`, the depth-aware surface
// treatment expected of any element on the Vision Pro canvas.
//
// These helpers exist purely to route between those two spellings, so
// views can ask for "the platform's glass" without each one carrying an
// `#if os(visionOS)`.

public extension View {

    /// Applies the platform-native glass treatment inside the given
    /// shape. Use for ambient surfaces (text fields, pill buttons,
    /// capsule badges) that should feel translucent against scrolling
    /// content.
    ///
    /// - **visionOS**: `.glassBackgroundEffect()`, clipped to `shape`.
    /// - **iOS / macOS**: Liquid Glass via `.glassEffect`.
    ///
    /// - Parameter shape: The shape the background is clipped to. Defaults
    ///   to `Capsule()` since most chat-surface controls (text fields,
    ///   send buttons) are pill-shaped.
    @ViewBuilder
    func platformGlassBackground<S: InsettableShape>(in shape: S) -> some View {
        #if os(visionOS)
        self.glassBackgroundEffect()
            .clipShape(shape)
        #else
        self.glassEffect(in: shape)
        #endif
    }

    /// Tinted variant for primary action controls (e.g. the chat
    /// send button).
    ///
    /// - **visionOS**: a solid tint fill — visionOS's
    ///   `.glassBackgroundEffect` doesn't accept a tint, so for the
    ///   handful of "this is the primary action" surfaces we render a
    ///   solid colored capsule that reads unambiguously as the CTA.
    /// - **iOS / macOS**: tinted Liquid Glass.
    ///
    /// - Parameters:
    ///   - tint: The branded color applied to the glass tint.
    ///   - shape: The shape the background is clipped to.
    @ViewBuilder
    func platformGlassBackground<S: InsettableShape>(
        tint: Color,
        in shape: S
    ) -> some View {
        #if os(visionOS)
        self.background(tint, in: shape)
        #else
        self.glassEffect(.regular.tint(tint).interactive(), in: shape)
        #endif
    }
}
