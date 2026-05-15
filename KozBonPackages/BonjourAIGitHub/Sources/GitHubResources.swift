//
//  GitHubResources.swift
//  BonjourAIGitHub
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - GitHubResources

/// Public handle to this module's resource bundle.
///
/// Mirrors ``AnthropicResources`` for the GitHub-scoped assets
/// (currently `Media.xcassets/GitHub.imageset/` — the official
/// Octocat from GitHub's brand resources). Lets BonjourUI's
/// design-system code reach the bundle without rebundling.
public enum GitHubResources {

    /// The bundle shipping the GitHub brand mark. Resolves to
    /// the SwiftPM-generated `Bundle.module` for the
    /// `BonjourAIGitHub` target.
    public static let bundle: Bundle = .module
}
