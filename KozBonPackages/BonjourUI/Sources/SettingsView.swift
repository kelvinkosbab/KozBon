//
//  SettingsView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

#if os(macOS)

import SwiftUI

// MARK: - SettingsView

public struct SettingsView: View {

    @AppStorage("autoScanOnLaunch") private var autoScanOnLaunch = true
    @AppStorage("defaultSortOrder") private var defaultSortOrder = DefaultSortOrder.none

    public init() {}

    public var body: some View {
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
                "Hostname (A \u{2192} Z)"
            case .hostNameDesc:
                "Hostname (Z \u{2192} A)"
            case .serviceNameAsc:
                "Service Name (A \u{2192} Z)"
            case .serviceNameDesc:
                "Service Name (Z \u{2192} A)"
            }
        }
    }
}

#endif
