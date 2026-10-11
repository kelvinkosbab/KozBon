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

/// The Siri & Shortcuts section: brings back dismissed Siri tips and
/// opens KozBon's page in the Shortcuts app.
extension SettingsView {

    @ViewBuilder
    var siriSection: some View {
        #if !os(tvOS) && !os(watchOS)
        Section {
            Toggle(isOn: siriTipsBinding) {
                Text(Strings.Settings.showSiriTips)
            }
            .accessibilityHint(Strings.Accessibility.showSiriTipsHint)
            .accessibilityIdentifier("settings.siriTips")

            ShortcutsLink()
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("settings.shortcutsLink")
        } header: {
            Text(Strings.Settings.siriAndShortcuts)
                .accessibilityAddTraits(.isHeader)
        } footer: {
            Text(Strings.Settings.siriAndShortcutsFooter)
        }
        #endif
    }

    private var siriTipsBinding: Binding<Bool> {
        Binding {
            preferencesStore.siriTipsEnabled
        } set: { newValue in
            preferencesStore.siriTipsEnabled = newValue
        }
    }
}
