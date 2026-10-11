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

/// A compact Liquid Glass Insights capsule for detail screens.
///
/// The long-press ``InsightsContextMenuItems`` is easy to miss, so
/// the discovered-service and library detail screens also show
/// Insights as a small centred capsule just below their header. The glass
/// separates it from the ambient wash, and the label takes the
/// selected assistant's chat colours (``AmbientMeshPalette/chat(_:)``)
/// so it reads as that assistant's entry point.
///
/// It resolves the same states as the context menu: an Insights
/// capsule, an "Enable Apple Intelligence" or "Sign in to …" call
/// to action, or nothing at all when AI is off or the device can't
/// run the selected backend.
///
/// The ``Style/capsule`` style renders a bare list row with no section
/// of its own, so place it in the header's section to keep it tight
/// under the header. The ``Style/toolbar`` style renders an icon-only
/// button for a navigation bar.
struct InsightsLink: View {

    /// Where the Insights control appears.
    enum Style {
        /// A glass capsule row under a detail header.
        case capsule
        /// An icon-only navigation bar button.
        case toolbar
    }

    @Environment(\.preferencesStore) private var preferencesStore
    @Environment(\.aiCloudCredentialsStore) private var credentialsStore
    @Environment(\.hapticFeedback) private var hapticFeedback
    @Environment(\.openURL) private var openURL
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    private let style: Style
    private let action: () -> Void

    /// Creates the Insights control.
    ///
    /// - Parameters:
    ///   - style: Where the control appears.
    ///   - action: Presents the Insights sheet. Called after a
    ///     `.medium` haptic has already fired.
    init(style: Style = .capsule, action: @escaping () -> Void) {
        self.style = style
        self.action = action
    }

    var body: some View {
        switch state {
        case .explain(let backend):
            control(title: Strings.Insights.explainWithAI, backend: backend) {
                hapticFeedback.play(.medium)
                action()
            }
            .accessibilityIdentifier("insights_link")

        case .enableAppleIntelligence:
            control(title: Strings.Insights.enableAppleIntelligence, backend: .appleIntelligence) {
                hapticFeedback.play(.light)
                openAppleIntelligenceSettings()
            }

        case .signIn(let backend, let provider):
            control(title: Self.signInTitle(for: provider), backend: backend) {
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

    // MARK: - Control

    @ViewBuilder
    private func control(
        title: LocalizedStringResource,
        backend: AIBackend,
        perform: @escaping () -> Void
    ) -> some View {
        switch style {
        case .capsule:
            capsule(title: title, backend: backend, perform: perform)
        case .toolbar:
            toolbarButton(title: title, backend: backend, perform: perform)
        }
    }

    /// Icon-only, but the title stays the VoiceOver label.
    private func toolbarButton(
        title: LocalizedStringResource,
        backend: AIBackend,
        perform: @escaping () -> Void
    ) -> some View {
        Button(action: perform) {
            Label {
                Text(title)
            } icon: {
                backend.icon
                    .foregroundStyle(labelStyle(for: backend))
            }
            .labelStyle(.iconOnly)
        }
        // The bar's own tinting overrides the label's gradient, so
        // tint the button with the assistant's accent instead.
        .tint(backend.accentColor)
    }

    // MARK: - Capsule

    private func capsule(
        title: LocalizedStringResource,
        backend: AIBackend,
        perform: @escaping () -> Void
    ) -> some View {
        Button(action: perform) {
            Label {
                Text(title)
            } icon: {
                backend.icon
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(labelStyle(for: backend))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .buttonStyle(InsightsCapsuleButtonStyle(tint: backend.accentColor))
        .frame(maxWidth: .infinity, minHeight: 44)
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 12, leading: 8, bottom: 4, trailing: 8))
    }

    /// The chat wash's colours as a gradient, or the backend's solid
    /// accent under Increase Contrast — the lighter gradient stops
    /// don't hold contrast on glass.
    private func labelStyle(for backend: AIBackend) -> AnyShapeStyle {
        if colorSchemeContrast == .increased {
            return AnyShapeStyle(backend.accentColor)
        }
        return AnyShapeStyle(
            LinearGradient(
                colors: AmbientMeshPalette.chatAccents(for: backend),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
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

// MARK: - InsightsCapsuleButtonStyle

/// Interactive Liquid Glass capsule, lightly tinted with the
/// assistant's accent. Mirrors the chat suggestion chips; the label
/// dims while pressed so feedback survives Reduce Motion.
private struct InsightsCapsuleButtonStyle: ButtonStyle {

    let tint: Color

    @ViewBuilder
    func makeBody(configuration: Configuration) -> some View {
        let capsule = configuration.label
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            #if os(visionOS)
            .glassBackgroundEffect(in: Capsule(style: .continuous))
            #else
            .glassEffect(.regular.tint(tint.opacity(0.15)).interactive(), in: Capsule(style: .continuous))
            #endif
            .contentShape(.capsule)

        #if !os(macOS)
        capsule.hoverEffect(.highlight)
        #else
        capsule
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
