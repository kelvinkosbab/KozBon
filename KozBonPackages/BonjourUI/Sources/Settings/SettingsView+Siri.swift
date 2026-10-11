//
//  SettingsView+Siri.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import AppIntents
import SwiftUI
import BonjourLocalization

// MARK: - SettingsView + Siri

/// The "Using Siri with KozBon" section: one row that cycles through
/// Siri phrases for KozBon's most useful actions, and a button that
/// opens KozBon's page in the Shortcuts app.
///
/// iOS and visionOS only. `ShortcutsLink` is unavailable on macOS, so
/// the section isn't shown there.
extension SettingsView {

    @ViewBuilder
    var siriSection: some View {
        #if os(iOS) || os(visionOS)
        Section {
            SiriPhraseRow(phrases: Strings.Settings.siriPhrases)

            ShortcutsLink()
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                .accessibilityIdentifier("settings.shortcutsLink")
        } header: {
            Text(Strings.Settings.usingSiri)
                .accessibilityAddTraits(.isHeader)
        } footer: {
            Text(Strings.Settings.usingSiriFooter)
        }
        #endif
    }
}
