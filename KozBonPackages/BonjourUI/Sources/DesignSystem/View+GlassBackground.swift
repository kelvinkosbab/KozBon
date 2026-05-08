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
// visionOS does NOT expose iOS-26's `.glassEffect` modifier, but it has
// its own native equivalent: `.glassBackgroundEffect()`. That API ships
// the depth-aware surface treatment that's expected of any element on
// the Vision Pro canvas, and it's what our `ServiceTypeBadge` already
// uses. So on visionOS we route through `.glassBackgroundEffect()`
// rather than the dimmer `.ultraThinMaterial` fallback that this helper
// used to emit on Vision Pro — every glass surface in the app now feels
// native there.
//
// Keeping all branches in one extension avoids sprinkling
// `if #available` through every view that needs the treatment and makes
// it trivial to tune the fallback material app-wide.

public extension View {

    /// Applies the platform-native glass treatment inside the given
    /// shape. Use for ambient surfaces (text fields, pill buttons,
    /// capsule badges) that should feel translucent against scrolling
    /// content.
    ///
    /// Per-platform:
    /// - **visionOS**: `.glassBackgroundEffect()` — the native
    ///   depth-aware Vision Pro surface, clipped to `shape`.
    /// - **iOS 26+ / macOS 26+**: Liquid Glass via `.glassEffect`.
    /// - **Pre-26 iOS / macOS / older platforms**: `.ultraThinMaterial`
    ///   inside `shape`.
    ///
    /// - Parameter shape: The shape the background is clipped to. Defaults
    ///   to `Capsule()` since most chat-surface controls (text fields,
    ///   send buttons) are pill-shaped.
    @ViewBuilder
    func glassOrMaterialBackground<S: InsettableShape>(in shape: S) -> some View {
        #if os(visionOS)
        self.glassBackgroundEffect()
            .clipShape(shape)
        #else
        if #available(iOS 26, macOS 26, *) {
            self.glassEffect(in: shape)
        } else {
            self.background(.ultraThinMaterial, in: shape)
        }
        #endif
    }

    /// Tinted variant of ``glassOrMaterialBackground(in:)`` for primary
    /// action controls (e.g. the chat send button).
    ///
    /// Per-platform:
    /// - **visionOS**: a solid tint fill — visionOS's
    ///   `.glassBackgroundEffect` doesn't accept a tint, so for the
    ///   handful of "this is the primary action" surfaces we render a
    ///   solid colored capsule that reads unambiguously as the CTA.
    /// - **iOS 26+ / macOS 26+**: tinted Liquid Glass.
    /// - **Pre-26 iOS / macOS / older platforms**: solid tint fill.
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
    /// systems; does nothing on iOS 26+ / macOS 26+ / visionOS.
    ///
    /// Use this on outer bar containers (e.g. the chat compose bar
    /// wrapper) where the container previously provided a frosted
    /// surface for visual separation from scrolling content. On iOS 26+
    /// and visionOS the individual controls inside the bar (text field,
    /// send button) already carry their platform's native glass via
    /// ``glassOrMaterialBackground(in:)`` and
    /// ``glassOrTintedBackground(tint:in:)`` — adding another material
    /// under them produces a glass-on-glass look that reads as dull
    /// frosted material instead of translucent glass. Skipping the
    /// outer material on those platforms lets the inner glass float
    /// directly over scroll content, which is the intended look.
    ///
    /// On older OS versions, the `.bar` material is retained so the
    /// compose surface still reads as a distinct region.
    @ViewBuilder
    func composeBarBackgroundForLegacySystems() -> some View {
        #if os(visionOS)
        self
        #else
        if #available(iOS 26, macOS 26, *) {
            self
        } else {
            self.background(.bar)
        }
        #endif
    }
}
