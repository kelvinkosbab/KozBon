//
//  InsightsLink.swift
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

// MARK: - InsightsLink

/// A plain Insights link row for detail screens.
///
/// The long-press ``InsightsContextMenuItems`` is easy to miss, so
/// the discovered-service and library detail screens also show
/// Insights as a link in its own section with no card behind it. It resolves the same
/// states as the context menu: an Insights link tinted for the
/// selected backend, an "Enable Apple Intelligence" or "Sign in to …"
/// call to action, or nothing at all when AI is off or the device
/// can't run the selected backend.
struct InsightsLink: View {

    @Environment(\.preferencesStore) private var preferencesStore
    @Environment(\.aiCloudCredentialsStore) private var credentialsStore
    @Environment(\.hapticFeedback) private var hapticFeedback
    @Environment(\.openURL) private var openURL

    private let action: () -> Void

    /// Creates the Insights link.
    ///
    /// - Parameter action: Presents the Insights sheet. Called after
    ///   a `.medium` haptic has already fired.
    init(action: @escaping () -> Void) {
        self.action = action
    }

    var body: some View {
        // The section lives here, not at the call site, so a hidden
        // link leaves no empty section (and its spacing) behind.
        if state != .hidden {
            Section { content }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .explain(let backend):
            link(
                title: Strings.Insights.explainWithAI,
                icon: backend.icon,
                tint: backend.accentColor
            ) {
                hapticFeedback.play(.medium)
                action()
            }
            .accessibilityIdentifier("insights_link")

        case .enableAppleIntelligence:
            link(
                title: Strings.Insights.enableAppleIntelligence,
                icon: AIBackend.appleIntelligence.icon,
                tint: AIBackend.appleIntelligence.accentColor
            ) {
                hapticFeedback.play(.light)
                openAppleIntelligenceSettings()
            }

        case .signIn(let backend, let provider):
            link(
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

        case .hidden:
            EmptyView()
        }
    }

    // MARK: - Link

    private func link(
        title: LocalizedStringResource,
        icon: Image,
        tint: Color,
        perform: @escaping () -> Void
    ) -> some View {
        Button(action: perform) {
            Label {
                Text(title)
            } icon: {
                icon
            }
            .font(.subheadline.weight(.semibold))
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        // Borderless so only the link is tappable, not the whole
        // row the List would otherwise turn into a button.
        .buttonStyle(.borderless)
        .foregroundStyle(tint)
        .listRowBackground(Color.clear)
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

/// What ``InsightsLink`` shows for a given backend setup.
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
