//
//  InsightsButtonSection.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourAI
import BonjourAIAnthropic
import BonjourAIGemini
import BonjourAIOpenAI
import BonjourAIApple
import BonjourAICore
import BonjourCore
import BonjourLocalization
import BonjourStorage

#if canImport(UIKit)
import UIKit
#endif

// MARK: - InsightsButtonSection

/// A visible, tappable Insights row for detail screens.
///
/// The long-press ``InsightsContextMenuItems`` is easy to miss, so
/// the discovered-service and library detail screens also offer
/// Insights as a full-width list row. It resolves the same states
/// as the context menu: an Insights button tinted for the selected
/// backend, an "Enable Apple Intelligence" or "Sign in to …" call
/// to action, or nothing at all when AI is off or the device can't
/// run the selected backend.
struct InsightsButtonSection: View {

    @Environment(\.preferencesStore) private var preferencesStore
    @Environment(\.aiCloudCredentialsStore) private var credentialsStore
    @Environment(\.hapticFeedback) private var hapticFeedback
    @Environment(\.openURL) private var openURL

    private let action: () -> Void

    /// Creates the Insights row.
    ///
    /// - Parameter action: Presents the Insights sheet. Called after
    ///   a `.medium` haptic has already fired.
    init(action: @escaping () -> Void) {
        self.action = action
    }

    var body: some View {
        switch state {
        case .explain(let backend):
            Section {
                row(
                    title: Strings.Insights.explainWithAI,
                    icon: backend.icon,
                    tint: backend.accentColor
                ) {
                    hapticFeedback.play(.medium)
                    action()
                }
                .accessibilityIdentifier("insights_button")
            }

        case .enableAppleIntelligence:
            Section {
                row(
                    title: Strings.Insights.enableAppleIntelligence,
                    icon: AIBackend.appleIntelligence.icon,
                    tint: AIBackend.appleIntelligence.accentColor
                ) {
                    hapticFeedback.play(.light)
                    openAppleIntelligenceSettings()
                }
            }

        case .signIn(let backend, let provider):
            Section {
                row(
                    title: Self.signInTitle(for: provider),
                    icon: backend.icon,
                    tint: backend.accentColor
                ) {
                    hapticFeedback.play(.light)
                    NotificationCenter.default.post(
                        name: .aiCloudSignInRequested,
                        object: nil,
                        userInfo: [aiCloudSignInRequestedProviderKey: provider.rawValue]
                    )
                }
            }

        case .hidden:
            EmptyView()
        }
    }

    // MARK: - Row

    private func row(
        title: LocalizedStringResource,
        icon: Image,
        tint: Color,
        perform: @escaping () -> Void
    ) -> some View {
        Button(action: perform) {
            HStack {
                Spacer()
                Label {
                    Text(title)
                } icon: {
                    icon
                }
                .font(.headline)
                .padding(.vertical)
                Spacer()
            }
        }
        .foregroundStyle(tint)
        .listRowBackground(tint.opacity(0.2))
    }

    // MARK: - State

    private var state: InsightsButtonState {
        let backend = preferencesStore.aiBackend
        return InsightsButtonState.resolve(
            aiAnalysisEnabled: preferencesStore.aiAnalysisEnabled,
            backend: backend,
            appleIntelligenceAvailability: AppleIntelligenceSupport.availability,
            hasAPIKey: backend.cloudProvider.map { credentialsStore.hasAPIKey(for: $0) } ?? false,
            canOpenAppleIntelligenceSettings: Self.canOpenAppleIntelligenceSettings
        )
    }

    private static func signInTitle(for provider: AICloudProvider) -> LocalizedStringResource {
        switch provider {
        case .gemini:
            return Strings.Insights.signInToGemini
        case .openai:
            return Strings.Insights.signInToOpenAI
        case .anthropic, .github:
            return Strings.Insights.signInToClaude
        }
    }

    // MARK: - Apple Intelligence Settings

    /// visionOS has no public Apple Intelligence settings deep link,
    /// so the CTA would dead-end there. Matches `AIContextMenuItems`.
    private static var canOpenAppleIntelligenceSettings: Bool {
        #if os(visionOS)
        false
        #else
        true
        #endif
    }

    private func openAppleIntelligenceSettings() {
        #if os(iOS)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
        #elseif os(macOS)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.appleintelligencea") {
            openURL(url)
        }
        #endif
    }
}

// MARK: - InsightsButtonState

/// What ``InsightsButtonSection`` shows for a given backend setup.
enum InsightsButtonState: Equatable {
    /// Insights is ready on this backend.
    case explain(AIBackend)
    /// Apple Intelligence is supported but off or still downloading.
    case enableAppleIntelligence
    /// A cloud backend is selected but has no API key yet.
    case signIn(AIBackend, AICloudProvider)
    /// AI is off, or the device can't run the selected backend.
    case hidden

    static func resolve(
        aiAnalysisEnabled: Bool,
        backend: AIBackend,
        appleIntelligenceAvailability: AppleIntelligenceSupport.AvailabilityState,
        hasAPIKey: Bool,
        canOpenAppleIntelligenceSettings: Bool
    ) -> InsightsButtonState {
        guard aiAnalysisEnabled else { return .hidden }

        guard let provider = backend.cloudProvider else {
            switch appleIntelligenceAvailability {
            case .available:
                return .explain(backend)
            case .deviceNotEligible:
                return .hidden
            case .appleIntelligenceDisabled, .modelNotReady, .otherUnavailable:
                return canOpenAppleIntelligenceSettings ? .enableAppleIntelligence : .hidden
            }
        }

        return hasAPIKey ? .explain(backend) : .signIn(backend, provider)
    }
}
