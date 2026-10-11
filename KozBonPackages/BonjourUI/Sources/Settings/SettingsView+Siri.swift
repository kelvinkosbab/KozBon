//
//  SettingsView+Siri.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import AppIntents
import SwiftUI
import BonjourAppIntents
import BonjourLocalization

// MARK: - SettingsView + Siri

/// The "Using Siri with KozBon" section: Siri phrases for KozBon's
/// most useful actions, and a button that opens KozBon's page in the
/// Shortcuts app.
///
/// iOS and visionOS only. `SiriTipView` and `ShortcutsLink` are
/// unavailable on macOS, so the section isn't shown there.
extension SettingsView {

    @ViewBuilder
    var siriSection: some View {
        #if os(iOS) || os(visionOS)
        Section {
            siriTip(ScanForServicesIntent())
            siriTip(FindServicesIntent(category: .printersAndScanners))
            siriTip(IsDeviceOnlineIntent())

            // Floats like the tips above it, so the section reads as
            // one group rather than three loose cards and a row.
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

    #if os(iOS) || os(visionOS)
    /// The tip draws its own card, so the row adds no inset or
    /// background of its own.
    private func siriTip(_ intent: some AppIntent) -> some View {
        SiriTipView(intent: intent)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
    }
    #endif
}
