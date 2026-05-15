//
//  AICloudProvider.swift
//  BonjourAICore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourLocalization

// MARK: - AICloudProvider

/// The set of cloud-hosted AI providers KozBon can route requests to.
///
/// Defined as an enum (rather than a string preference) so each
/// provider gets compile-time enforcement everywhere it surfaces:
/// the credentials store, the model picker, the factory routing.
/// Adding a new provider (OpenAI, Gemini, etc.) is a single new
/// case here, plus the implementations of the matching session and
/// explainer types.
///
/// ADR 0005 documents why this layer exists — KozBon's default is
/// still on-device Apple Foundation Models, and the cloud surface
/// is strictly opt-in.
public enum AICloudProvider: String, Sendable, CaseIterable, Codable {

    /// Anthropic's Claude family. The user supplies their own API
    /// key from `console.anthropic.com`; KozBon never operates the
    /// key.
    case anthropic

    /// GitHub Models — OpenAI-compatible inference endpoint
    /// (`models.inference.ai.azure.com`) brokered by GitHub. The
    /// user supplies a GitHub Personal Access Token from
    /// `github.com/settings/tokens`; KozBon never operates the
    /// token.
    case github

    /// Localized user-facing name for this provider, suitable for
    /// confirmation dialogs and error messages that reference a
    /// specific cloud backend. Mirrors ``AIBackend/displayName``
    /// for the cloud cases.
    public var displayName: LocalizedStringResource {
        switch self {
        case .anthropic:
            return Strings.Settings.aiBackendAnthropic
        case .github:
            return Strings.Settings.aiBackendGitHub
        }
    }
}
