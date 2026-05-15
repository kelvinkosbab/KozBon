//
//  Image+AnthropicBrand.swift
//  BonjourAIAnthropic
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - Image + Anthropic Brand

/// Anthropic brand-mark accessor.
///
/// Hosted in `BonjourAIAnthropic` so the SVG asset
/// (`Media.xcassets/Claude.imageset/claude.svg`), its `Image`
/// accessor, and the rest of the Anthropic code all live in
/// one module. `Bundle.module` is internal to the owning
/// SwiftPM target — keeping the accessor here means we resolve
/// the asset against the right bundle without exposing a
/// separate public bundle handle.
public extension Image {

    /// The official Anthropic mark, template-rendered so it
    /// picks up the surrounding tint — in practice
    /// `Color.kozBonAnthropic` (Cara orange) wherever this icon
    /// surfaces, or the standard tab-bar gray when the chat
    /// tab is unselected.
    ///
    /// For call sites that need a `systemImage:`-compatible
    /// name (e.g. `Label(_:systemImage:)`), use
    /// `Iconography.anthropicClaude` — that string-based
    /// fallback resolves to the `sparkle` SF Symbol.
    static var anthropicClaude: Image {
        Image("Claude", bundle: .module)
    }
}
