//
//  SettingsView+Siri.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourLocalization

// MARK: - SettingsView + Siri

/// The "Using Siri with KozBon" section: one row that cycles through
/// Siri phrases for KozBon's most useful actions, and on iPhone and
/// iPad a row that pushes ``ShortcutsGuideView``.
///
/// Not shown on macOS.
extension SettingsView {

    @ViewBuilder
    var siriSection: some View {
        #if os(iOS) || os(visionOS)
        Section {
            SiriPhraseRow(phrases: Strings.Settings.siriPhrases)

            #if os(iOS)
            NavigationLink {
                ShortcutsGuideView()
            } label: {
                Text(Strings.Settings.usingShortcuts)
            }
            .accessibilityIdentifier("settings.shortcutsLink")
            #endif
        } header: {
            Text(Strings.Settings.usingSiri)
                .accessibilityAddTraits(.isHeader)
        } footer: {
            Text(Strings.Settings.usingSiriFooter)
        }
        #endif
    }
}
