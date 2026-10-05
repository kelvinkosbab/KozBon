//
//  SettingsView+ModelPickers.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourCore
import BonjourAICore
import BonjourAIAnthropic
import BonjourAIGemini
import BonjourAIOpenAI
import BonjourLocalization

// MARK: - SettingsView + Model Pickers

/// The per-provider model pickers and their localized copy.
///
/// Split out of `SettingsView+AIBackend.swift` to keep that file
/// under the file-length budget. Each provider's picker is
/// populated at runtime from its catalog (see the AI Backend
/// Routing notes in `CLAUDE.md`), so this file grows with every
/// provider while the section wiring next door does not.
extension SettingsView {

    /// Model picker driven by ``AnthropicModelCatalog`` rather
    /// than the hardcoded ``AnthropicModel`` enum.
    ///
    /// Anthropic ships new models between KozBon releases, so a
    /// compiled-in list goes stale the moment it ships. The
    /// catalog fetches what the user's own key can actually call;
    /// the enum survives only as the offline fallback.
    @ViewBuilder
    var claudeModelPicker: some View {
        modelPickerRow(
            label: Strings.Settings.aiCloudModelPickerLabel,
            selectedName: modelDisplayName(for: selectedModelIdentifier)
        ) {
            ForEach(anthropicModelCatalog.options) { option in
                modelMenuButton(for: option)
            }
        } subtitle: {
            modelSubtitleView
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
    var geminiModelPicker: some View {
        modelPickerRow(
            label: Strings.Settings.aiCloudModelPickerLabelGemini,
            selectedName: geminiModelDisplayName(for: selectedGeminiModelIdentifier)
        ) {
            ForEach(geminiModelCatalog.options) { option in
                geminiModelMenuButton(for: option)
            }
        } subtitle: {
            geminiModelSubtitleView
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

    // MARK: - OpenAI Model Picker

    /// The OpenAI counterpart to ``geminiModelPicker``, driven by
    /// ``OpenAIModelCatalog``.
    @ViewBuilder
    var openAIModelPicker: some View {
        modelPickerRow(
            label: Strings.Settings.aiCloudModelPickerLabelOpenAI,
            selectedName: openAIModelCatalog.displayName(for: selectedOpenAIModelIdentifier)
        ) {
            ForEach(openAIModelCatalog.options) { option in
                openAIModelMenuButton(for: option)
            }
        } subtitle: {
            openAIModelSubtitleView
        }
    }

    @ViewBuilder
    private func openAIModelMenuButton(for option: OpenAIModelOption) -> some View {
        let isSelected = option.id == selectedOpenAIModelIdentifier
        Button {
            withAnimation(reduceMotion ? nil : .default) {
                preferencesStore.setAICloudModelIdentifier(option.id, for: .openai)
            }
        } label: {
            if isSelected {
                Label(option.displayName, systemImage: Iconography.selected)
            } else {
                Text(verbatim: option.displayName)
            }
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// Curated blurbs exist only for the compiled-in tiers; a
    /// catalog-sourced model shows its identifier.
    @ViewBuilder
    private var openAIModelSubtitleView: some View {
        if let builtIn = OpenAIModel(rawValue: selectedOpenAIModelIdentifier) {
            Text(localizedSubtitle(for: builtIn))
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            Text(verbatim: selectedOpenAIModelIdentifier)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    /// Reconciled against the catalog, as for the other providers.
    var selectedOpenAIModelIdentifier: String {
        openAIModelCatalog.resolvedSelection(
            for: preferencesStore.aiCloudModelIdentifier(for: .openai)
        )
    }

    private func localizedSubtitle(for model: OpenAIModel) -> LocalizedStringResource {
        switch model {
        case .flagship: return Strings.Settings.aiCloudModelOpenAIFlagshipSubtitle
        case .mini:     return Strings.Settings.aiCloudModelOpenAIMiniSubtitle
        case .nano:     return Strings.Settings.aiCloudModelOpenAINanoSubtitle
        }
    }

    // MARK: - Shared Picker Row

    /// The layout every provider's model picker shares: the label
    /// on the leading edge, the current model as a tinted capsule
    /// menu on the trailing edge, and the model's description
    /// underneath at full width.
    ///
    /// A capsule with an up/down chevron rather than plain text:
    /// as a bare menu label the model name read as a static value,
    /// not as something the user could change.
    @ViewBuilder
    private func modelPickerRow<Options: View, Subtitle: View>(
        label: LocalizedStringResource,
        selectedName: String,
        @ViewBuilder options: () -> Options,
        @ViewBuilder subtitle: () -> Subtitle
    ) -> some View {
        let menu = modelMenu(label: label, selectedName: selectedName, options: options)

        VStack(alignment: .leading, spacing: 6) {
            // Side by side when both fit; otherwise the label takes
            // its own line and the capsule keeps the trailing edge
            // below it. A long model name ("Claude Sonnet 4.5") or a
            // large Dynamic Type size would otherwise truncate the
            // label to "Claude Mo…".
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    pickerLabel(label)
                    Spacer(minLength: 8)
                    menu
                }
                VStack(alignment: .leading, spacing: 6) {
                    pickerLabel(label)
                    HStack {
                        Spacer(minLength: 0)
                        menu
                    }
                }
            }

            subtitle()
        }
    }

    /// The visible label, hidden from VoiceOver because the menu
    /// carries it as its accessibility label.
    private func pickerLabel(_ label: LocalizedStringResource) -> some View {
        Text(label)
            .fixedSize()
            .accessibilityHidden(true)
    }

    /// The current model as a tinted capsule menu with an up/down
    /// chevron.
    private func modelMenu<Options: View>(
        label: LocalizedStringResource,
        selectedName: String,
        @ViewBuilder options: () -> Options
    ) -> some View {
        Menu {
            options()
        } label: {
            HStack(spacing: 4) {
                Text(verbatim: selectedName)
                    .lineLimit(1)
                Image.menuIndicator
                    .imageScale(.small)
                    .accessibilityHidden(true)
            }
            .font(.subheadline.weight(.semibold))
        }
        .menuStyle(.button)
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .tint(preferencesStore.aiBackend.accentColor)
        .fixedSize()
        // VoiceOver hears "Claude Model, Sonnet 4.5, pop-up button".
        .accessibilityLabel(label)
        .accessibilityValue(Text(verbatim: selectedName))
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
}
