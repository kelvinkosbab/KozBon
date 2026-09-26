//
//  SettingsView+Display.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourCore
import BonjourLocalization
import BonjourModels
import BonjourStorage

// MARK: - SettingsView + Display

/// The Display section — the persistent default sort order and the
/// ambient-background switch — plus the sort-option plumbing it
/// owns.
///
/// Split out of `SettingsView.swift` to keep that file under the
/// file-length limit. `displaySection` is `internal` because
/// `private` doesn't span files and the main file's `body` composes
/// it; everything it reads in turn stays here.
extension SettingsView {

    @ViewBuilder
    var displaySection: some View {
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
                .accessibilityLabel(Strings.Settings.defaultSortOrder)
            } label: {
                Text(Strings.Settings.defaultSortOrder)
            }

            Toggle(isOn: ambientBackgroundBinding) {
                Text(Strings.Settings.ambientBackground)
            }
            .accessibilityHint(Strings.Accessibility.ambientBackgroundHint)
            .accessibilityIdentifier("settings.ambientBackground")
        } header: {
            Text(Strings.Settings.display)
                .accessibilityAddTraits(.isHeader)
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                Text(Strings.Settings.displayFooter)
                Text(Strings.Settings.ambientBackgroundFooter)
            }
        }
    }

    /// Bridges the store's plain `Bool` into a `Binding` for the
    /// toggle. The wash appears and disappears behind the form the
    /// user is touching, so the change is animated unless the user
    /// asked for less motion.
    private var ambientBackgroundBinding: Binding<Bool> {
        Binding {
            preferencesStore.ambientBackgroundEnabled
        } set: { newValue in
            withAnimation(reduceMotion ? nil : .default) {
                preferencesStore.ambientBackgroundEnabled = newValue
            }
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
}
