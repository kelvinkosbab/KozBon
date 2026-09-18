//
//  Image+GeminiBrand.swift
//  BonjourAIGemini
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - Image + Gemini Brand

/// Google Gemini brand-mark accessor.
///
/// Mirrors `Image.anthropicClaude` in `BonjourAIAnthropic` — the
/// SVG asset and its `Image` accessor share a module so the asset
/// resolves through the SwiftPM-generated `Bundle.module` that's
/// internal to this target.
public extension Image {

    /// Google's official Gemini spark
    /// (`Media.xcassets/Gemini.imageset/gemini.svg`, normalized
    /// from the 16pt source to a 24pt viewBox so its intrinsic
    /// size matches the Claude mark), template-rendered so it
    /// picks up the surrounding tint — `Color.kozBonGemini`
    /// wherever the Gemini backend is active, and the standard
    /// tab-bar gray when the chat tab is unselected.
    ///
    /// Template rendering flattens the source radial gradient
    /// (#9168C0 → #5684D1 → #1BA1E3) to a single tint. That's
    /// deliberate: an icon with a baked-in gradient can't go gray
    /// when its tab deselects, which is the same reason the
    /// Claude and Octocat marks are template-rendered.
    ///
    /// For call sites that need a `systemImage:`-compatible name
    /// (e.g. `Label(_:systemImage:)`), use
    /// `Iconography.googleGemini` — that string-based fallback
    /// resolves to the `asterisk` SF Symbol.
    static var googleGemini: Image {
        Image("Gemini", bundle: .module)
    }
}
