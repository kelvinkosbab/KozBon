//
//  AIBackend+Style.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourAICore
import BonjourAIAnthropic
import BonjourAIGemini
import BonjourCore

// MARK: - AIBackend + Style

/// Design-system extensions on ``AIBackend`` so the chat / Insights
/// surfaces can swap their accent color and icon depending on which
/// backend the user has selected — telegraphing the active provider
/// at a glance before they read a response.
///
/// Lives in `BonjourUI` (not `BonjourAICore`) because the styling
/// belongs to the design system, not the AI module. The AI module
/// shouldn't have to know about `Color` or `Image` types; the UI
/// module is the natural home for "what does this backend look
/// like in our app's visual language."
public extension AIBackend {

    /// The accent color the chat / Insights surfaces use when this
    /// backend is active.
    ///
    /// - `.appleIntelligence` → ``Color/kozBonBlue`` — the existing
    ///   global tint, so users on the on-device default see no
    ///   visual change from the previous on-device-only era.
    /// - `.anthropic` → ``Color/kozBonAnthropic`` — Anthropic's
    ///   "Cara" brand orange, lightened slightly in dark mode for
    ///   contrast.
    /// - `.gemini` → ``Color/kozBonGemini`` — Google's published
    ///   blues (#1A73E8 / #8AB4F8).
    var accentColor: Color {
        switch self {
        case .appleIntelligence:
            return .kozBonBlue
        case .anthropic:
            return .kozBonAnthropic
        case .gemini:
            return .kozBonGemini
        }
    }

    /// The chat-tab / Insights icon for this backend.
    ///
    /// - `.appleIntelligence` → the Apple Intelligence glyph.
    /// - `.anthropic` → the bundled Claude vector mark.
    /// - `.gemini` → the bundled Gemini spark vector mark.
    var icon: Image {
        switch self {
        case .appleIntelligence:
            return .appleIntelligence
        case .anthropic:
            return .anthropicClaude
        case .gemini:
            return .googleGemini
        }
    }

    /// The raw SF Symbol string for ``icon``. Useful when an API
    /// requires the symbol name directly (`Label(_, systemImage:)`,
    /// for instance) rather than an `Image`.
    var iconSystemName: String {
        switch self {
        case .appleIntelligence:
            return Iconography.appleIntelligence
        case .anthropic:
            return Iconography.anthropicClaude
        case .gemini:
            return Iconography.googleGemini
        }
    }
}

// MARK: - AICloudProvider + Style

/// Cloud-provider styling mirroring ``AIBackend``'s. The two
/// types overlap for the cloud cases — `AIBackend.cloudProvider`
/// is exactly this enum — but `AICloudProvider` is what the
/// sign-in sheet, credentials store, and routing-factory code
/// hold directly, so it gets its own accent accessor rather
/// than forcing every call site to round-trip through
/// `AIBackend`.
public extension AICloudProvider {

    /// The brand-color tint surfaces (sign-in sheet, error
    /// banners that mention a specific provider) use when
    /// rendering provider-scoped UI. Resolves to the same colors
    /// as ``AIBackend/accentColor`` for the matching cases.
    ///
    /// `.github` has no ``AIBackend`` counterpart — the case
    /// survives only so Settings can offer to delete the
    /// Keychain token GitHub Models left behind — and keeps
    /// ``Color/kozBonGitHub``, Microsoft's "Copilot purple"
    /// (#8534F3 / #9444FF in dark mode).
    var accentColor: Color {
        switch self {
        case .anthropic:
            return .kozBonAnthropic
        case .gemini:
            return .kozBonGemini
        case .github:
            return .kozBonGitHub
        }
    }
}
