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
                    }
                } header: {
                    Text(Strings.Settings.aiAnalysis)
                        .accessibilityAddTraits(.isHeader)
                } footer: {
                    Text(Strings.Settings.aiAnalysisFooter)
                }

                // MARK: Display

                Section {
                    LabeledContent {
                        Menu {
                            ForEach(Self.sortOptions, id: \.self) { sortType in
                                sortMenuButton(for: sortType)
                            }

                            Divider()

                            ForEach(Self.filterOptions, id: \.self) { sortType in
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

                // MARK: Reset

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

    // MARK: - Sort Options

    private static let sortOptions: [BonjourServiceSortType] = [
        .hostNameAsc, .hostNameDesc, .serviceNameAsc, .serviceNameDesc
    ]

    private static let filterOptions: [BonjourServiceSortType] = [
        .smartHome, .appleDevices, .mediaAndStreaming, .printersAndScanners, .remoteAccess
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
