//
//  SettingsView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

#if os(macOS)

import SwiftUI
import BonjourLocalization

// MARK: - SettingsView

/// macOS settings view providing preferences for auto-scan on launch and default sort order.
public struct SettingsView: View {

    @AppStorage("autoScanOnLaunch") private var autoScanOnLaunch = true
    @AppStorage("defaultSortOrder") private var defaultSortOrder = DefaultSortOrder.none

    public init() {}

    public var body: some View {
        Form {
            Section(String(localized: Strings.Settings.scanning)) {
                Toggle(String(localized: Strings.Settings.scanOnLaunch), isOn: $autoScanOnLaunch)
            }

            Section(String(localized: Strings.Settings.display)) {
                Picker(String(localized: Strings.Settings.defaultSortOrder), selection: $defaultSortOrder) {
                    ForEach(DefaultSortOrder.allCases) { sortOrder in
                        Text(sortOrder.displayName)
                            .tag(sortOrder)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400)
        .navigationTitle(String(localized: Strings.NavigationTitles.settings))
    }

    // MARK: - DefaultSortOrder

    enum DefaultSortOrder: String, CaseIterable, Identifiable {
        case none
        case hostNameAsc
        case hostNameDesc
        case serviceNameAsc
        case serviceNameDesc

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .none:
                String(localized: Strings.Settings.sortNone)
            case .hostNameAsc:
                String(localized: Strings.Settings.sortHostnameAsc)
            case .hostNameDesc:
                String(localized: Strings.Settings.sortHostnameDesc)
            case .serviceNameAsc:
                String(localized: Strings.Settings.sortServiceNameAsc)
            case .serviceNameDesc:
                String(localized: Strings.Settings.sortServiceNameDesc)
            }
        }
    }
}

#endif
