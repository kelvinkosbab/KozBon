//
//  View+GlassBackground.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - Glass Background with Material Fallback
//
// iOS 26 and macOS 26 introduced Liquid Glass via the `.glassEffect`
// modifier. On capable devices we want UI surfaces (chat text field, send
// button, etc.) to use it directly — no solid tinted background,
// translucent glass only. On older OS versions there is no Liquid Glass,
// so we fall back to a flat material fill that still reads as "frosted"
// against the content behind it.
//
// visionOS handles translucency through its own native surface system
// and does NOT expose `.glassEffect` even on OS 26 — calls there fail to
// compile. We gate it out via `#if os(visionOS)` and always use the
// material fallback on Vision Pro, which matches what the rest of the
// visionOS UI looks like anyway.
//
// Keeping both branches in one extension avoids sprinkling
// `if #available` through every view that needs the treatment and makes
// it trivial to tune the fallback material app-wide.

public extension View {

    /// Applies Liquid Glass on iOS 26+ / macOS 26+, falling back to
    /// `.ultraThinMaterial` inside the given shape on older systems and
    /// on visionOS. Use for ambient surfaces (text fields, pill buttons,
    /// capsule badges) that should feel translucent against scrolling
    /// content.
    ///
    /// - Parameter shape: The shape the background is clipped to. Defaults
    ///   to `Capsule()` since most chat-surface controls (text fields,
    ///   send buttons) are pill-shaped.
    @ViewBuilder
    func glassOrMaterialBackground<S: InsettableShape>(in shape: S) -> some View {
        #if os(visionOS)
        self.background(.ultraThinMaterial, in: shape)
        #else
        if #available(iOS 26, macOS 26, *) {
            self.glassEffect(in: shape)
        } else {
            self.background(.ultraThinMaterial, in: shape)
        }
        #endif
    }

    /// Tinted variant of ``glassOrMaterialBackground(in:)`` for primary
    /// action controls (e.g. the chat send button). On iOS 26+ / macOS 26+
    /// uses a tinted Liquid Glass; on older systems and on visionOS falls
    /// back to a solid tint fill so the action still reads as the primary
    /// affordance.
    ///
    /// - Parameters:
    ///   - tint: The branded color applied to the glass tint on iOS 26+
    ///     and to the solid fill on older systems.
    ///   - shape: The shape the background is clipped to.
    @ViewBuilder
    func glassOrTintedBackground<S: InsettableShape>(
        tint: Color,
        in shape: S
    ) -> some View {
        #if os(visionOS)
        self.background(tint, in: shape)
        #else
        if #available(iOS 26, macOS 26, *) {
            self.glassEffect(.regular.tint(tint).interactive(), in: shape)
        } else {
            self.background(tint, in: shape)
        }
        #endif
    }

    /// Applies a `.bar`-style material background on pre-Liquid-Glass
    /// systems; does nothing on iOS 26+ / macOS 26+.
    ///
    /// Use this on outer bar containers (e.g. the chat compose bar
    /// wrapper) where the container previously provided a frosted
    /// surface for visual separation from scrolling content. On iOS 26+
    /// the individual controls inside the bar (text field, send button)
    /// already carry Liquid Glass via ``glassOrMaterialBackground(in:)``
    /// and ``glassOrTintedBackground(tint:in:)`` — adding another
    /// material under them produces a glass-on-glass look that reads as
    /// dull frosted material instead of translucent glass. Skipping the
    /// outer material on iOS 26+ lets the inner glass float directly
    /// over scroll content, which is the intended Liquid Glass look.
    ///
    /// On visionOS (where Liquid Glass is unavailable) and on older OS
    /// versions, the `.bar` material is retained so the compose surface
    /// still reads as a distinct region.
    @ViewBuilder
    func composeBarBackgroundForLegacySystems() -> some View {
        #if os(visionOS)
        self.background(.bar)
        #else
        if #available(iOS 26, macOS 26, *) {
            self
        } else {
            self.background(.bar)
        }
        #endif
    }
}
