//
//  SettingsView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import CoreData
import BonjourAI
import BonjourAICloud
import BonjourCore
import BonjourLocalization
import BonjourModels
import BonjourStorage

// MARK: - SettingsView

/// Cross-platform settings view providing user preferences for AI analysis,
/// display options, and data management.
public struct SettingsView: View {

    // The AI Backend section's view-builders and sign-out flow
    // live in `SettingsView+AIBackend.swift`. Per
    // `apple-swiftui-mvvm.md`, `private` doesn't span files —
    // these declarations stay `internal` so the companion
    // extension can read them. They remain `@State` /
    // `@Environment` on the View struct itself because SwiftUI
    // ownership can't traverse a class boundary.
    @Environment(\.preferencesStore) var preferencesStore
    @Environment(\.aiCloudCredentialsStore) var credentialsStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isResetConfirmationPresented = false
    @State var isSignInSheetPresented = false
    @State var isSignOutConfirmationPresented = false

    /// Reflects "is there an Anthropic API key in the
    /// Keychain right now?" Refreshed on appearance and after
    /// the sign-in sheet dismisses or the sign-out confirmation
    /// resolves. Pulled into `@State` so the AI Backend row
    /// re-renders without re-querying the Keychain on every
    /// body evaluation.
    @State var hasAnthropicKey: Bool = false

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

                aiBackendSection

                displaySection

                resetSection

                aboutSection
            }
            .formStyle(.grouped)
            #if os(macOS)
            .frame(width: 400)
            #endif
            .navigationTitle(String(localized: Strings.NavigationTitles.settings))
            // Drive the Reset to Defaults section's appear/disappear
            // animation declaratively. `.animation(_:value:)` watches
            // `isAtDefaults` and runs the same transition regardless
            // of which preference flipped — the AI toggle, the
            // expertise level menu, the sort order menu, or a
            // custom-service-type create/delete elsewhere in the app.
            // Without this every mutation point would have to
            // remember to wrap in `withAnimation`, which was easy to
            // forget when adding a new preference and produced an
            // instant pop instead of the smooth fade users expect.
            //
            // The companion `value: aiAnalysisEnabled` modifier
            // animates the conditional AI Expertise row inside the
            // AI Analysis section the same way.
            .animation(reduceMotion ? nil : .default, value: isAtDefaults)
            .animation(reduceMotion ? nil : .default, value: preferencesStore.aiAnalysisEnabled)
            .animation(reduceMotion ? nil : .default, value: preferencesStore.aiBackend)
            .animation(reduceMotion ? nil : .default, value: hasAnthropicKey)
            // Refresh the cached custom-types flag on first
            // appearance so the Reset to Defaults section's
            // visibility is correct the moment the form lands.
            .onAppear {
                refreshCustomServiceTypesState()
                refreshAnthropicKeyState()
            }
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
                refreshCustomServiceTypesState()
            }
            .alert(
                String(localized: Strings.Settings.resetToDefaults),
                isPresented: $isResetConfirmationPresented
            ) {
                Button(String(localized: Strings.Buttons.cancel), role: .cancel) {}
                Button(String(localized: Strings.Settings.reset), role: .destructive) {
                    preferencesStore.resetToDefaults()
                    BonjourServiceType.deleteAllPersistentCopies()
                    refreshAnthropicKeyState()
                }
            } message: {
                Text(Strings.Settings.resetConfirmationMessage)
            }
            .alert(
                String(localized: Strings.Settings.aiCloudSignOut),
                isPresented: $isSignOutConfirmationPresented
            ) {
                Button(String(localized: Strings.Buttons.cancel), role: .cancel) {}
                Button(String(localized: Strings.Settings.aiCloudSignOut), role: .destructive) {
                    signOutOfClaude()
                }
            }
            .sheet(isPresented: $isSignInSheetPresented) {
                AICloudSignInSheet(credentialsStore: credentialsStore)
                    .onDisappear { refreshAnthropicKeyState() }
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
                    set: { preferencesStore.aiAnalysisEnabled = $0 }
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
            // When Apple Intelligence is currently unavailable for an
            // actionable reason (turned off in iOS Settings, model
            // still downloading, etc.), surface the localized message
            // above the regular footer copy so the user understands
            // why the toggle below has no effect. `unavailabilityReason`
            // is `nil` when AI is fully available or when the device
            // can't run it at all (in which case this section is
            // hidden by `isDeviceSupported` upstream), so this notice
            // only fires for the "capable hardware, not currently
            // working" middle state.
            VStack(alignment: .leading, spacing: 8) {
                if let reason = AppleIntelligenceSupport.unavailabilityReason {
                    Text(verbatim: reason)
                        .foregroundStyle(.orange)
                        .accessibilityAddTraits(.isStaticText)
                }
                Text(Strings.Settings.aiAnalysisFooter)
            }
        }
    }

    // MARK: - AI Backend Section
    //
    // Implementation lives in `SettingsView+AIBackend.swift` —
    // section view-builders, model-name localization helpers, and
    // the sign-out flow. The state vars (`isSignInSheetPresented`,
    // `isSignOutConfirmationPresented`, `hasAnthropicKey`) stay on
    // `SettingsView` itself since SwiftUI's `@State` ownership
    // can't cross the file boundary.

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
            // Normalize: when the user picks the fallback sort
            // (`hostNameAsc`), persist the documented empty-string
            // default instead of the explicit id. Both produce the
            // same effective sort, but persisting `"hostNameAsc"`
            // would make `isAtDefaults` think the user changed
            // away from default — and the Reset to Defaults
            // section would stay visible after the user picked
            // the same option that was already showing as
            // selected. Keeping the store canonical (`""` always
            // means "default") avoids that surprise without
            // leaking the fallback equivalence into every
            // `defaultSortOrder` consumer.
            preferencesStore.defaultSortOrder = sortType.id == BonjourServiceSortType.hostNameAsc.id
                ? UserPreferences.defaultSortOrder
                : sortType.id
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
