//
//  SettingsView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import CoreData
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

    /// Cached "the user has at least one persisted custom service
    /// type" flag. Refreshed on `.onAppear` and on every Core Data
    /// `NSManagedObjectContextDidSave` notification, so the
    /// `isAtDefaults` check (and therefore the visibility of the
    /// Reset to Defaults section) reacts in near-realtime when the
    /// Library tab — or the chat assistant's intent flow, or any
    /// future surface — adds or deletes a custom type. The cached
    /// flag also keeps the `isAtDefaults` computation off the
    /// Core Data fetch path on every body re-evaluation.
    @State private var hasCustomServiceTypes: Bool = false

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                if AppleIntelligenceSupport.isDeviceSupported {
                    aiAnalysisSection
                }

                displaySection

                resetSection

                aboutSection
            }
            .formStyle(.grouped)
            #if os(macOS)
            .frame(width: 400)
            #endif
            .navigationTitle(String(localized: Strings.NavigationTitles.settings))
            // Refresh the cached custom-types flag on first
            // appearance so the Reset to Defaults section's
            // visibility is correct the moment the form lands.
            .onAppear { refreshCustomServiceTypesState() }
            // Listen for any Core Data save in the process. KozBon
            // has a single Core Data stack (the custom-service-type
            // store) so every `NSManagedObjectContextDidSave` here
            // is from that store; SwiftData (used for preferences)
            // doesn't post these notifications. This catches:
            //
            //   - the Library tab's create/delete flows
            //   - the chat assistant's `prepareCustomServiceType` /
            //     `prepareDeleteCustomServiceType` intents
            //   - the Reset to Defaults action itself (after which
            //     the section needs to disappear)
            //
            // Especially relevant on macOS where Settings runs in
            // its own window scene — a user can edit the Library
            // in one window and Settings in another, and we want
            // the section to flip visibility without a manual
            // refresh. iOS / iPadOS / visionOS reach the same
            // surface via tab switching, which already triggers
            // `.onAppear`, but the listener is harmless there
            // (notifications are debounced into a single state
            // update per save).
            .onReceive(
                NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            ) { _ in
                withAnimation(reduceMotion ? nil : .default) {
                    refreshCustomServiceTypesState()
                }
            }
            .alert(
                String(localized: Strings.Settings.resetToDefaults),
                isPresented: $isResetConfirmationPresented
            ) {
                Button(String(localized: Strings.Buttons.cancel), role: .cancel) {}
                Button(String(localized: Strings.Settings.reset), role: .destructive) {
                    // Wrap the state mutations in `withAnimation`
                    // so the reset section fades out smoothly once
                    // `isAtDefaults` flips to true. Without this,
                    // the section vanishes instantly the moment
                    // the alert dismisses, which reads as the
                    // form having a glitch instead of as a
                    // deliberate "everything's clean now" cue.
                    withAnimation(reduceMotion ? nil : .default) {
                        preferencesStore.resetToDefaults()
                        BonjourServiceType.deleteAllPersistentCopies()
                    }
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

    /// The destructive "Reset to defaults" affordance only surfaces
    /// when there's *something* to reset — at least one preference
    /// differs from its documented default, OR at least one
    /// user-created custom service type is persisted in Core Data.
    /// Hiding the section in the all-defaults case keeps the form
    /// short and prevents users from accidentally reaching for a
    /// destructive button that would do nothing visible.
    @ViewBuilder
    private var resetSection: some View {
        if !isAtDefaults {
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
    }

    /// Whether every preference tracked by the reset action is at
    /// its documented default value AND no custom service types
    /// are persisted. The four preference comparisons read from
    /// the `@Observable` `preferencesStore`, which triggers a
    /// re-render when any preference changes; the custom-types
    /// half reads the cached ``hasCustomServiceTypes`` flag,
    /// which is refreshed on `.onAppear` and on every
    /// `NSManagedObjectContextDidSave` notification. Net result:
    /// the Reset to Defaults section reacts to changes from any
    /// surface — the Library tab, the chat assistant's intent
    /// flow, the reset action itself — within a single render
    /// cycle of the underlying mutation, on every platform
    /// including macOS multi-window setups where Settings can be
    /// open in parallel with Library.
    private var isAtDefaults: Bool {
        preferencesStore.aiAnalysisEnabled == UserPreferences.defaultAIAnalysisEnabled
            && preferencesStore.aiExpertiseLevel == UserPreferences.defaultAIExpertiseLevel
            && preferencesStore.aiResponseLength == UserPreferences.defaultAIResponseLength
            && preferencesStore.defaultSortOrder == UserPreferences.defaultSortOrder
            && !hasCustomServiceTypes
    }

    /// Re-queries the Core Data custom-types store and updates
    /// ``hasCustomServiceTypes``. Cheap (the store is typically
    /// empty or a handful of rows) but cached behind `@State` so
    /// it doesn't run on every body evaluation. Called from
    /// `.onAppear` and from the `NSManagedObjectContextDidSave`
    /// publisher.
    private func refreshCustomServiceTypesState() {
        hasCustomServiceTypes = !BonjourServiceType.fetchAllPersistentCopies().isEmpty
    }

    // MARK: - About Section

    /// Read-only metadata about the running build — marketing version
    /// (`CFBundleShortVersionString`) and build number
    /// (`CFBundleVersion`). Surfaced as separate ``LabeledContent``
    /// rows so each piece carries its own VoiceOver label and
    /// monospaced-digit value column. The combined "4.2 (114)" form
    /// available as ``AppVersion/formatted`` is intentionally not
    /// used here — splitting into rows lets users scan, copy via
    /// long-press selection, and identify whichever piece a bug
    /// report or TestFlight crash dump is asking for, without
    /// having to mentally parse a parenthetical.
    @ViewBuilder
    private var aboutSection: some View {
        Section {
            LabeledContent(
                String(localized: Strings.Settings.version),
                value: AppVersion.marketing
            )
            // `monospacedDigit()` keeps the value column aligned across
            // both rows even when the marketing and build strings have
            // different proportional widths — without it, "4.2" and
            // "114" land at slightly different x positions on the
            // grouped-form's trailing edge.
            .monospacedDigit()
            .accessibilityElement(children: .combine)

            LabeledContent(
                String(localized: Strings.Settings.buildNumber),
                value: AppVersion.build
            )
            .monospacedDigit()
            .accessibilityElement(children: .combine)
        } header: {
            Text(Strings.Settings.about)
                .accessibilityAddTraits(.isHeader)
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
