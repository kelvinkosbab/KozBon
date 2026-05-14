//
//  InsightsContextMenuItems.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourAI
import BonjourAICloud
import BonjourCore
import BonjourLocalization
import BonjourStorage

// MARK: - InsightsContextMenuItems

/// Backend-aware Insights context-menu items.
///
/// Wraps the legacy `AIContextMenuItems` (Apple Foundation Models,
/// iOS 26+ only) and a non-version-gated fallback that surfaces
/// "Explain with Claude" when the user has the Anthropic backend
/// selected and a key configured. ADR 0005 broadened the Insights
/// surface from "Apple Intelligence only" to "whichever backend
/// the user has selected and configured" — this view is the entry
/// point every long-press call site now uses, so the cloud path
/// works on iOS 18+ devices that can't reach Apple Foundation
/// Models at all.
///
/// Routing:
///
/// - `aiBackend == .appleIntelligence` and iOS 26+ available →
///   defer to `AIContextMenuItems`. Same availability cascade as
///   before (`.available` shows "Explain with AI",
///   `.appleIntelligenceDisabled` / `.modelNotReady` shows the
///   "Enable Apple Intelligence" CTA, `.deviceNotEligible` hides
///   the row).
/// - `aiBackend == .anthropic` with a key configured → show
///   "Explain with Claude" rendered with the Anthropic glyph and
///   accent color.
/// - Anything else → render nothing.
public struct InsightsContextMenuItems: View {

    @Environment(\.preferencesStore) private var preferencesStore
    @Environment(\.aiCloudCredentialsStore) private var credentialsStore
    @Environment(\.hapticFeedback) private var hapticFeedback

    private let action: () -> Void

    /// Creates Insights context-menu items.
    ///
    /// - Parameter action: The action to perform when the user
    ///   taps the Insights affordance. Called after a `.medium`
    ///   haptic has already fired, so the caller doesn't need to
    ///   add one. Matches `AIContextMenuItems`'s contract.
    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        if preferencesStore.aiAnalysisEnabled {
            switch preferencesStore.aiBackend {
            case .appleIntelligence:
                appleIntelligenceMenu

            case .anthropic:
                anthropicMenu
            }
        }
    }

    // MARK: - Apple Intelligence

    @ViewBuilder
    private var appleIntelligenceMenu: some View {
        #if canImport(FoundationModels)
        if #available(iOS 26, macOS 26, visionOS 26, *) {
            AIContextMenuItems(
                aiAnalysisEnabled: preferencesStore.aiAnalysisEnabled,
                action: action
            )
        }
        #endif
    }

    // MARK: - Anthropic Claude

    @ViewBuilder
    private var anthropicMenu: some View {
        if credentialsStore.hasAPIKey(for: .anthropic) {
            Divider()
            Button {
                hapticFeedback.play(.medium)
                action()
            } label: {
                // `Label(_:systemImage:)` only accepts SF Symbol
                // names, so previously the long-press menu showed
                // the `sparkle` fallback (`Iconography.anthropicClaude`)
                // instead of Anthropic's actual brand mark. The
                // view-builder form of `Label` accepts any Image,
                // so we route through `Image.anthropicClaude`
                // (resolved from the `Claude` asset, template-
                // rendered so it picks up the menu's tint).
                Label {
                    Text(Strings.Insights.explainWithAI)
                } icon: {
                    Image.anthropicClaude
                }
            }
        }
    }
}
