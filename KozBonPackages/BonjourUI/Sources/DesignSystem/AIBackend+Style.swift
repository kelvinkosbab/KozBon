//
//  AIBackend+Style.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourAICore
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
    var accentColor: Color {
        switch self {
        case .appleIntelligence:
            return .kozBonBlue
        case .anthropic:
            return .kozBonAnthropic
        }
    }

    /// The chat-tab / Insights icon for this backend.
    ///
    /// - `.appleIntelligence` → the Apple Intelligence glyph.
    /// - `.anthropic` → an SF Symbol stand-in (`sparkle`) chosen
    ///   to evoke Anthropic's Cara brand mark without shipping a
    ///   custom asset that carries trademark constraints.
    var icon: Image {
        switch self {
        case .appleIntelligence:
            return .appleIntelligence
        case .anthropic:
            return .anthropicClaude
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
        }
    }
}
