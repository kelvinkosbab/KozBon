//
//  BonjourServiceListSortMenu.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 9/14/23.
//  Copyright © 2023 Kozinga. All rights reserved.
//

/// A SwiftUI menu that lets users choose how to sort Bonjour services.
///
/// The menu presents all available cases of `BonjourServiceSortType` and
/// writes the selected case back through a binding. The label uses a localized
/// "Sort" title and a tinted system icon.
import SwiftUI

/// A menu used to select a sorting strategy for a list of Bonjour services.
///
/// Provide a binding to an optional `BonjourServiceSortType`. When the user
/// selects an option, the bound value is updated. Passing `nil` can represent
/// an unset or default sort, depending on how the parent view interprets it.
struct BonjourServiceListSortMenu: View {

    /// The currently selected sort type, bound to a parent view.
    ///
    /// Updating this value propagates the user's selection to the owner of the
    /// binding. A value of `nil` can be used by the parent to indicate a default
    /// or unsorted state.
    @Binding var sortType: BonjourServiceSortType?

    /// Localized title used for the menu's label.
    let sortButtonString = NSLocalizedString(
        "Sort",
        comment: "Sort services button string"
    )

    /// The view hierarchy for the sort menu.
    ///
    /// Displays a `Menu` whose content consists of a button for each
    /// `BonjourServiceSortType` case. Selecting a button updates `sortType`.
    var body: some View {
        Menu {
            ForEach(BonjourServiceSortType.allCases) { sortType in
                Button(sortType.hostOrServiceTitle) {
                    self.didSelect(sortType: sortType)
                }
            }
        } label: {
            Label(
                title: {
                    Text(self.sortButtonString)
                },
                icon: {
                    Image.arrowUpArrowDownCircleFill
                        .renderingMode(.template)
                        .foregroundColor(.kozBonBlue)
                }
            )
        }
    }

    /// Handles selection of a sort type from the menu.
    /// - Parameter sortType: The selected `BonjourServiceSortType`, or `nil` to clear.
    private func didSelect(sortType: BonjourServiceSortType?) {
        self.sortType = sortType
    }
}
