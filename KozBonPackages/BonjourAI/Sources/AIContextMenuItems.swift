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

    private let aiAnalysisEnabled: Bool
    private let action: () -> Void

    /// Creates AI context menu items.
    ///
    /// - Parameters:
    ///   - aiAnalysisEnabled: Whether the user has enabled AI analysis in Preferences.
    ///   - action: The action to perform when "Explain with AI" is tapped.
    public init(aiAnalysisEnabled: Bool, action: @escaping () -> Void) {
        self.aiAnalysisEnabled = aiAnalysisEnabled
        self.action = action
    }

    public var body: some View {
        if aiAnalysisEnabled {
            switch SystemLanguageModel.default.availability {
            case .available:
                Divider()
                Button {
                    action()
                } label: {
                    Label(
                        String(localized: Strings.AIInsights.explainWithAI),
                        systemImage: Iconography.appleIntelligence
                    )
                }

            case .unavailable(let reason):
                if reason != .deviceNotEligible {
                    Divider()
                    Button {
                        openAppleIntelligenceSettings()
                    } label: {
                        Label(
                            String(localized: Strings.AIInsights.enableAppleIntelligence),
                            systemImage: Iconography.appleIntelligence
                        )
                    }
                }

            @unknown default:
                EmptyView()
            }
        }
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
