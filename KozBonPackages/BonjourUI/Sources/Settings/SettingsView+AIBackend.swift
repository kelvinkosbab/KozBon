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

    /// Inline picker so both options surface simultaneously —
    /// each with its provider glyph tinted in the matching brand
    /// color (blue for Apple Intelligence, Cara orange for
    /// Anthropic). The visible branding makes the active provider
    /// scannable without reading the subtitle, and having both
    /// rows present lets users compare the subtitles (which
    /// describe the privacy posture + context-window trade-off)
    /// side by side.
    ///
    /// `.labelsHidden()` suppresses the picker's own header row —
    /// the "Assistant" section header already announces the
    /// purpose, so the intermediate "Provider" label row would
    /// just be visual noise. The label is preserved semantically
    /// for VoiceOver (`accessibilityLabel` + `accessibilityHint`)
    /// so screen-reader users still get the picker's role when
    /// they land on the control.
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
        .pickerStyle(.inline)
        .labelsHidden()
        .accessibilityLabel(String(localized: Strings.Settings.aiBackendPickerLabel))
        .accessibilityHint(String(localized: Strings.Accessibility.aiBackendPickerHint))
    }

    /// One row of the inline backend picker.
    ///
    /// Leading slot is the backend's brand glyph (Apple
    /// Intelligence sparkle for `.appleIntelligence`, the
    /// bundled Claude vector mark for `.anthropic`), tinted with
    /// the matching accent color (`Color.kozBonBlue` /
    /// `Color.kozBonAnthropic`) so each row carries a coherent
    /// visual identity. The icon sits in a fixed-width frame so
    /// the trailing text columns align across rows regardless of
    /// the icon's intrinsic width.
    ///
    /// The icon is decorative (`accessibilityHidden`) — the row's
    /// VoiceOver label is composed from the title and subtitle so
    /// screen-reader users get the same comparison content
    /// sighted users get.
    @ViewBuilder
    private func backendOption(_ backend: AIBackend) -> some View {
        HStack(spacing: 12) {
            backend.icon
                .font(.title3)
                .foregroundStyle(backend.accentColor)
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(backend.displayName)
                Text(backend.displaySubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
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
                    // VoiceOver reads each menu Button's label
                    // identically across selection states (the
                    // checkmark icon is decorative within a
                    // `Label`), so without the `.isSelected`
                    // trait a blind user can't tell which model
                    // is currently active. The trait makes
                    // VoiceOver append "selected" to the
                    // announcement for the matching option.
                    .accessibilityAddTraits(
                        preferencesStore.aiCloudModel == model ? .isSelected : []
                    )
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
            // Combine title + subtitle into one VoiceOver
            // element so users hear "Claude Model, Balanced.
            // 200K context window, Recommended for most
            // questions about your network." as a single read
            // rather than two separate elements requiring an
            // extra swipe.
            .accessibilityElement(children: .combine)
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
