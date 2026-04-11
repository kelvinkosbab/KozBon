//
//  BonjourServiceListSortMenu.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourCore
import BonjourLocalization
import BonjourModels

// MARK: - BonjourServiceListSortMenu

/// A menu used to select a sorting strategy for a list of Bonjour services.
///
/// Displays all available `BonjourServiceSortType` cases plus a "Default"
/// option (host name A→Z). A checkmark indicates the currently selected sort.
struct BonjourServiceListSortMenu: View {

    /// The currently selected sort type, bound to a parent view.
    ///
    /// A value of `nil` represents the default sort (host name A→Z).
    @Binding var sortType: BonjourServiceSortType?

    var body: some View {
        Menu {
            Button {
                sortType = nil
            } label: {
                if sortType == nil {
                    Label(String(localized: Strings.Settings.sortDefault), systemImage: Iconography.selected)
                } else {
                    Text(Strings.Settings.sortDefault)
                }
            }

            Divider()

            ForEach(BonjourServiceSortType.allCases) { option in
                Button {
                    sortType = option
                } label: {
                    if sortType == option {
                        Label(option.title, systemImage: Iconography.selected)
                    } else {
                        Label(option.title, systemImage: option.iconName)
                    }
                }
            }
        } label: {
            Label(String(localized: Strings.Buttons.sort), systemImage: Iconography.sort)
                .tint(.primary)
        }
    }
}
