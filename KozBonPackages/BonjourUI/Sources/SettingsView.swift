//
//  SettingsView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
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
                // MARK: AI Analysis

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
                            Picker(
                                String(localized: Strings.Settings.aiExpertiseLevel),
                                selection: Binding(
                                    get: { preferencesStore.aiExpertiseLevel },
                                    set: { preferencesStore.aiExpertiseLevel = $0 }
                                )
                            ) {
                                Text(Strings.AIInsights.basic).tag("basic")
                                Text(Strings.AIInsights.technical).tag("technical")
                            }
                            .labelsHidden()
                            .font(.subheadline)
                            .accessibilityLabel(String(localized: Strings.Settings.aiExpertiseLevel))
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(Strings.Settings.aiExpertiseLevel)
                                Text(currentExpertiseLevelDescription)
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

                // MARK: Display

                Section(String(localized: Strings.Settings.display)) {
                    LabeledContent {
                        Picker(
                            String(localized: Strings.Settings.defaultSortOrder),
                            selection: Binding(
                                get: {
                                    let stored = preferencesStore.defaultSortOrder
                                    return stored.isEmpty ? BonjourServiceSortType.hostNameAsc.id : stored
                                },
                                set: { preferencesStore.defaultSortOrder = $0 }
                            )
                        ) {
                            ForEach(BonjourServiceSortType.allCases) { sortType in
                                Text(sortType.title).tag(sortType.id)
                            }
                        }
                        .labelsHidden()
                        .font(.subheadline)
                        .accessibilityLabel(String(localized: Strings.Settings.defaultSortOrder))
                    } label: {
                        Text(Strings.Settings.defaultSortOrder)
                    }
                }

                // MARK: Reset

                Section {
                    Button(role: .destructive) {
                        isResetConfirmationPresented = true
                    } label: {
                        Text(Strings.Settings.resetToDefaults)
                    }
                    .accessibilityHint(String(localized: Strings.Accessibility.resetHint))
                }
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

    // MARK: - Helpers

    /// A short description of the currently selected expertise level.
    private var currentExpertiseLevelDescription: LocalizedStringResource {
        preferencesStore.aiExpertiseLevel == "technical"
            ? Strings.Settings.aiTechnicalSubtitle
            : Strings.Settings.aiBasicSubtitle
    }

}
