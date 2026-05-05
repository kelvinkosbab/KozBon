//
//  AIContextMenuItems.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourCore
import BonjourLocalization

#if canImport(FoundationModels)
import FoundationModels

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

// MARK: - AIContextMenuItems

/// Reusable context menu items for AI-powered service explanations.
///
/// Renders different content based on Apple Intelligence availability:
/// - **Available**: Shows "Explain with AI" button that triggers the provided action.
/// - **Not enabled / model not ready**: Shows "Enable Apple Intelligence" that opens Settings.
/// - **Device not eligible**: Shows nothing.
@available(iOS 26, macOS 26, visionOS 26, *)
public struct AIContextMenuItems: View {

    @Environment(\.hapticFeedback) private var hapticFeedback

    private let aiAnalysisEnabled: Bool
    private let action: () -> Void

    /// Creates AI context menu items.
    ///
    /// - Parameters:
    ///   - aiAnalysisEnabled: Whether the user has enabled AI analysis in Preferences.
    ///   - action: The action to perform when "Insights" is tapped. Called after
    ///     a `.medium` haptic has already fired, so the caller doesn't need to
    ///     add one.
    public init(aiAnalysisEnabled: Bool, action: @escaping () -> Void) {
        self.aiAnalysisEnabled = aiAnalysisEnabled
        self.action = action
    }

    public var body: some View {
        if aiAnalysisEnabled {
            #if targetEnvironment(simulator)
            // On the simulator, always show "Insights" so developers
            // can test the UI flow with mock lorem ipsum responses.
            Divider()
            Button {
                onInsightsTapped()
            } label: {
                Label(
                    String(localized: Strings.Insights.explainWithAI),
                    systemImage: Iconography.appleIntelligence
                )
            }
            #else
            switch SystemLanguageModel.default.availability {
            case .available:
                Divider()
                Button {
                    onInsightsTapped()
                } label: {
                    Label(
                        String(localized: Strings.Insights.explainWithAI),
                        systemImage: Iconography.appleIntelligence
                    )
                }

            case .unavailable(let reason):
                // visionOS doesn't expose a public Apple Intelligence
                // settings deep link, so an "Enable Apple Intelligence"
                // CTA there would dead-end — hide it. iOS and macOS both
                // route through the platform-specific URLs in
                // `openAppleIntelligenceSettings()`.
                #if !os(visionOS)
                if reason != .deviceNotEligible {
                    Divider()
                    Button {
                        hapticFeedback.play(.light)
                        openAppleIntelligenceSettings()
                    } label: {
                        Label(
                            String(localized: Strings.Insights.enableAppleIntelligence),
                            systemImage: Iconography.appleIntelligence
                        )
                    }
                }
                #endif

            @unknown default:
                EmptyView()
            }
            #endif
        }
    }

    /// Handles the "Insights" button tap: fires a medium haptic to confirm
    /// the action landed (context-menu taps don't get a default haptic the
    /// way buttons elsewhere in the UI do) and invokes the caller-provided
    /// action to present the Insights sheet. Centralizing this here means
    /// all six call sites get consistent tactile feedback without each
    /// view having to plumb `@Environment(\.hapticFeedback)` into its own
    /// closure — the user reported missing feedback on exactly this path.
    private func onInsightsTapped() {
        hapticFeedback.play(.medium)
        action()
    }

    // MARK: - Open Settings

    private func openAppleIntelligenceSettings() {
        #if os(iOS)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #elseif os(macOS)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.appleintelligencea") {
            NSWorkspace.shared.open(url)
        }
        #endif
    }
}

#endif
