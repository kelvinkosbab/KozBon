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
            // Shown only while a now-useless GitHub PAT is still
            // in the Keychain — see `gitHubRetirementNotice`.
            if hasGitHubKey {
                gitHubRetirementNotice
            }

            backendPicker

            switch preferencesStore.aiBackend {
            case .appleIntelligence:
                EmptyView()
            case .anthropic:
                anthropicSignInRow

                if hasAnthropicKey {
                    claudeModelPicker
                }
            case .gemini:
                geminiSignInRow

                if hasGeminiKey {
                    geminiModelPicker
                }
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
                }
            }
        }
    }

    // MARK: - Backend Picker

    /// Inline picker so every option surfaces simultaneously —
    /// each with its provider glyph tinted in the matching brand
    /// color (blue for Apple Intelligence, Cara orange for
    /// Anthropic, Google blue for Gemini). The visible branding
    /// makes the active provider scannable without reading the
    /// subtitle, and having every row present lets users compare
    /// the subtitles (which describe the privacy posture and cost
    /// trade-off) side by side.
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
            // Enumerated rather than listed row by row: a
            // hardcoded list silently omitted Gemini when it was
            // added, and no switch meant no compiler error. Adding
            // a case to `AIBackend` now surfaces it here for free.
            ForEach(AIBackend.allCases) { backend in
                backendOption(backend)
                    .tag(backend)
            }
        } label: {
            Text(Strings.Settings.aiBackendPickerLabel)
        }
        .pickerStyle(.inline)
        .labelsHidden()
        .accessibilityLabel(Strings.Settings.aiBackendPickerLabel)
        .accessibilityHint(Strings.Accessibility.aiBackendPickerHint)
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

    /// Anthropic-specific signed-in / sign-in row.
    @ViewBuilder
    private var anthropicSignInRow: some View {
        signInRow(
            provider: .anthropic,
            isConnected: hasAnthropicKey,
            signInLabel: Strings.Settings.aiCloudSignIn
        )
    }

    /// Gemini-specific signed-in / sign-in row.
    @ViewBuilder
    private var geminiSignInRow: some View {
        signInRow(
            provider: .gemini,
            isConnected: hasGeminiKey,
            signInLabel: Strings.Settings.aiCloudSignInGemini
        )
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
                    providerPendingSignOut = provider
                } label: {
                    Text(Strings.Settings.aiCloudSignOut)
                }
                .accessibilityHint(Strings.Accessibility.aiCloudSignOutHint)
                .accessibilityIdentifier("aiCloud.signOut.\(provider.rawValue)")
            }
            .accessibilityElement(children: .combine)
        } else {
            Button {
                providerPendingSignIn = provider
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
            .accessibilityHint(Strings.Accessibility.aiCloudSignInHint)
            .accessibilityIdentifier("aiCloud.signIn.\(provider.rawValue)")
        }
    }

    // MARK: - Claude Model Picker

    /// Model picker driven by ``AnthropicModelCatalog`` rather
    /// than the hardcoded ``AnthropicModel`` enum.
    ///
    /// Anthropic ships new models between KozBon releases, so a
    /// compiled-in list goes stale the moment it ships. The
    /// catalog fetches what the user's own key can actually call;
    /// the enum survives only as the offline fallback.
    @ViewBuilder
    private var claudeModelPicker: some View {
        LabeledContent {
            Menu {
                ForEach(anthropicModelCatalog.options) { option in
                    modelMenuButton(for: option)
                }
            } label: {
                Text(verbatim: modelDisplayName(for: selectedModelIdentifier))
                    .font(.subheadline)
            }
            .accessibilityLabel(Strings.Settings.aiCloudModelPickerLabel)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(Strings.Settings.aiCloudModelPickerLabel)
                modelSubtitleView
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

    /// One row of the model menu. Extracted so the picker body
    /// stays small enough for the type-checker.
    @ViewBuilder
    private func modelMenuButton(for option: AnthropicModelOption) -> some View {
        let isSelected = option.id == selectedModelIdentifier
        Button {
            // Same animation treatment as the backend picker —
            // the checkmark moves between rows when selection
            // changes, and the move reads as a smooth slide
            // rather than a pop inside a `withAnimation`
            // transaction.
            withAnimation(reduceMotion ? nil : .default) {
                preferencesStore.aiCloudModelIdentifier = option.id
            }
        } label: {
            if isSelected {
                Label(modelDisplayName(for: option.id), systemImage: Iconography.selected)
            } else {
                Text(verbatim: modelDisplayName(for: option.id))
            }
        }
        // VoiceOver reads each menu Button's label identically
        // across selection states (the checkmark icon is
        // decorative within a `Label`), so without the
        // `.isSelected` trait a blind user can't tell which model
        // is currently active.
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// Subtitle under the picker label. The curated, localized
    /// blurbs only exist for the three built-in tiers; a model
    /// that came from the live catalog shows its identifier
    /// instead, which is more useful than nothing and needs no
    /// translation.
    @ViewBuilder
    private var modelSubtitleView: some View {
        if let builtIn = AnthropicModel(rawValue: selectedModelIdentifier) {
            Text(localizedSubtitle(for: builtIn))
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            Text(verbatim: selectedModelIdentifier)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Gemini Model Picker

    /// The Gemini counterpart to ``claudeModelPicker``, driven by
    /// ``GeminiModelCatalog`` for the same reason: Google ships new
    /// models between KozBon releases, so a compiled-in list is
    /// stale on arrival.
    ///
    /// Deliberately a sibling rather than a generalization of the
    /// Claude picker. The two differ in more than their data
    /// source — separate localized labels, separate built-in tiers
    /// with their own curated subtitles — and this file is already
    /// organized per provider.
    @ViewBuilder
    private var geminiModelPicker: some View {
        LabeledContent {
            Menu {
                ForEach(geminiModelCatalog.options) { option in
                    geminiModelMenuButton(for: option)
                }
            } label: {
                Text(verbatim: geminiModelDisplayName(for: selectedGeminiModelIdentifier))
                    .font(.subheadline)
            }
            .accessibilityLabel(Strings.Settings.aiCloudModelPickerLabelGemini)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(Strings.Settings.aiCloudModelPickerLabelGemini)
                geminiModelSubtitleView
            }
            .accessibilityElement(children: .combine)
        }
    }

    @ViewBuilder
    private func geminiModelMenuButton(for option: GeminiModelOption) -> some View {
        let isSelected = option.id == selectedGeminiModelIdentifier
        Button {
            withAnimation(reduceMotion ? nil : .default) {
                preferencesStore.setAICloudModelIdentifier(option.id, for: .gemini)
            }
        } label: {
            if isSelected {
                Label(geminiModelDisplayName(for: option.id), systemImage: Iconography.selected)
            } else {
                Text(verbatim: geminiModelDisplayName(for: option.id))
            }
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// Curated blurbs exist only for the compiled-in tiers; a
    /// catalog-sourced model shows its identifier, which beats
    /// showing nothing and needs no translation.
    @ViewBuilder
    private var geminiModelSubtitleView: some View {
        if let builtIn = GeminiModel(rawValue: selectedGeminiModelIdentifier) {
            Text(localizedSubtitle(for: builtIn))
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            Text(verbatim: selectedGeminiModelIdentifier)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    /// Reconciled against the catalog — an identifier this binary
    /// has never heard of survives unless a live list proves it
    /// retired.
    var selectedGeminiModelIdentifier: String {
        geminiModelCatalog.resolvedSelection(
            for: preferencesStore.aiCloudModelIdentifier(for: .gemini)
        )
    }

    func geminiModelDisplayName(for identifier: String) -> String {
        // Model names are brand identifiers, so unlike the
        // subtitles they aren't translated — the catalog's own
        // `displayName` and the built-in list agree on that.
        if let builtIn = GeminiModel(rawValue: identifier) {
            return builtIn.displayName
        }
        return geminiModelCatalog.displayName(for: identifier)
    }

    private func localizedSubtitle(for model: GeminiModel) -> LocalizedStringResource {
        switch model {
        case .pro:       return Strings.Settings.aiCloudModelGeminiProSubtitle
        case .flash:     return Strings.Settings.aiCloudModelGeminiFlashSubtitle
        case .flashLite: return Strings.Settings.aiCloudModelGeminiFlashLiteSubtitle
        }
    }

    // MARK: - Model Selection Helpers

    /// The currently-selected model identifier, reconciled against
    /// the catalog.
    ///
    /// ``AnthropicModelCatalog/resolvedSelection(for:)`` only
    /// overrides the stored value when it has a *live* list
    /// proving the model is gone — so a newer model this binary
    /// has never heard of is preserved rather than discarded.
    var selectedModelIdentifier: String {
        anthropicModelCatalog.resolvedSelection(
            for: preferencesStore.aiCloudModelIdentifier
        )
    }

    /// Display name for a model identifier.
    ///
    /// Built-in tiers keep their translated names from the String
    /// Catalog; catalog-sourced models use Anthropic's own
    /// `display_name`, which is English — consistent with how the
    /// project already treats provider and model branding.
    func modelDisplayName(for identifier: String) -> String {
        if let builtIn = AnthropicModel(rawValue: identifier) {
            return String(localized: localizedName(for: builtIn))
        }
        return anthropicModelCatalog.displayName(for: identifier)
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
        hasGitHubKey = credentialsStore.hasAPIKey(for: .github)
    }
}
