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
    @State private var isResetConfirmationPresented = false
    @State private var isDetailLevelInfoPresented = false

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
                            set: { preferencesStore.aiAnalysisEnabled = $0 }
                        )
                    )

                    VStack(alignment: .leading) {
                        Picker(
                            String(localized: Strings.Settings.aiExpertiseLevel),
                            selection: Binding(
                                get: { preferencesStore.aiExpertiseLevel },
                                set: { preferencesStore.aiExpertiseLevel = $0 }
                            )
                        ) {
                            Text(Strings.AIInsights.beginner).tag("beginner")
                            Text(Strings.AIInsights.technical).tag("technical")
                        }

                        Button {
                            isDetailLevelInfoPresented = true
                        } label: {
                            Text(Strings.Settings.whatsTheDifference)
                                .font(.caption)
                        }
                    }
                    .disabled(!preferencesStore.aiAnalysisEnabled)
                } header: {
                    Text(Strings.Settings.aiAnalysis)
                }

                // MARK: Display

                Section(String(localized: Strings.Settings.display)) {
                    Picker(
                        String(localized: Strings.Settings.defaultSortOrder),
                        selection: Binding(
                            get: { preferencesStore.defaultSortOrder },
                            set: { preferencesStore.defaultSortOrder = $0 }
                        )
                    ) {
                        Text(Strings.Settings.sortNone).tag("")
                        ForEach(BonjourServiceSortType.allCases) { sortType in
                            Text(sortType.title).tag(sortType.id)
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
            .alert(
                String(localized: Strings.Settings.aiExpertiseLevel),
                isPresented: $isDetailLevelInfoPresented
            ) {
                Button(String(localized: Strings.Buttons.ok)) {}
            } message: {
                Text(Strings.Settings.detailLevelExplanation)
            }
        }
    }
}
