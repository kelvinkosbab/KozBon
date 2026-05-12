//
//  SettingsView+AIBackend.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourAI
import BonjourAICloud
import BonjourCore
import BonjourLocalization

// MARK: - SettingsView + AI Backend Section
//
// ADR 0005 introduces a pluggable AI backend. This file owns the
// section view-builders, model-name localization helpers, and the
// sign-out flow. State (`isSignInSheetPresented`,
// `isSignOutConfirmationPresented`, `hasAnthropicKey`) stays on
// `SettingsView` itself because SwiftUI's `@State` ownership
// can't cross a file boundary; everything else moves here to keep
// `SettingsView.swift` under the file-length budget.

extension SettingsView {

    // MARK: - Section

    @ViewBuilder
    var aiBackendSection: some View {
        Section {
            backendPicker

            if preferencesStore.aiBackend == .anthropic {
                signInRow

                if hasAnthropicKey {
                    claudeModelPicker
                }
            }
        } header: {
            Text(Strings.Settings.aiBackendSection)
                .accessibilityAddTraits(.isHeader)
        } footer: {
            // Two-paragraph footer: a stable description of what
            // the AI is responsible for (applies to either
            // backend) followed by a backend-specific privacy
            // disclosure. The previous version surfaced the per-
            // backend privacy line as the whole footer, which
            // implicitly conveyed "AI is for privacy" rather
            // than "AI explains your services and runs the Chat
            // tab" — the purpose-first split makes both halves
            // legible.
            VStack(alignment: .leading, spacing: 8) {
                Text(Strings.Settings.aiBackendSectionPurpose)

                switch preferencesStore.aiBackend {
                case .appleIntelligence:
                    Text(Strings.Settings.aiBackendApplePrivacy)
                case .anthropic:
                    Text(Strings.Settings.aiCloudFooter)
                }
            }
        }
    }

    // MARK: - Backend Picker

    @ViewBuilder
    private var backendPicker: some View {
        Picker(
            selection: Binding(
                get: { preferencesStore.aiBackend },
                set: { preferencesStore.aiBackend = $0 }
            )
        ) {
            backendOption(.appleIntelligence)
                .tag(AIBackend.appleIntelligence)
            backendOption(.anthropic)
                .tag(AIBackend.anthropic)
        } label: {
            Text(Strings.Settings.aiBackendPickerLabel)
        }
        .accessibilityHint(String(localized: Strings.Accessibility.aiBackendPickerHint))
    }

    @ViewBuilder
    private func backendOption(_ backend: AIBackend) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(backend.displayName)
            Text(backend.displaySubtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Sign-In Row

    @ViewBuilder
    private var signInRow: some View {
        if hasAnthropicKey {
            // Connected state — leading "Signed in" status, trailing
            // destructive "Sign out" button. Keeps the row short
            // and avoids two competing CTAs.
            HStack {
                Label {
                    Text(Strings.Settings.aiCloudSignedIn)
                } icon: {
                    Image.signedIn
                        .foregroundStyle(.green)
                        .accessibilityHidden(true)
                }
                Spacer()
                Button(role: .destructive) {
                    isSignOutConfirmationPresented = true
                } label: {
                    Text(Strings.Settings.aiCloudSignOut)
                }
                .accessibilityHint(String(localized: Strings.Accessibility.aiCloudSignOutHint))
                .accessibilityIdentifier("aiCloud.signOut")
            }
            .accessibilityElement(children: .combine)
        } else {
            // Not connected — primary CTA to launch the sign-in
            // sheet. Tap target spans the row so it's easy to hit
            // with VoiceOver and on visionOS.
            Button {
                isSignInSheetPresented = true
            } label: {
                HStack {
                    Label {
                        Text(Strings.Settings.aiCloudSignIn)
                    } icon: {
                        Image.signIn
                            .accessibilityHidden(true)
                    }
                    Spacer()
                    Image.disclosure
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
            }
            .accessibilityHint(String(localized: Strings.Accessibility.aiCloudSignInHint))
            .accessibilityIdentifier("aiCloud.signIn")
        }
    }

    // MARK: - Claude Model Picker

    @ViewBuilder
    private var claudeModelPicker: some View {
        LabeledContent {
            Menu {
                ForEach(AnthropicModel.allCases) { model in
                    Button {
                        preferencesStore.aiCloudModel = model
                    } label: {
                        if preferencesStore.aiCloudModel == model {
                            Label(localizedName(for: model), systemImage: Iconography.selected)
                        } else {
                            Text(localizedName(for: model))
                        }
                    }
                }
            } label: {
                Text(localizedName(for: preferencesStore.aiCloudModel))
                    .font(.subheadline)
            }
            .accessibilityLabel(String(localized: Strings.Settings.aiCloudModelPickerLabel))
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(Strings.Settings.aiCloudModelPickerLabel)
                Text(localizedSubtitle(for: preferencesStore.aiCloudModel))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Localized Model Copy

    private func localizedName(for model: AnthropicModel) -> LocalizedStringResource {
        switch model {
        case .opus:   return Strings.Settings.aiCloudModelOpus
        case .sonnet: return Strings.Settings.aiCloudModelSonnet
        case .haiku:  return Strings.Settings.aiCloudModelHaiku
        }
    }

    private func localizedSubtitle(for model: AnthropicModel) -> LocalizedStringResource {
        switch model {
        case .opus:   return Strings.Settings.aiCloudModelOpusSubtitle
        case .sonnet: return Strings.Settings.aiCloudModelSonnetSubtitle
        case .haiku:  return Strings.Settings.aiCloudModelHaikuSubtitle
        }
    }

    // MARK: - Sign Out

    /// Removes the Anthropic API key from the Keychain and falls
    /// the user's backend back to Apple Intelligence if available.
    /// If the device can't run Apple Intelligence we leave the
    /// backend preference at `.anthropic` (so the user's choice
    /// isn't second-guessed when they reach the Sign In flow
    /// again), but they'll see the "Not signed in" state until
    /// they enter a new key.
    func signOutOfClaude() {
        do {
            try credentialsStore.removeAPIKey(for: .anthropic)
        } catch {
            // Worst case: the key remains in the Keychain but the
            // user expects it gone. Surfacing the failure as a
            // separate alert would be louder than this warrants;
            // the next save attempt will overwrite cleanly.
        }
        refreshAnthropicKeyState()
        if AppleIntelligenceSupport.isDeviceSupported {
            preferencesStore.aiBackend = .appleIntelligence
        }
    }

    /// Re-queries the credentials store and refreshes
    /// ``hasAnthropicKey``. Called on appearance and after every
    /// sign-in / sign-out flow resolves.
    func refreshAnthropicKeyState() {
        hasAnthropicKey = credentialsStore.hasAPIKey(for: .anthropic)
    }
}
