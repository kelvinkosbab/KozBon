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
import BonjourAIGemini
import BonjourAIOpenAI
import BonjourCore
import BonjourLocalization

// MARK: - SettingsView + AI Backend Section
//
// ADR 0005 introduces a pluggable AI backend. This file owns the
// section view-builders, model-name localization helpers, and the
// sign-out flow. State (`providerPendingSignIn`,
// `isSignOutConfirmationPresented`, `hasAnthropicKey`) stays on
// `SettingsView` itself because SwiftUI's `@State` ownership
// can't cross a file boundary; everything else moves here to keep
// `SettingsView.swift` under the file-length budget.

extension SettingsView {

    // MARK: - Section

    @ViewBuilder
    var aiBackendSection: some View {
        Section {
            // Shown only while a now-useless GitHub PAT is still
            // in the Keychain — see `gitHubRetirementNotice`.
            if hasGitHubKey {
                gitHubRetirementNotice
            }

            // Enumerated rather than listed row by row: a hardcoded
            // list silently omitted Gemini when it was added, and no
            // switch meant no compiler error. Adding a case to
            // `AIBackend` surfaces it here for free.
            ForEach(AIBackend.allCases) { backend in
                backendRow(backend)
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
                case .gemini:
                    Text(Strings.Settings.aiBackendGeminiPrivacy)
                case .openai:
                    Text(Strings.Settings.aiBackendOpenAIPrivacy)
                }
            }
        }
    }

    // MARK: - Backend Rows

    /// One selectable backend, with the selected cloud backend's
    /// model picker and sign-in controls folded into its own row.
    ///
    /// A hand-built list rather than an inline `Picker`: a picker
    /// row is a single selection target and can't host the menu and
    /// buttons the selected provider needs, which previously sat in
    /// separate rows at the bottom of the section — far from the
    /// option they configure. Every row stays visible so the
    /// subtitles (privacy posture, cost) can be compared side by
    /// side, and the selection carries `.isSelected` for VoiceOver,
    /// which is what the picker used to provide.
    @ViewBuilder
    private func backendRow(_ backend: AIBackend) -> some View {
        let isSelected = preferencesStore.aiBackend == backend

        VStack(alignment: .leading, spacing: 12) {
            Button {
                // `withAnimation` rather than relying on the Form's
                // `.animation(_:value:)`: the global tint in
                // `AppCoreScene` reads `aiBackend.accentColor`, and
                // only a transaction reaches that far up the tree.
                withAnimation(reduceMotion ? nil : .default) {
                    preferencesStore.aiBackend = backend
                }
            } label: {
                backendOption(backend, isSelected: isSelected)
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityHint(Strings.Accessibility.aiBackendPickerHint)
            .accessibilityIdentifier("aiBackend.option.\(backend.rawValue)")

            if isSelected, let provider = backend.cloudProvider {
                cloudControls(for: provider)
                    // Aligns with the title column: the 28pt icon
                    // frame plus the row's 12pt spacing.
                    .padding(.leading, 40)
                    .transition(.opacity)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .contain)
    }

    /// The label half of a backend row: brand glyph, name,
    /// subtitle, and a trailing checkmark on the selected row.
    ///
    /// The glyph sits in a fixed-width frame so the text columns
    /// align across rows regardless of each mark's intrinsic width.
    /// It's decorative — VoiceOver reads the combined name and
    /// subtitle, and the selection is a trait.
    @ViewBuilder
    private func backendOption(_ backend: AIBackend, isSelected: Bool) -> some View {
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

            Spacer(minLength: 8)

            if isSelected {
                Image.confirm
                    .font(.body.weight(.semibold))
                    .foregroundStyle(backend.accentColor)
                    .accessibilityHidden(true)
            }
        }
        // The whole row is the tap target, not just its text.
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    // MARK: - Cloud Controls

    /// The selected cloud provider's model picker and account
    /// controls, shown inside its row.
    ///
    /// `.borderless` because several buttons now share one list
    /// row; with the default style a tap anywhere in the row fires
    /// all of them.
    @ViewBuilder
    private func cloudControls(for provider: AICloudProvider) -> some View {
        let isConnected = hasAPIKey(for: provider)

        VStack(alignment: .leading, spacing: 4) {
            if isConnected {
                modelPicker(for: provider)
                    .frame(minHeight: 44)
            }
            signInRow(
                provider: provider,
                isConnected: isConnected,
                signInLabel: signInLabel(for: provider)
            )
        }
        .buttonStyle(.borderless)
    }

    /// The model picker for `provider`; each lives in
    /// `SettingsView+ModelPickers.swift`.
    @ViewBuilder
    private func modelPicker(for provider: AICloudProvider) -> some View {
        switch provider {
        case .anthropic: claudeModelPicker
        case .gemini:    geminiModelPicker
        case .openai:    openAIModelPicker
        case .github:    EmptyView()
        }
    }

    /// The cached key-presence flag for `provider`.
    private func hasAPIKey(for provider: AICloudProvider) -> Bool {
        switch provider {
        case .anthropic: hasAnthropicKey
        case .gemini:    hasGeminiKey
        case .openai:    hasOpenAIKey
        case .github:    hasGitHubKey
        }
    }

    private func signInLabel(for provider: AICloudProvider) -> LocalizedStringResource {
        switch provider {
        case .anthropic: Strings.Settings.aiCloudSignIn
        case .gemini:    Strings.Settings.aiCloudSignInGemini
        case .openai:    Strings.Settings.aiCloudSignInOpenAI
        // Retired; never selectable, so never asked for.
        case .github:    Strings.Settings.aiCloudSignIn
        }
    }

    // MARK: - GitHub Retirement Notice

    /// Explains why the GitHub Models option disappeared, and
    /// offers to delete the Personal Access Token it left behind.
    ///
    /// GitHub retired GitHub Models on 2026-07-30 (playground,
    /// catalog, inference API, and BYOK all withdrawn), and the
    /// endpoint KozBon called no longer resolves in DNS — so
    /// `AIBackend.github` was removed and anyone who had it
    /// selected is silently migrated to Apple Intelligence by
    /// `AIBackend.resolved(rawValue:)`. A silent switch would be
    /// baffling on its own, hence this row.
    ///
    /// Presence of the orphaned key IS the "should I show this?"
    /// state — no extra persisted flag, and the notice disappears
    /// for good once the token is removed. Reuses the standard
    /// sign-out confirmation flow via ``providerPendingSignOut``.
    @ViewBuilder
    private var gitHubRetirementNotice: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text(Strings.Settings.aiBackendGitHubRetiredTitle)
                    .font(.headline)
            } icon: {
                Image.errorBanner
                    .foregroundStyle(.orange)
                    .accessibilityHidden(true)
            }

            Text(Strings.Settings.aiBackendGitHubRetiredBody)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button(role: .destructive) {
                providerPendingSignOut = .github
            } label: {
                Text(Strings.Settings.aiBackendGitHubRetiredRemoveToken)
            }
            .accessibilityIdentifier("aiCloud.removeRetiredToken.github")
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .contain)
    }

    /// Shared row layout for both cloud backends. The destructive
    /// sign-out button captures `provider` into
    /// ``providerPendingSignOut`` so the confirmation alert
    /// targets the row's provider rather than the currently-
    /// selected backend — important when both cloud providers
    /// are signed in and the active one is GitHub but the user
    /// taps Sign Out on the Anthropic row.
    @ViewBuilder
    private func signInRow(
        provider: AICloudProvider,
        isConnected: Bool,
        signInLabel: LocalizedStringResource
    ) -> some View {
        if isConnected {
            // A tight icon-text pair rather than a `Label`, whose
            // icon column pushed the text ~40pt in from the model
            // picker's left edge once the row moved inline.
            HStack(spacing: 6) {
                Image.signedIn
                    .foregroundStyle(.green)
                    .accessibilityHidden(true)
                Text(Strings.Settings.aiCloudSignedIn)
                Spacer()
                Button(role: .destructive) {
                    providerPendingSignOut = provider
                } label: {
                    Text(Strings.Settings.aiCloudSignOut)
                }
                .accessibilityHint(Strings.Accessibility.aiCloudSignOutHint)
                .accessibilityIdentifier("aiCloud.signOut.\(provider.rawValue)")
            }
            .frame(minHeight: 44)
            .accessibilityElement(children: .combine)
        } else {
            Button {
                providerPendingSignIn = provider
            } label: {
                HStack(spacing: 6) {
                    Image.signIn
                        .accessibilityHidden(true)
                    Text(signInLabel)
                    Spacer()
                    Image.disclosure
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
                // Full-width, 44pt target: borderless buttons only
                // hit-test their visible content.
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .accessibilityHint(Strings.Accessibility.aiCloudSignInHint)
            .accessibilityIdentifier("aiCloud.signIn.\(provider.rawValue)")
        }
    }

    // MARK: - Sign Out

    /// Removes the currently-selected cloud provider's credentials
    /// from the Keychain and falls the user's backend back to
    /// Removes the stored API key for `provider` and, if that
    /// provider was the user's currently-selected backend, falls
    /// the active backend back to Apple Intelligence (when the
    /// device supports it). Signing out from a non-active
    /// provider just clears its key — the user stays on whichever
    /// backend they had selected.
    ///
    /// The previous `signOutOfCurrentBackend()` always read from
    /// `preferencesStore.aiBackend`, which removed the wrong key
    /// when both cloud providers were configured but the user
    /// tapped Sign Out on the non-active row. Threading the
    /// provider through fixes that.
    func signOut(from provider: AICloudProvider) {
        do {
            try credentialsStore.removeAPIKey(for: provider)
        } catch {
            // Worst case: the key remains in the Keychain but the
            // user expects it gone. Surfacing the failure as a
            // separate alert would be louder than this warrants;
            // the next save attempt will overwrite cleanly.
        }
        withAnimation(reduceMotion ? nil : .default) {
            refreshCloudKeyState()
            // Only switch backend if we just signed out from the
            // active one. Keys-on-disk and active-backend are
            // independent — signing out from Anthropic while
            // using GitHub doesn't change which backend is
            // running.
            if preferencesStore.aiBackend.cloudProvider == provider,
               AppleIntelligenceSupport.isDeviceSupported {
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
        hasGeminiKey = credentialsStore.hasAPIKey(for: .gemini)
        hasOpenAIKey = credentialsStore.hasAPIKey(for: .openai)
        hasGitHubKey = credentialsStore.hasAPIKey(for: .github)
    }
}
