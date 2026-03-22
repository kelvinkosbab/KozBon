//
//  SettingsView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

#if os(macOS)

import SwiftUI

// MARK: - SettingsView

struct SettingsView: View {

    @AppStorage("autoScanOnLaunch") private var autoScanOnLaunch = true
    @AppStorage("defaultSortOrder") private var defaultSortOrder = DefaultSortOrder.none

    var body: some View {
        Form {
            Section("Scanning") {
                Toggle("Scan for services on launch", isOn: $autoScanOnLaunch)
            }

            Section("Display") {
                Picker("Default sort order", selection: $defaultSortOrder) {
                    ForEach(DefaultSortOrder.allCases) { sortOrder in
                        Text(sortOrder.displayName)
                            .tag(sortOrder)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400)
        .navigationTitle("Settings")
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
                "None"
            case .hostNameAsc:
                "Hostname (A → Z)"
            case .hostNameDesc:
                "Hostname (Z → A)"
            case .serviceNameAsc:
                "Service Name (A → Z)"
            case .serviceNameDesc:
                "Service Name (Z → A)"
            }
        }
    }
}

#endif
