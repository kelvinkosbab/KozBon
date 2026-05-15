//
//  SettingsView+AIBackend.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourAI
import BonjourAIApple
import BonjourAICore
import BonjourAIAnthropic
import BonjourAIGitHub
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

            switch preferencesStore.aiBackend {
            case .appleIntelligence:
                EmptyView()
            case .anthropic:
                anthropicSignInRow

                if hasAnthropicKey {
                    claudeModelPicker
                }
            case .github:
                githubSignInRow
            }
        } header: {
            Text(Strings.Settings.aiBackendSection)
                .accessibilityAddTraits(.isHeader)
        } footer: {
            // Two-paragraph footer: a stable description of what
            // the AI is responsible for (applies to every
            // backend) followed by a backend-specific privacy
            // disclosure.
            VStack(alignment: .leading, spacing: 8) {
                Text(Strings.Settings.aiBackendSectionPurpose)

                switch preferencesStore.aiBackend {
                case .appleIntelligence:
                    Text(Strings.Settings.aiBackendApplePrivacy)
                case .anthropic:
                    Text(Strings.Settings.aiCloudFooter)
                case .github:
                    Text(Strings.Settings.aiBackendGitHubPrivacy)
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
                // Wrap the mutation in a `withAnimation`
                // transaction so the resulting color changes
                // ripple through the view tree smoothly: the
                // global `.tint(...)` in `AppCoreScene` reads
                // `aiBackend.accentColor` and propagates through
                // every tinted control (the picker's checkmark,
                // the sign-in/sign-out buttons, the chat tab's
                // icon highlight). Without an animation
                // transaction the colors pop between blue and
                // Cara orange in a single frame.
                //
                // The Form's existing `.animation(_:value:
                // aiBackend)` only covers descendants of the
                // Form — `withAnimation` covers everything that
                // re-renders from this mutation, including the
                // tint propagation upstream.
                set: { newValue in
                    withAnimation(reduceMotion ? nil : .default) {
                        preferencesStore.aiBackend = newValue
                    }
                }
            )
        ) {
            backendOption(.appleIntelligence)
                .tag(AIBackend.appleIntelligence)
            backendOption(.anthropic)
                .tag(AIBackend.anthropic)
            backendOption(.github)
                .tag(AIBackend.github)
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

    // MARK: - Sign-In Rows

    /// Anthropic-specific signed-in / sign-in row. The label and
    /// sign-out flow are Anthropic-flavored (Claude-specific
    /// copy); the layout is shared with the GitHub variant via
    /// ``signInRow(isConnected:signInLabel:)``.
    @ViewBuilder
    private var anthropicSignInRow: some View {
        signInRow(
            isConnected: hasAnthropicKey,
            signInLabel: Strings.Settings.aiCloudSignIn
        )
    }

    /// GitHub-specific signed-in / sign-in row. Surfaces the
    /// GitHub-flavored copy (`Sign in to GitHub`); reuses the
    /// shared layout helper.
    @ViewBuilder
    private var githubSignInRow: some View {
        signInRow(
            isConnected: hasGitHubKey,
            signInLabel: Strings.Settings.aiCloudSignInGitHub
        )
    }

    /// Shared row layout for both cloud backends. The
    /// connected-state copy ("Signed in" / "Sign out") is
    /// backend-agnostic; the sign-in CTA pulls a per-backend
    /// localized label so users see the right provider name.
    /// The sheet itself reads the active backend from
    /// preferences when it mounts, so callers don't need to
    /// thread the provider through.
    @ViewBuilder
    private func signInRow(
        isConnected: Bool,
        signInLabel: LocalizedStringResource
    ) -> some View {
        if isConnected {
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
            Button {
                isSignInSheetPresented = true
            } label: {
                HStack {
                    Label {
                        Text(signInLabel)
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
                        // Same animation treatment as the
                        // backend picker — the checkmark moves
                        // between rows when selection changes,
                        // and the move reads as a smooth slide
                        // rather than a pop inside a
                        // `withAnimation` transaction.
                        withAnimation(reduceMotion ? nil : .default) {
                            preferencesStore.aiCloudModel = model
                        }
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

    /// Removes the currently-selected cloud provider's credentials
    /// from the Keychain and falls the user's backend back to
    /// Apple Intelligence if available. If the device can't run
    /// Apple Intelligence we leave the backend preference at the
    /// cloud value (so the user's choice isn't second-guessed
    /// when they reach the Sign In flow again), but they'll see
    /// the "Not signed in" state until they enter a new key.
    ///
    /// Reads the active provider from the preferences store at
    /// call time so the alert's destructive button doesn't need
    /// to thread the provider through. A user on `.appleIntelligence`
    /// shouldn't see the sign-out alert — this method is a no-op
    /// for that case.
    func signOutOfCurrentBackend() {
        guard let provider = preferencesStore.aiBackend.cloudProvider else { return }
        do {
            try credentialsStore.removeAPIKey(for: provider)
        } catch {
            // Worst case: the key remains in the Keychain but the
            // user expects it gone. Surfacing the failure as a
            // separate alert would be louder than this warrants;
            // the next save attempt will overwrite cleanly.
        }
        // Animate the same way the picker-driven backend swap
        // does — sign-out reassigns `aiBackend` programmatically,
        // and without an animation transaction the global tint
        // would pop between brand colors in a single frame.
        withAnimation(reduceMotion ? nil : .default) {
            refreshCloudKeyState()
            if AppleIntelligenceSupport.isDeviceSupported {
                preferencesStore.aiBackend = .appleIntelligence
            }
        }
    }

    /// Re-queries the credentials store and refreshes both
    /// ``hasAnthropicKey`` and ``hasGitHubKey``. Called on
    /// appearance and after every sign-in / sign-out flow
    /// resolves.
    func refreshCloudKeyState() {
        hasAnthropicKey = credentialsStore.hasAPIKey(for: .anthropic)
        hasGitHubKey = credentialsStore.hasAPIKey(for: .github)
    }
}
