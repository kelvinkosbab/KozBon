//
//  SettingsView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import CoreData
import BonjourAI
import BonjourAIApple
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
    // `internal` so the `+AIBackend` companion file can read it.
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var isResetConfirmationPresented = false
    @State var isSignInSheetPresented = false

    /// Provider whose sign-out is being confirmed. Drives the
    /// alert's title + destructive target so taps on the
    /// non-active row don't remove the active provider's key.
    @State var providerPendingSignOut: AICloudProvider?

    /// Provider whose sign-in sheet is about to mount. Captured
    /// from the tapped row so per-provider copy matches.
    @State var providerPendingSignIn: AICloudProvider?

    /// Reflects "is there an Anthropic API key in the
    /// Keychain right now?" Refreshed on appearance and after
    /// the sign-in sheet dismisses or the sign-out confirmation
    /// resolves. Pulled into `@State` so the AI Backend row
    /// re-renders without re-querying the Keychain on every
    /// body evaluation.
    @State var hasAnthropicKey: Bool = false

    /// Mirror of ``hasAnthropicKey`` for the GitHub Models
    /// backend. Same refresh contract.
    @State var hasGitHubKey: Bool = false

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
                // Pre-ADR-0005 this section was gated solely on
                // `AppleIntelligenceSupport.isDeviceSupported` —
                // older iPhones / non-M-series Macs never saw the
                // AI Analysis controls. Now that the cloud
                // backend ships, the section surfaces when any
                // viable backend exists: Apple Intelligence
                // hardware OR a configured Anthropic key.
                if isAIAnalysisAvailable {
                    aiAnalysisSection
                }

                // The Assistant section (backend picker, sign-in
                // row, Claude model picker) only makes sense when
                // Insights are turned on — its only consumers are
                // the long-press Insights surface and the Chat
                // tab, and both of those are gated on
                // `aiAnalysisEnabled`. Hiding the section when
                // Insights is off keeps Settings focused and
                // avoids the implication that configuring a
                // provider does anything while the feature is
                // disabled.
                if preferencesStore.aiAnalysisEnabled {
                    aiBackendSection
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
            // Declarative section appear/disappear animations.
            // Watches multiple values so every preference flip
            // (and the per-backend sign-in state changes) get
            // the same transition without each mutation site
            // having to remember `withAnimation`.
            .animation(reduceMotion ? nil : .default, value: isAtDefaults)
            .animation(reduceMotion ? nil : .default, value: preferencesStore.aiAnalysisEnabled)
            .animation(reduceMotion ? nil : .default, value: preferencesStore.aiBackend)
            .animation(reduceMotion ? nil : .default, value: hasAnthropicKey)
            .animation(reduceMotion ? nil : .default, value: hasGitHubKey)
            // Refresh the cached custom-types flag on first
            // appearance so the Reset to Defaults section's
            // visibility is correct the moment the form lands.
            .onAppear {
                refreshCustomServiceTypesState()
                refreshCloudKeyState()
            }
            // Refresh on any Core Data save (the custom-types
            // store) so Library / chat-intent / Reset writes
            // flip section visibility without a manual refresh.
            // Especially relevant on macOS where Settings runs
            // in its own window scene alongside Library.
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
                    refreshCloudKeyState()
                }
            } message: {
                Text(Strings.Settings.resetConfirmationMessage)
            }
            .alert(
                // Title interpolates the specific provider name
                // (e.g. "Sign out of Claude?" / "Sign out of
                // GitHub?") so the user can't accidentally
                // remove the wrong key when both clouds are
                // signed in.
                providerPendingSignOut.map { provider in
                    Strings.Settings.aiCloudSignOutConfirmationTitle(
                        String(localized: provider.displayName)
                    )
                } ?? String(localized: Strings.Settings.aiCloudSignOut),
                isPresented: Binding(
                    get: { providerPendingSignOut != nil },
                    set: { presented in
                        if !presented { providerPendingSignOut = nil }
                    }
                )
            ) {
                Button(String(localized: Strings.Buttons.cancel), role: .cancel) {
                    providerPendingSignOut = nil
                }
                Button(String(localized: Strings.Settings.aiCloudSignOut), role: .destructive) {
                    if let provider = providerPendingSignOut {
                        signOut(from: provider)
                    }
                    providerPendingSignOut = nil
                }
            }
            .sheet(isPresented: $isSignInSheetPresented) {
                // Route to the provider whose row was tapped.
                // Anthropic fallback is defensive — the sheet
                // shouldn't open without `providerPendingSignIn`
                // being set, but if the rare race happens we
                // land on the historical default.
                AICloudSignInSheet(
                    credentialsStore: credentialsStore,
                    provider: providerPendingSignIn ?? .anthropic
                )
                    .onDisappear {
                        refreshCloudKeyState()
                        providerPendingSignIn = nil
                    }
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
            //
            // Gated to `aiBackend == .appleIntelligence` so users on
            // the cloud path don't see Apple-Intelligence-specific
            // warnings — their backend is fully functional regardless
            // of the on-device model's state.
            VStack(alignment: .leading, spacing: 8) {
                if preferencesStore.aiBackend == .appleIntelligence,
                   let reason = AppleIntelligenceSupport.unavailabilityReason {
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

    /// The destructive "Reset to defaults" affordance surfaces
    /// when something can be reset (a preference differs from its
    /// default, or a custom service type is persisted) AND
    /// Insights is enabled. When Insights is off, the rest of the
    /// AI surface is hidden, so a Reset button there would read
    /// out of context — re-enable Insights to access this
    /// section again.
    @ViewBuilder
    private var resetSection: some View {
        if preferencesStore.aiAnalysisEnabled, !isAtDefaults {
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

    /// Whether every reset-tracked preference is at its default
    /// AND no custom service types are persisted. The preference
    /// reads come through `@Observable` `preferencesStore`; the
    /// custom-types half reads the cached flag refreshed on
    /// `.onAppear` and `NSManagedObjectContextDidSave`.
    private var isAtDefaults: Bool {
        preferencesStore.aiAnalysisEnabled == UserPreferences.defaultAIAnalysisEnabled
            && preferencesStore.aiExpertiseLevel == UserPreferences.defaultAIExpertiseLevel
            && preferencesStore.aiResponseLength == UserPreferences.defaultAIResponseLength
            && preferencesStore.defaultSortOrder == UserPreferences.defaultSortOrder
            && !hasCustomServiceTypes
    }

    /// Whether any AI backend is currently usable — Apple
    /// Intelligence hardware-supported, OR a cloud key configured.
    /// ADR 0005 broadened this from on-device-only so users on
    /// ineligible hardware with a cloud account still see the AI
    /// Analysis controls.
    private var isAIAnalysisAvailable: Bool {
        AppleIntelligenceSupport.isDeviceSupported
            || credentialsStore.hasAPIKey(for: .anthropic)
            || credentialsStore.hasAPIKey(for: .github)
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

    /// Build metadata — marketing version row plus a navigation
    /// row that pushes the "What's New" release-notes page.
    @ViewBuilder
    private var aboutSection: some View {
        Section {
            LabeledContent(
                String(localized: Strings.Settings.version),
                value: AppVersion.marketing
            )
            // `monospacedDigit()` keeps the value column aligned
            // against any neighbouring rows we add later.
            .monospacedDigit()
            .accessibilityElement(children: .combine)

            NavigationLink {
                WhatsNewView()
            } label: {
                Text(Strings.Settings.whatsNew)
            }
            .accessibilityHint(Strings.Accessibility.whatsNewHint)
            .accessibilityIdentifier("whats_new_link")
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
