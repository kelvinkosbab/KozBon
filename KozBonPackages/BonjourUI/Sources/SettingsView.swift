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

                // Chat persistence is only meaningful when the
                // chat tab is actually surfaced — otherwise the
                // toggle is for a feature the user can't reach.
                if AppleIntelligenceSupport.isDeviceSupported,
                   preferencesStore.aiAnalysisEnabled {
                    chatSection
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
                                Label(String(localized: Strings.Insights.basic), systemImage: Iconography.selected)
                            } else {
                                Text(Strings.Insights.basic)
                            }
                        }

                        Button {
                            preferencesStore.aiExpertiseLevel = "technical"
                        } label: {
                            if preferencesStore.aiExpertiseLevel == "technical" {
                                Label(String(localized: Strings.Insights.technical), systemImage: Iconography.selected)
                            } else {
                                Text(Strings.Insights.technical)
                            }
                        }
                    } label: {
                        Text(preferencesStore.aiExpertiseLevel == "technical"
                             ? Strings.Insights.technical
                             : Strings.Insights.basic)
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

                // Response length is no longer user-selectable: it's
                // derived from the Detail level above (Basic →
                // standard, Technical → thorough). The previous
                // standalone picker confused users because both
                // controls seemed to govern "how much detail you get."
                // Folding length into Detail level keeps the surface
                // clean while still giving each level a meaningfully
                // different shape of response.
            }
        } header: {
            Text(Strings.Settings.aiAnalysis)
                .accessibilityAddTraits(.isHeader)
        } footer: {
            Text(Strings.Settings.aiAnalysisFooter)
        }
    }

    // MARK: - Chat Section

    @ViewBuilder
    private var chatSection: some View {
        Section {
            Toggle(
                String(localized: Strings.Settings.persistChatHistory),
                isOn: Binding(
                    get: { preferencesStore.persistChatHistory },
                    set: { newValue in
                        withAnimation(reduceMotion ? nil : .default) {
                            preferencesStore.persistChatHistory = newValue
                        }
                    }
                )
            )

            if preferencesStore.persistChatHistory {
                LabeledContent(
                    String(localized: Strings.Settings.persistChatHistoryStorageUsed),
                    value: chatHistoryStorageDescription
                )
                .accessibilityElement(children: .combine)
            }
        } header: {
            Text(chatSectionHeader)
                .accessibilityAddTraits(.isHeader)
        } footer: {
            Text(Strings.Settings.persistChatHistoryFooter)
        }
    }

    /// Human-readable size of the persisted chat history blob, formatted
    /// with the system's localized byte-count style (e.g. "12 KB",
    /// "0 bytes", "1.2 MB"). Reads zero when nothing has been saved
    /// yet — that's still informative because it tells the user the
    /// toggle hasn't actually written anything to disk.
    private var chatHistoryStorageDescription: String {
        let bytes = Int64(preferencesStore.chatHistory?.count ?? 0)
        return bytes.formatted(.byteCount(style: .file))
    }

    /// Section header label that matches the platform's chat-tab
    /// label ("Chat" on iOS, "Explore" on macOS/visionOS) so the
    /// Preferences row reads consistently with the tab the user
    /// just tapped over from.
    private var chatSectionHeader: LocalizedStringResource {
        #if os(macOS) || os(visionOS)
        Strings.Tabs.explore
        #else
        Strings.Tabs.chat
        #endif
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
            String(localized: Strings.Insights.responseLengthBrief)
        case .standard:
            String(localized: Strings.Insights.responseLengthStandard)
        case .thorough:
            String(localized: Strings.Insights.responseLengthThorough)
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
