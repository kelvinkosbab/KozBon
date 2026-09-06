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
public enum AICloudProvider: String, Sendable, CaseIterable, Codable, Identifiable {

    /// Stable identity for SwiftUI's `.sheet(item:)` and friends.
    /// The raw value doubles as the identifier since each case
    /// is unique and stable across launches.
    public var id: String { rawValue }

    /// Anthropic's Claude family. The user supplies their own API
    /// key from `console.anthropic.com`; KozBon never operates the
    /// key.
    case anthropic

    /// Google's Gemini family, via the Gemini Developer API
    /// (`generativelanguage.googleapis.com`). The user supplies
    /// their own API key from Google AI Studio; KozBon never
    /// operates the key.
    ///
    /// Deliberately the Developer API rather than Vertex AI —
    /// Vertex authenticates with service-account OAuth, which the
    /// paste-an-API-key flow in Settings can't express.
    case gemini

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
        case .gemini:
            return Strings.Settings.aiBackendGemini
        case .github:
            return Strings.Settings.aiBackendGitHub
        }
    }

    /// The model identifier to fall back on when nothing usable is
    /// stored for this provider.
    ///
    /// Lives here rather than on each provider's model enum so the
    /// provider-agnostic preferences bridge can resolve a default
    /// without importing every provider module. Each provider's
    /// own `Model.default` must agree with this — enforced by a
    /// test in that provider's module.
    public var defaultModelIdentifier: String {
        switch self {
        case .anthropic:
            return "claude-sonnet-4-5"
        case .gemini:
            return "gemini-2.5-flash"
        case .github:
            // Retired 2026-07-30; the case survives only so
            // Settings can delete the stranded token.
            return ""
        }
    }
}
