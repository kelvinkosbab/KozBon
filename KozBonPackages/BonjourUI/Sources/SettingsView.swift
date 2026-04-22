//
//  SettingsView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourAI
import BonjourCore
import BonjourLocalization
import BonjourModels
import BonjourStorage

// MARK: - SettingsView

/// Cross-platform settings view providing user preferences for AI analysis,
/// display options, and data management.
public struct SettingsView: View {

    @Environment(\.preferencesStore) private var preferencesStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isResetConfirmationPresented = false

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                if AppleIntelligenceSupport.isDeviceSupported {
                    aiAnalysisSection
                }

                displaySection

                resetSection
            }
            .formStyle(.grouped)
            #if os(macOS)
            .frame(width: 400)
            #endif
            .navigationTitle(String(localized: Strings.NavigationTitles.settings))
            .alert(
                String(localized: Strings.Settings.resetToDefaults),
                isPresented: $isResetConfirmationPresented
            ) {
                Button(String(localized: Strings.Buttons.cancel), role: .cancel) {}
                Button(String(localized: Strings.Settings.reset), role: .destructive) {
                    preferencesStore.resetToDefaults()
                    BonjourServiceType.deleteAllPersistentCopies()
                }
            } message: {
                Text(Strings.Settings.resetConfirmationMessage)
            }
        }
    }

    // MARK: - AI Analysis Section

    @ViewBuilder
    private var aiAnalysisSection: some View {
        Section {
            Toggle(
                String(localized: Strings.Settings.aiAnalysisEnabled),
                isOn: Binding(
                    get: { preferencesStore.aiAnalysisEnabled },
                    set: { newValue in
                        withAnimation(reduceMotion ? nil : .default) {
                            preferencesStore.aiAnalysisEnabled = newValue
                        }
                    }
                )
            )
            .accessibilityHint(String(localized: Strings.Accessibility.toggleAIHint))

            if preferencesStore.aiAnalysisEnabled {
                LabeledContent {
                    Menu {
                        Button {
                            preferencesStore.aiExpertiseLevel = "basic"
                        } label: {
                            if preferencesStore.aiExpertiseLevel == "basic" {
                                Label(String(localized: Strings.AIInsights.basic), systemImage: Iconography.selected)
                            } else {
                                Text(Strings.AIInsights.basic)
                            }
                        }

                        Button {
                            preferencesStore.aiExpertiseLevel = "technical"
                        } label: {
                            if preferencesStore.aiExpertiseLevel == "technical" {
                                Label(String(localized: Strings.AIInsights.technical), systemImage: Iconography.selected)
                            } else {
                                Text(Strings.AIInsights.technical)
                            }
                        }
                    } label: {
                        Text(preferencesStore.aiExpertiseLevel == "technical"
                             ? Strings.AIInsights.technical
                             : Strings.AIInsights.basic)
                            .font(.subheadline)
                    }
                    .accessibilityLabel(String(localized: Strings.Settings.aiExpertiseLevel))
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Strings.Settings.aiExpertiseLevel)
                        Text(currentExpertiseLevelDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                LabeledContent {
                    Menu {
                        ForEach(Self.responseLengthOptions, id: \.rawValue) { length in
                            responseLengthButton(length: length)
                        }
                    } label: {
                        Text(currentResponseLength.displayTitle)
                            .font(.subheadline)
                    }
                    .accessibilityLabel(String(localized: Strings.Settings.aiResponseLength))
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Strings.Settings.aiResponseLength)
                        Text(currentResponseLength.displaySubtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Text(Strings.Settings.aiAnalysis)
                .accessibilityAddTraits(.isHeader)
        } footer: {
            Text(Strings.Settings.aiAnalysisFooter)
        }
    }

    @ViewBuilder
    private func responseLengthButton(length: BonjourServicePromptBuilder.ResponseLength) -> some View {
        Button {
            preferencesStore.aiResponseLength = length.rawValue
        } label: {
            if preferencesStore.aiResponseLength == length.rawValue {
                Label(length.displayTitle, systemImage: Iconography.selected)
            } else {
                Text(length.displayTitle)
            }
        }
    }

    private static let responseLengthOptions: [BonjourServicePromptBuilder.ResponseLength] = [
        .brief, .standard, .thorough
    ]

    private var currentResponseLength: BonjourServicePromptBuilder.ResponseLength {
        BonjourServicePromptBuilder.ResponseLength(
            rawValue: preferencesStore.aiResponseLength
        ) ?? .standard
    }

    // MARK: - Display Section

    @ViewBuilder
    private var displaySection: some View {
        Section {
            LabeledContent {
                Menu {
                    // Only sort options are offered as a persistent default.
                    // Filters (Smart Home, Apple devices, etc.) are transient
                    // view modes accessible from the Discover tab's sort menu —
                    // persisting a filter would hide all non-matching services
                    // on every launch, which confuses users.
                    ForEach(Self.sortOptions, id: \.self) { sortType in
                        sortMenuButton(for: sortType)
                    }
                } label: {
                    Text(currentSortTitle)
                        .font(.subheadline)
                }
                .accessibilityLabel(String(localized: Strings.Settings.defaultSortOrder))
            } label: {
                Text(Strings.Settings.defaultSortOrder)
            }
        } header: {
            Text(Strings.Settings.display)
                .accessibilityAddTraits(.isHeader)
        } footer: {
            Text(Strings.Settings.displayFooter)
        }
    }

    // MARK: - Reset Section

    @ViewBuilder
    private var resetSection: some View {
        Section {
            Button(role: .destructive) {
                isResetConfirmationPresented = true
            } label: {
                Text(Strings.Settings.resetToDefaults)
            }
            .accessibilityHint(String(localized: Strings.Accessibility.resetHint))
        } footer: {
            Text(Strings.Settings.resetFooter)
        }
    }

    // MARK: - Sort Options

    private static let sortOptions: [BonjourServiceSortType] = [
        .hostNameAsc, .hostNameDesc, .serviceNameAsc, .serviceNameDesc
    ]

    private var effectiveSortId: String {
        let stored = preferencesStore.defaultSortOrder
        return stored.isEmpty ? BonjourServiceSortType.hostNameAsc.id : stored
    }

    private var currentSortTitle: String {
        BonjourServiceSortType.allCases.first { $0.id == effectiveSortId }?.title
            ?? BonjourServiceSortType.hostNameAsc.title
    }

    @ViewBuilder
    private func sortMenuButton(for sortType: BonjourServiceSortType) -> some View {
        Button {
            preferencesStore.defaultSortOrder = sortType.id
        } label: {
            if effectiveSortId == sortType.id {
                Label(sortType.title, systemImage: Iconography.selected)
            } else {
                Label(sortType.title, systemImage: sortType.iconName)
            }
        }
    }

    // MARK: - Helpers

    /// A short description of the currently selected expertise level.
    private var currentExpertiseLevelDescription: LocalizedStringResource {
        preferencesStore.aiExpertiseLevel == "technical"
            ? Strings.Settings.aiTechnicalSubtitle
            : Strings.Settings.aiBasicSubtitle
    }
}

// MARK: - ResponseLength Display

extension BonjourServicePromptBuilder.ResponseLength {

    var displayTitle: String {
        switch self {
        case .brief:
            String(localized: Strings.AIInsights.responseLengthBrief)
        case .standard:
            String(localized: Strings.AIInsights.responseLengthStandard)
        case .thorough:
            String(localized: Strings.AIInsights.responseLengthThorough)
        }
    }

    var displaySubtitle: LocalizedStringResource {
        switch self {
        case .brief:
            Strings.Settings.aiResponseLengthBriefSubtitle
        case .standard:
            Strings.Settings.aiResponseLengthStandardSubtitle
        case .thorough:
            Strings.Settings.aiResponseLengthThoroughSubtitle
        }
    }
}
