//
//  Image+OpenAIBrand.swift
//  BonjourAIOpenAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - Image + OpenAI Brand

/// OpenAI brand-mark accessor.
///
/// Hosted in `BonjourAIOpenAI` so the SVG asset
/// (`Media.xcassets/OpenAI.imageset/openai.svg`), its `Image`
/// accessor, and the rest of the OpenAI code all live in one
/// module. `Bundle.module` is internal to the owning SwiftPM
/// target — keeping the accessor here means we resolve the asset
/// against the right bundle without exposing a separate public
/// bundle handle.
public extension Image {

    /// The official OpenAI mark, template-rendered so it picks up
    /// the surrounding tint.
    ///
    /// Template rendering matters more here than for the other
    /// providers: the mark is a single black path, so rendered as
    /// its original artwork it would stay black in dark mode and
    /// disappear into the chrome. Anthropic's orange and Gemini's
    /// gradient at least remain legible either way.
    ///
    /// For call sites that need a `systemImage:`-compatible name
    /// (e.g. `Label(_:systemImage:)`), use `Iconography.openAI` —
    /// that string-based fallback resolves to the `hexagon` SF
    /// Symbol.
    static var openAI: Image {
        Image("OpenAI", bundle: .module)
    }
}
