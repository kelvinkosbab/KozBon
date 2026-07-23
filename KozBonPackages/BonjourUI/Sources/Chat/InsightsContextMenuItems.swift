//
//  InsightsContextMenuItems.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourAI
import BonjourAIAnthropic
import BonjourAIApple
import BonjourAICore
import BonjourAIGitHub
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

            case .github:
                githubMenu
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
                // View-builder `Label` form so the Claude asset
                // mark renders instead of an SF Symbol.
                Label {
                    Text(Strings.Insights.explainWithAI)
                } icon: {
                    Image.anthropicClaude
                }
            }
        } else {
            cloudSignInItem(
                provider: .anthropic,
                label: Strings.Insights.signInToClaude,
                icon: Image.anthropicClaude
            )
        }
    }

    // MARK: - GitHub Models

    @ViewBuilder
    private var githubMenu: some View {
        if credentialsStore.hasAPIKey(for: .github) {
            Divider()
            Button {
                hapticFeedback.play(.medium)
                action()
            } label: {
                Label {
                    Text(Strings.Insights.explainWithGitHub)
                } icon: {
                    Image.github
                }
            }
        } else {
            cloudSignInItem(
                provider: .github,
                label: Strings.Insights.signInToGitHub,
                icon: Image.github
            )
        }
    }

    // MARK: - Cloud Sign-In CTA

    /// Sign-in CTA surfaced in the cloud branches when the
    /// selected backend doesn't have credentials yet. Posts
    /// ``Notification.Name/aiCloudSignInRequested`` with the
    /// provider; ``AppCoreScene`` observes it at the scene root
    /// and mounts the matching `AICloudSignInSheet`. Mirrors the
    /// Apple-Intelligence path's "Enable Apple Intelligence"
    /// affordance so the long-press menu always surfaces a
    /// useful next step for the selected backend.
    @ViewBuilder
    private func cloudSignInItem(
        provider: AICloudProvider,
        label: LocalizedStringResource,
        icon: Image
    ) -> some View {
        Divider()
        Button {
            hapticFeedback.play(.light)
            NotificationCenter.default.post(
                name: .aiCloudSignInRequested,
                object: nil,
                userInfo: [aiCloudSignInRequestedProviderKey: provider.rawValue]
            )
        } label: {
            Label {
                Text(label)
            } icon: {
                icon
            }
        }
    }
}

// MARK: - InsightsAccessibilityAction

/// VoiceOver / Switch Control mirror for ``InsightsContextMenuItems``.
///
/// Context menus aren't reachable from the VoiceOver rotor or
/// Switch Control scanning, so every row that offers Insights via
/// long-press must also expose it as an accessibility action.
/// Drop this inside the row's `.accessibilityActions { }` block:
///
/// ```swift
/// .accessibilityActions {
///     InsightsAccessibilityAction(action: { serviceToExplain = service })
/// }
/// ```
///
/// Gated on `aiAnalysisEnabled` to match the context-menu items —
/// when AI is off, no phantom action appears in the rotor.
public struct InsightsAccessibilityAction: View {

    @Environment(\.preferencesStore) private var preferencesStore

    private let action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        if preferencesStore.aiAnalysisEnabled {
            Button(String(localized: Strings.Insights.explainWithAI), action: action)
        }
    }
}
