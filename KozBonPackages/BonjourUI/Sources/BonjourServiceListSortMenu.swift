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
/// Displays all available `BonjourServiceSortType` cases with a checkmark
/// indicating the currently selected sort. Defaults to Host Name A → Z
/// when no sort type is set.
struct BonjourServiceListSortMenu: View {

    /// The currently selected sort type, bound to a parent view.
    ///
    /// A value of `nil` represents the default sort (Host Name A → Z).
    @Binding var sortType: BonjourServiceSortType?

    /// The effective sort type, treating `nil` as `.hostNameAsc`.
    private var effectiveSortType: BonjourServiceSortType {
        sortType ?? .hostNameAsc
    }

    var body: some View {
        Menu {
            ForEach(BonjourServiceSortType.allCases) { option in
                Button {
                    sortType = option
                } label: {
                    if effectiveSortType == option {
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
