//
//  AnthropicResources.swift
//  BonjourAIAnthropic
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - AnthropicResources

/// Public handle to this module's resource bundle.
///
/// `Bundle.module` is the SwiftPM-generated bundle that holds
/// the brand assets shipped with `BonjourAIAnthropic`
/// (currently `Media.xcassets/Claude.imageset/` — the official
/// Anthropic mark). The static is `internal` to its module by
/// default; we re-export it here so design-system code in
/// `BonjourUI` can resolve `Image("Claude", bundle:
/// AnthropicResources.bundle)` without rebundling the asset.
public enum AnthropicResources {

    /// The bundle that ships the Anthropic brand mark and any
    /// future Anthropic-scoped asset (color sets, font files,
    /// etc.). Resolves to `Bundle.module` at compile time —
    /// the same `.module` SwiftPM generates for every target
    /// that opts into `resources:`.
    public static let bundle: Bundle = .module
}
