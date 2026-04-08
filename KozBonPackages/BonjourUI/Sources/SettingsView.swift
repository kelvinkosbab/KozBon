//
//  SettingsView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

#if os(macOS)

import SwiftUI
import BonjourLocalization
import BonjourModels

// MARK: - SettingsView

/// macOS settings view providing preferences for auto-scan on launch and default sort order.
public struct SettingsView: View {

    @AppStorage("autoScanOnLaunch") private var autoScanOnLaunch = true
    @AppStorage("defaultSortOrder") private var defaultSortOrder = ""

    public init() {}

    public var body: some View {
        Form {
            Section(String(localized: Strings.Settings.scanning)) {
                Toggle(String(localized: Strings.Settings.scanOnLaunch), isOn: $autoScanOnLaunch)
            }

            Section(String(localized: Strings.Settings.display)) {
                Picker(String(localized: Strings.Settings.defaultSortOrder), selection: $defaultSortOrder) {
                    Text(Strings.Settings.sortNone).tag("")
                    ForEach(BonjourServiceSortType.allCases) { sortType in
                        Text(sortType.title).tag(sortType.id)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400)
        .navigationTitle(String(localized: Strings.NavigationTitles.settings))
    }
}

#endif
