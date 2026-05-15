//
//  Image+GitHubBrand.swift
//  BonjourAIGitHub
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - Image + GitHub Brand

/// GitHub brand-mark accessor.
///
/// Mirrors `Image.anthropicClaude` in `BonjourAIAnthropic` —
/// the Octocat asset and its `Image` accessor share a module
/// so the asset bundle resolves through the SwiftPM-generated
/// `Bundle.module` that's internal to this target.
public extension Image {

    /// GitHub's official Octocat
    /// (`Media.xcassets/GitHub.imageset/github.svg`, sourced
    /// from `mark-github-24.svg` in GitHub's brand resources),
    /// template-rendered so it picks up the surrounding tint —
    /// `Color.kozBonGitHub` (Copilot purple) on the chat
    /// surface and tab-bar gray when the chat tab is unselected.
    ///
    /// For `systemImage:`-compatible call sites, use
    /// `Iconography.github` — the string-based fallback
    /// resolves to the `chevron.left.forwardslash.chevron.right`
    /// SF Symbol.
    static var github: Image {
        Image("GitHub", bundle: .module)
    }
}
