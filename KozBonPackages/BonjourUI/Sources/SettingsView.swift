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
                } footer: {
                    Text(Strings.Settings.aiAnalysisFooter)
                }

                // MARK: Display

                Section(String(localized: Strings.Settings.display)) {
                    LabeledContent {
                        Menu {
                            Button {
                                preferencesStore.defaultSortOrder = ""
                            } label: {
                                if preferencesStore.defaultSortOrder.isEmpty {
                                    Label(
                                        String(localized: Strings.Settings.sortDefault),
                                        systemImage: Iconography.selected
                                    )
                                } else {
                                    Text(Strings.Settings.sortDefault)
                                }
                            }

                            Divider()

                            ForEach(BonjourServiceSortType.allCases) { sortType in
                                Button {
                                    preferencesStore.defaultSortOrder = sortType.id
                                } label: {
                                    if preferencesStore.defaultSortOrder == sortType.id {
                                        Label(sortType.title, systemImage: Iconography.selected)
                                    } else {
                                        Text(sortType.title)
                                    }
                                }
                            }
                        } label: {
                            Text(Strings.Buttons.update)
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(Strings.Settings.defaultSortOrder)
                            Text(currentSortOrderDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // MARK: Reset

                Section {
                    Button(role: .destructive) {
                        isResetConfirmationPresented = true
                    } label: {
                        Text(Strings.Settings.resetToDefaults)
                    }
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

    /// The display title of the currently selected sort order.
    private var currentSortOrderDescription: String {
        let storedId = preferencesStore.defaultSortOrder
        if let sortType = BonjourServiceSortType.allCases.first(where: { $0.id == storedId }) {
            return sortType.title
        }
        return String(localized: Strings.Settings.sortDefault)
    }
}
